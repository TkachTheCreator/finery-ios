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

    var isIdle: Bool {
        if case .idle = state { return true }
        return false
    }

    var voiceError: String? {
        if case .error(let msg) = state { return msg }
        return nil
    }

    private var recognizer: SFSpeechRecognizer?
    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var tapInstalled = false

    override init() {
        super.init()
        recognizer = SFSpeechRecognizer(locale: Locale(identifier: "ru-RU"))
    }

    func toggle() {
        switch state {
        case .recording:  stop()
        case .requesting: return
        default:          start()
        }
    }

    func start() {
        state = .requesting
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            Task { @MainActor in
                guard let self else { return }
                guard authStatus == .authorized else {
                    self.state = .error("Доступ к распознаванию речи не разрешён. Разрешите в Настройках → Конфиденциальность.")
                    return
                }
                self.requestMicAndRecord()
            }
        }
    }

    private func requestMicAndRecord() {
        guard let recognizer, recognizer.isAvailable else {
            state = .error("Распознавание речи недоступно. Убедитесь, что язык «Русский» загружен.")
            return
        }
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            Task { @MainActor in
                guard let self else { return }
                guard granted else {
                    self.state = .error("Доступ к микрофону не разрешён. Разрешите в Настройках.")
                    return
                }
                self.startRecording()
            }
        }
    }

    private func startRecording() {
        // 1. Настраиваем аудиосессию ДО создания движка
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            state = .error("Не удалось активировать аудио: \(error.localizedDescription)")
            return
        }

        // 2. Создаём движок и запрос
        let engine = AVAudioEngine()
        audioEngine = engine

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        req.requiresOnDeviceRecognition = false
        recognitionRequest = req

        // 3. Проверяем формат входного узла
        let inputNode = engine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        guard format.sampleRate > 0 else {
            state = .error("Не удалось получить аудиоформат микрофона")
            cleanupAudio()
            return
        }

        // 4. Устанавливаем tap
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            req.append(buffer)
        }
        tapInstalled = true

        // 5. Запускаем движок
        do {
            engine.prepare()
            try engine.start()
        } catch {
            state = .error("Не удалось запустить запись: \(error.localizedDescription)")
            cleanupAudio()
            return
        }

        // 6. Запускаем распознавание
        recognitionTask = recognizer?.recognitionTask(with: req) { [weak self] result, error in
            Task { @MainActor in
                guard let self, self.audioEngine != nil else { return }
                if let result {
                    self.recognizedText = result.bestTranscription.formattedString
                    self.parsedAmount   = Self.parseAmount(from: self.recognizedText)
                }
                if result?.isFinal == true {
                    self.stop()
                } else if let error {
                    self.stopWithError(error.localizedDescription)
                }
            }
        }

        state = .recording
    }

    func stop() {
        guard audioEngine != nil else { return }
        cleanupAudio()
        state = .idle
    }

    private func stopWithError(_ message: String) {
        guard audioEngine != nil else { return }
        cleanupAudio()
        state = .error(message)
    }

    private func cleanupAudio() {
        // Correct teardown order to prevent req.append(buffer) after endAudio():
        // 1. Cancel task — stops result callbacks from firing
        recognitionTask?.cancel()
        recognitionTask = nil

        // 2. Remove tap — prevents the audio callback from appending more data
        if tapInstalled {
            audioEngine?.inputNode.removeTap(onBus: 0)
            tapInstalled = false
        }

        // 3. Stop engine — no more audio flows after this
        audioEngine?.stop()
        audioEngine = nil

        // 4. Only THEN finalize the request (safe: no more appends possible)
        recognitionRequest?.endAudio()
        recognitionRequest = nil

        // 5. Release audio session last
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Amount Parser

    nonisolated static func parseAmount(from text: String) -> Decimal? {
        let cleaned = text.lowercased()
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

    private nonisolated static func applyWordMultiplier(to value: Decimal, text: String) -> Decimal {
        if text.contains("миллион") || text.contains("млн") { return value * 1_000_000 }
        if text.contains("тысяч")  || text.contains("тыс")  { return value * 1_000 }
        return value
    }
}
