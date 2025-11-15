//
//  AudioRecordManager.swift
//  SlangTranslator
//
//  Created by Pramuditha Muhammad Ikhwan on 12/11/25.
//

import Foundation
import AVFoundation

final class AudioRecorderManager: NSObject {
    private var recorder: AVAudioRecorder?
    private(set) var isRecording: Bool = false
    
    func requestPermission(completion: @escaping (Bool) -> Void) {
        AVAudioApplication.requestRecordPermission { granted in
            completion(granted)
        }
    }
    
    func start() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try session.setActive(true)
        
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatMPEG4AAC,
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")
        
        recorder = try? AVAudioRecorder(url: url, settings: settings)
        recorder?.record()
        isRecording = true
    }
    
    func stopAndFetchData() throws -> (data: Data, fileName: String, mimeType: String) {
        guard let recorder else {
            throw NSError(domain: "AudioRecorder", code: 0, userInfo: [NSLocalizedDescriptionKey: "Recorder not initialized"])
        }
        
        recorder.stop()
        isRecording = false
        let url = recorder.url
        let data = try Data(contentsOf: url)
        return (data, url.lastPathComponent, "audio/m4a")
    }
    
    func stop() {
        recorder?.stop()
        isRecording = false
    }
    
    
}
