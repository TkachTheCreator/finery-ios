import Foundation
import Speech
import AVFoundation
import Observation

@Observable
@MainActor
final class VoiceInputManager: NSObject {

    enum State {
        case idle
        case requesting
        case recording
        case processing
        case error(String)
    }

    var state: State = .idle
    var recognizedText: String = ""
    var parsedAmount: Decimal?

    private var recognizer: SFSpeechRecognizer?
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?

    override init() {
        super.init()
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))
    }

    func toggle() {
        switch state {
        case .recording:
            stop()
        default:
            start()
        }
    }

    func start() {
        state = .requesting
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            Task { @MainActor in
                guard let self else { return }
                guard authStatus == .authorized else {
                    self.state = .error("Доступ к распознаванию речи не разрешён")
                    return
                }
                self.requestMicAndRecord()
            }
        }
    }

    private func requestMicAndRecord() {
        guard let recognizer, recognizer.isAvailable else {
            state = .error("Распознавание речи недоступно на этом устройстве")
            return
        }
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            Task { @MainActor in
                guard let self else { return }
                guard granted else {
                    self.state = .error("Доступ к микрофону не разрешён")
                    return
                }
                self.startRecording()
            }
        }
    }

    private func startRecording() {
        let engine = AVAudioEngine()
        audioEngine = engine

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let req = recognitionRequest else { return }
        req.shouldReportPartialResults = true

        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            req.append(buffer)
        }

        do {
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .measurement, options: .duckOthers)
            try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
            engine.prepare()
            try engine.start()
        } catch {
            state = .error("Не удалось запустить аудио: \(error.localizedDescription)")
            return
        }

        recognitionTask = recognizer?.recognitionTask(with: req) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    let text = result.bestTranscription.formattedString
                    self.recognizedText = text
                    self.parsedAmount = Self.parseAmount(from: text)
                }
                if result?.isFinal == true || error != nil {
                    self.stop()
                }
            }
        }

        state = .recording
    }

    func stop() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        audioEngine = nil
        recognitionRequest = nil
        recognitionTask = nil
        try? AVAudioSession.sharedInstance().setActive(false)
        state = .idle
    }

    // MARK: - Amount Parser

    static func parseAmount(from text: String) -> Decimal? {
        let cleaned = text.lowercased()

        // Try direct number first: "5000", "5 000", "5.000"
        let digitPattern = /(\d[\d\s,.]*)/
        if let match = cleaned.firstMatch(of: digitPattern) {
            let numStr = String(match.1)
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: ",", with: ".")
            if let value = Decimal(string: numStr), value > 0 {
                return applyWordMultiplier(to: value, text: cleaned)
            }
        }
        return nil
    }

    private static func applyWordMultiplier(to value: Decimal, text: String) -> Decimal {
        if text.contains("миллион") || text.contains("млн") {
            return value * 1_000_000
        }
        if text.contains("тысяч") || text.contains("тыс") {
            return value * 1_000
        }
        return value
    }
}
