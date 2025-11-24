import Foundation
import AVFoundation
import Speech

final class SpeechStreamingManager: NSObject {
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let recognizer: SFSpeechRecognizer?

    override init() {
        self.recognizer = SFSpeechRecognizer(locale: Locale(identifier: "id-ID"))
        super.init()
    }

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            completion(status == .authorized)
        }
    }

    func start(onUpdate: @escaping (_ text: String, _ isFinal: Bool) -> Void) throws {
        guard recognitionTask == nil else { return }
        guard let recognizer, recognizer.isAvailable else {
            throw NSError(domain: "SpeechStreaming", code: 0, userInfo: [NSLocalizedDescriptionKey: "Speech recognizer not available"])
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        recognitionRequest?.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = recognizer.recognitionTask(with: recognitionRequest!) { result, error in
            if let result {
                let text = result.bestTranscription.formattedString
                onUpdate(text, result.isFinal)
                if result.isFinal {
                    self.stop()
                }
            } else if error != nil {
                self.stop()
            }
        }
    }

    func stop() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}
