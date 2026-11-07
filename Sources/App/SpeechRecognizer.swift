import Foundation
import Speech
import AVFoundation

final class SpeechRecognizer: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording: Bool = false
    @Published var authorized: Bool = false

    private let recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ja-JP"))
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    func requestAuthorization() {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            AVAudioSession.sharedInstance().requestRecordPermission { _ in
                DispatchQueue.main.async {
                    self?.authorized = (status == .authorized)
                }
            }
        }
    }

    func start() {
        guard let recognizer = recognizer, recognizer.isAvailable else { return }
        stopInternal(commit: false)

        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try? session.setActive(true, options: .notifyOthersOnDeactivation)

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition {
            req.requiresOnDeviceRecognition = true
        }
        request = req

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }
        audioEngine.prepare()
        try? audioEngine.start()

        task = recognizer.recognitionTask(with: req) { [weak self] result, _ in
            guard let self = self else { return }
            if let result = result {
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                }
            }
        }
        isRecording = true
    }

    func stop() {
        stopInternal(commit: true)
    }

    private func stopInternal(commit: Bool) {
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        request?.endAudio()
        request = nil
        task?.cancel()
        task = nil
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        isRecording = false
    }

    /// 軽い整形: フィラーの除去と空白の正規化
    func cleanedText() -> String {
        var t = transcript
        let fillers = ["えーと、", "えーと", "えっと、", "えっと", "あのー、", "あの、", "あの", "うーん、", "うーん"]
        for f in fillers {
            t = t.replacingOccurrences(of: f, with: "")
        }
        t = t.trimmingCharacters(in: .whitespacesAndNewlines)
        return t
    }
}
