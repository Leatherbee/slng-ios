//
//  SpeechRecordingService.swift
//  SlangTranslator
//
//  Consolidated service for speech recording and transcription.
//  Extracted from TranslateViewModel to improve separation of concerns.
//

import Foundation
import AVFoundation

enum SpeechRecordingError: LocalizedError {
    case microphoneNotGranted
    case speechRecognitionNotGranted
    case recorderNotInitialized
    case transcriptionFailed(underlying: Error)
    case rateLimited
    case serverError

    var errorDescription: String? {
        switch self {
        case .microphoneNotGranted:
            return "Mic's locked. Open Settings and free it"
        case .speechRecognitionNotGranted:
            return "Speech recognition not authorized"
        case .recorderNotInitialized:
            return "Recorder not initialized"
        case .transcriptionFailed(let error):
            return error.localizedDescription
        case .rateLimited:
            return "You're tapping faster than my brain can think… chill for a sec"
        case .serverError:
            return "Yeah that's on me, not you. Fixing the chaos"
        }
    }
}

protocol SpeechRecordingServiceDelegate: AnyObject {
    func speechRecordingService(_ service: SpeechRecordingService, didUpdateAudioLevel level: Float)
    func speechRecordingServiceDidStartRecording(_ service: SpeechRecordingService)
    func speechRecordingServiceDidStopRecording(_ service: SpeechRecordingService)
    func speechRecordingService(_ service: SpeechRecordingService, didTranscribe text: String)
    func speechRecordingService(_ service: SpeechRecordingService, didFailWithError error: SpeechRecordingError)
}

final class SpeechRecordingService {
    weak var delegate: SpeechRecordingServiceDelegate?

    private let audioRecorder = AudioRecorderManager()
    private let speechStreamingManager = SpeechStreamingManager()
    private var speechUseCase: TranscribeSpeechUseCase?
    private let analytics = AnalyticsService.shared

    private(set) var isRecording: Bool = false
    private(set) var isTranscribing: Bool = false

    init(speechUseCase: TranscribeSpeechUseCase? = nil) {
        self.speechUseCase = speechUseCase
    }

    func configure(speechUseCase: TranscribeSpeechUseCase) {
        self.speechUseCase = speechUseCase
    }

    // MARK: - Permission Handling

    func prewarmPermissions() {
        analytics.logPermissionPrompt(type: "microphone")
        audioRecorder.requestPermission { [weak self, analytics] granted in
            analytics.logPermissionResponse(type: "microphone", granted: granted)
        }

        analytics.logPermissionPrompt(type: "speech_recognition")
        speechStreamingManager.requestAuthorization { [weak self, analytics] granted in
            analytics.logPermissionResponse(type: "speech_recognition", granted: granted)
        }
    }

    func requestMicrophonePermission(completion: @escaping (Bool) -> Void) {
        audioRecorder.requestPermission(completion: completion)
    }

    func requestSpeechPermission(completion: @escaping (Bool) -> Void) {
        speechStreamingManager.requestAuthorization(completion: completion)
    }

    // MARK: - Recording

    func startRecording() {
        audioRecorder.requestPermission { [weak self] micGranted in
            guard let self else { return }

            if !micGranted {
                self.analytics.logPermissionResponse(type: "microphone", granted: false)
                self.delegate?.speechRecordingService(self, didFailWithError: .microphoneNotGranted)
                return
            }

            do {
                self.audioRecorder.setLevelUpdateHandler { [weak self] level in
                    guard let self else { return }
                    self.delegate?.speechRecordingService(self, didUpdateAudioLevel: level)
                }
                try self.audioRecorder.start()
                self.isRecording = true
                self.analytics.logPermissionResponse(type: "microphone", granted: true)
                self.delegate?.speechRecordingServiceDidStartRecording(self)
            } catch {
                logError("Failed to start recording: \(error)", category: .audio)
                self.delegate?.speechRecordingService(self, didFailWithError: .transcriptionFailed(underlying: error))
            }
        }
    }

    func stopRecording() {
        speechStreamingManager.stop()
        audioRecorder.stop()
        isRecording = false
        delegate?.speechRecordingServiceDidStopRecording(self)
    }

    func stopRecordingAndTranscribe() {
        let perm = AVAudioApplication.shared.recordPermission
        if perm != .granted {
            delegate?.speechRecordingService(self, didFailWithError: .microphoneNotGranted)
            return
        }

        speechStreamingManager.stop()

        do {
            let result = try audioRecorder.stopAndFetchData()
            isRecording = false
            isTranscribing = true
            delegate?.speechRecordingServiceDidStopRecording(self)

            Task { [weak self] in
                await self?.transcribe(audioData: result.data, fileName: result.fileName, mimeType: result.mimeType)
            }
        } catch {
            logError("Failed to stop and fetch audio data: \(error)", category: .audio)
            delegate?.speechRecordingService(self, didFailWithError: .transcriptionFailed(underlying: error))
        }
    }

    // MARK: - Transcription

    private func transcribe(audioData: Data, fileName: String, mimeType: String) async {
        guard let speechUseCase else {
            logError("Speech use case not configured", category: .speechToText)
            await MainActor.run {
                isTranscribing = false
                delegate?.speechRecordingService(self, didFailWithError: .recorderNotInitialized)
            }
            return
        }

        do {
            let text = try await speechUseCase.execute(audioData: audioData, fileName: fileName, mimeType: mimeType)
            await MainActor.run {
                isTranscribing = false
                delegate?.speechRecordingService(self, didTranscribe: text)
            }
            ReviewRequestManager.shared.recordSTTAndMaybePrompt()
        } catch {
            let speechError = mapError(error)
            await MainActor.run {
                isTranscribing = false
                delegate?.speechRecordingService(self, didFailWithError: speechError)
            }
        }
    }

    private func mapError(_ error: Error) -> SpeechRecordingError {
        let ns = error as NSError
        let code = ns.code
        let status = (ns.userInfo["status"] as? Int) ?? code

        if status == 429 {
            return .rateLimited
        } else if status == 500 {
            return .serverError
        } else {
            return .transcriptionFailed(underlying: error)
        }
    }
}
