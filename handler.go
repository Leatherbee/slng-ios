package http

import (
	"bytes"
	"context"
	"encoding/binary"
	"encoding/json"
	"io"
	"net/http"
	"strconv"
	"strings"
	"time"

	"github.com/prammmoe/slng-backend-go/internal/config"
	"github.com/prammmoe/slng-backend-go/internal/openai"
)

type Handler struct {
    whisper openai.Transcriber
    chat openai.ChatTranslator
    maxUpload int64
    multipartMemory int64
    defaultLanguage string
    requestTimeout time.Duration
}

func NewHandler(cfg config.Config) *Handler {
    rt := &http.Transport{MaxIdleConns: 64, MaxIdleConnsPerHost: 32, IdleConnTimeout: 90 * time.Second, ExpectContinueTimeout: 1 * time.Second}
    hc := &http.Client{Timeout: time.Duration(cfg.RequestTimeoutSec) * time.Second, Transport: rt}
    return &Handler{
        whisper: openai.NewWhisperClientWithHTTPClient(cfg.ApiKey, hc),
        chat: openai.NewChatClientWithHTTPClient(cfg.ApiKey, hc),
        maxUpload: int64(cfg.MaxUploadMB) * 1024 * 1024,
        multipartMemory: int64(cfg.MultipartMemoryMB) * 1024 * 1024,
        defaultLanguage: "id",
        requestTimeout: time.Duration(cfg.RequestTimeoutSec) * time.Second,
    }
}

func (h Handler) Transcribe(w http.ResponseWriter, r *http.Request) {
    timeout := h.requestTimeout
    if timeout == 0 {
        timeout = 90 * time.Second
    }
    ctx, cancel := context.WithTimeout(r.Context(), timeout)
    defer cancel()
    maxUpload := h.maxUpload
    if maxUpload == 0 {
        maxUpload = 25 * 1024 * 1024
    }
    r.Body = http.MaxBytesReader(w, r.Body, maxUpload)
    if err := r.ParseMultipartForm(maxUpload); err != nil {
        writeJSONError(w, http.StatusBadRequest, "invalid multipart form")
        return
    }
    file, header, err := r.FormFile("audio")
    if err != nil {
        writeJSONError(w, http.StatusBadRequest, "missing audio file")
        return
    }
    defer file.Close()

    filename := header.Filename
    contentType := header.Header.Get("Content-Type")
    if contentType == "" {
        contentType = "application/octet-stream"
    }
    q := r.URL.Query()
    language := q.Get("language")
    if language == "" {
        dl := h.defaultLanguage
        if dl == "" {
            dl = "id"
        }
        language = dl
    }
    model := q.Get("model")
    translate := false
    if v := q.Get("translate"); v != "" {
        b, _ := strconv.ParseBool(v)
        translate = b
    }
    var buf bytes.Buffer
    if _, err := io.Copy(&buf, file); err != nil {
        writeJSONError(w, http.StatusBadRequest, "failed to read audio file")
        return
    }
    b := buf.Bytes()
    if isSilenceWAV(b) {
        w.Header().Set("Content-Type", "application/json")
        json.NewEncoder(w).Encode(map[string]string{"text": ""})
        return
    }
    text, err := h.whisper.Transcribe(ctx, bytes.NewReader(b), filename, contentType, language, model, translate)
    if err != nil {
        status, msg := classifyUpstreamError(err)
        writeJSONError(w, status, msg)
        return
    }
    text = sanitizeTranscription(text)

    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]string{"text": text})
}

func (h Handler) Root(w http.ResponseWriter, r *http.Request) {
    w.Write([]byte("SLNG Backend API"))
}

func writeJSONError(w http.ResponseWriter, status int, msg string) {
    w.Header().Set("Content-Type", "application/json")
    w.WriteHeader(status)
    json.NewEncoder(w).Encode(map[string]string{"error": msg})
}

func (h Handler) Translate(w http.ResponseWriter, r *http.Request) {
    timeout := h.requestTimeout
    if timeout == 0 {
        timeout = 90 * time.Second
    }
    ctx, cancel := context.WithTimeout(r.Context(), timeout)
    defer cancel()
    var req struct{
        Text string `json:"text"`
        Model string `json:"model"`
        Temperature float64 `json:"temperature"`
    }
    if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
        writeJSONError(w, http.StatusBadRequest, "invalid json body")
        return
    }
    t := strings.TrimSpace(req.Text)
    if t == "" {
        writeJSONError(w, http.StatusBadRequest, "missing text")
        return
    }
    english, sentiment, err := h.chat.Translate(ctx, t, req.Model, req.Temperature)
    if err != nil {
        status, msg := classifyUpstreamError(err)
        writeJSONError(w, status, msg)
        return
    }
    w.Header().Set("Content-Type", "application/json")
    json.NewEncoder(w).Encode(map[string]any{"originalText": t, "englishTranslation": english, "sentiment": strings.ToLower(strings.TrimSpace(sentiment))})
}

