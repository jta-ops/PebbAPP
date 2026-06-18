import Foundation
import AVFoundation

/// Records a short voice message and exposes a live audio level for the waveform UI.
@MainActor
final class VoiceRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var level: CGFloat = 0          // 0...1 normalised mic level
    @Published var elapsed: TimeInterval = 0
    @Published var levels: [CGFloat] = []       // rolling history for the waveform

    private var recorder: AVAudioRecorder?
    private var meterTimer: Timer?
    private var fileURL: URL?

    func requestPermission(_ done: @escaping (Bool) -> Void) {
        AVAudioApplication.requestRecordPermission { granted in
            DispatchQueue.main.async { done(granted) }
        }
    }

    func start() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default, options: [.duckOthers, .defaultToSpeaker])
        try? session.setActive(true)

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("pebb-voice-\(UUID().uuidString).m4a")
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]
        do {
            recorder = try AVAudioRecorder(url: url, settings: settings)
            recorder?.isMeteringEnabled = true
            recorder?.record()
            fileURL = url
            isRecording = true
            elapsed = 0
            levels = []
            meterTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
                Task { @MainActor in self?.tick() }
            }
        } catch {
            isRecording = false
        }
    }

    private func tick() {
        guard let r = recorder else { return }
        r.updateMeters()
        let power = r.averagePower(forChannel: 0)            // -160...0 dB
        let normalized = max(0, min(1, (power + 55) / 55))
        level = CGFloat(normalized)
        levels.append(CGFloat(normalized))
        if levels.count > 40 { levels.removeFirst() }
        elapsed += 0.05
    }

    /// Stops recording. Returns the recorded file URL (nil if cancelled/too short).
    func stop() -> URL? {
        meterTimer?.invalidate(); meterTimer = nil
        recorder?.stop()
        isRecording = false
        let duration = elapsed
        try? AVAudioSession.sharedInstance().setActive(false)
        guard duration > 0.4 else { if let u = fileURL { try? FileManager.default.removeItem(at: u) }; return nil }
        return fileURL
    }

    func cancel() {
        meterTimer?.invalidate(); meterTimer = nil
        recorder?.stop()
        isRecording = false
        if let u = fileURL { try? FileManager.default.removeItem(at: u) }
        try? AVAudioSession.sharedInstance().setActive(false)
    }

    var durationLabel: String {
        let s = Int(elapsed)
        return String(format: "%d:%02d", s / 60, s % 60)
    }
}