func classifyUpstreamError(err error) (int, string) {
    s := strings.ToLower(err.Error())
    if strings.Contains(s, "rate limit") || strings.Contains(s, "rate_limit") || strings.Contains(s, "429") || strings.Contains(s, "too many requests") {
        wait := extractRetryAfterSeconds(err.Error())
        if wait != "" {
            return http.StatusTooManyRequests, "OpenAI rate limit exceeded. Please retry after " + wait + "s"
        }
        return http.StatusTooManyRequests, "OpenAI rate limit exceeded. Please wait and retry."
    }
    return http.StatusInternalServerError, err.Error()
}

func extractRetryAfterSeconds(msg string) string {
    m := strings.ToLower(msg)
    key := "try again in "
    i := strings.Index(m, key)
    if i == -1 {
        return ""
    }
    tail := msg[i+len(key):]
    j := strings.Index(tail, "s")
    if j == -1 {
        return ""
    }
    val := strings.TrimSpace(tail[:j])
    k := 0
    dot := false
    for ; k < len(val); k++ {
        c := val[k]
        if c == '.' {
            if dot {
                return ""
            }
            dot = true
            continue
        }
        if c < '0' || c > '9' {
            return ""
        }
    }
    return val
}

func isSilenceWAV(b []byte) bool {
    if len(b) < 44 {
        return false
    }
    if string(b[0:4]) != "RIFF" || string(b[8:12]) != "WAVE" {
        return false
    }
    off := 12
    var audioFmt uint16
    var channels uint16
    var sampleRate uint32
    var bitsPerSample uint16
    var dataStart int
    var dataSize uint32
    for off+8 <= len(b) {
        id := string(b[off : off+4])
        sz := binary.LittleEndian.Uint32(b[off+4 : off+8])
        off += 8
        if off+int(sz) > len(b) {
            break
        }
        if id == "fmt " {
            if sz < 16 {
                return false
            }
            audioFmt = binary.LittleEndian.Uint16(b[off : off+2])
            channels = binary.LittleEndian.Uint16(b[off+2 : off+4])
            sampleRate = binary.LittleEndian.Uint32(b[off+4 : off+8])
            bitsPerSample = binary.LittleEndian.Uint16(b[off+14 : off+16])
        } else if id == "data" {
            dataStart = off
            dataSize = sz
            break
        }
        off += int(sz)
        if sz%2 == 1 && off < len(b) {
            off++
        }
    }
    if dataStart == 0 || dataSize == 0 {
        return false
    }
    if audioFmt != 1 {
        return false
    }
    if bitsPerSample != 16 || channels == 0 || sampleRate == 0 {
        return false
    }
    data := b[dataStart : dataStart+int(dataSize)]
    sampCount := len(data) / int(2*channels)
    if sampCount == 0 {
        return true
    }
    maxCheck := sampCount
    maxSec := 2
    if sampleRate != 0 {
        limit := int(sampleRate) * maxSec
        if maxCheck > limit {
            maxCheck = limit
        }
    }
    idx := 0
    var sum int64
    var max int32
    for i := 0; i < maxCheck; i++ {
        var acc int32
        for c := 0; c < int(channels); c++ {
            if idx+2 > len(data) {
                break
            }
            v := int16(binary.LittleEndian.Uint16(data[idx : idx+2]))
            if v < 0 {
                acc += -int32(v)
            } else {
                acc += int32(v)
            }
            idx += 2
        }
        if acc > max {
            max = acc
        }
        sum += int64(acc)
    }
    if max == 0 && sum == 0 {
        return true
    }
    avg := float64(sum) / float64(maxCheck)
    if avg < 300 {
        return true
    }
    return false
}

func sanitizeTranscription(text string) string {
    t := strings.TrimSpace(strings.ToLower(text))
    if t == "" {
        return ""
    }
    if isNoiseText(t) {
        return ""
    }
    return text
}

func isNoiseText(t string) bool {
    if len(t) <= 64 {
        p := []string{
            "sub indo by broth3rmax",
            "sub indo by brothermax",
            "subindo by broth3rmax",
            "sub indo brothermax",
            "subtitle indonesia by broth3rmax",
        }
        for _, s := range p {
            if strings.Contains(t, s) {
                return true
            }
        }
        if strings.Contains(t, "sub indo") && strings.Contains(t, "bro") && strings.Contains(t, "max") {
            return true
        }
    }
    return false
}
