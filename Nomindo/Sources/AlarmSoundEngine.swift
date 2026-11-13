import Foundation
import AVFoundation
import UIKit

final class AlarmSoundEngine {
    static let shared = AlarmSoundEngine()

    private var audioEngine: AVAudioEngine?
    private var sourceNode: AVAudioSourceNode?
    private var isPlaying = false
    private var phase: Float = 0.0
    private var pulseTimer: Timer?
    private var isToneHigh = true

    private init() {}

    func startAlarm() {
        guard !isPlaying else { return }
        isPlaying = true

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default, options: [.duckOthers])
            try session.setActive(true)
        } catch {
            print("AudioSession error: \(error.localizedDescription)")
        }

        let engine = AVAudioEngine()
        let mainMixer = engine.mainMixerNode
        let outputFormat = mainMixer.outputFormat(forBus: 0)
        let sampleRate = Float(outputFormat.sampleRate > 0 ? outputFormat.sampleRate : 44100.0)

        let node = AVAudioSourceNode { [weak self] _, _, frameCount, audioBufferList -> OSStatus in
            guard let self = self, self.isPlaying else { return noErr }
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let freq: Float = self.isToneHigh ? 960.0 : 720.0
            let phaseIncrement = (2.0 * Float.pi * freq) / sampleRate

            for frame in 0..<Int(frameCount) {
                let rawSample = sin(self.phase)
                // Sharp square-ish alarm wave
                let shapedSample: Float = (rawSample > 0 ? 0.55 : -0.55)
                self.phase += phaseIncrement
                if self.phase >= 2.0 * Float.pi {
                    self.phase -= 2.0 * Float.pi
                }
                for buffer in ablPointer {
                    let buf: UnsafeMutableBufferPointer<Float> = UnsafeMutableBufferPointer(buffer)
                    buf[frame] = shapedSample
                }
            }
            return noErr
        }

        engine.attach(node)
        engine.connect(node, to: mainMixer, format: outputFormat)

        do {
            try engine.start()
            self.audioEngine = engine
            self.sourceNode = node
        } catch {
            print("AudioEngine start error: \(error.localizedDescription)")
        }

        pulseTimer?.invalidate()
        pulseTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { [weak self] _ in
            guard let self = self, self.isPlaying else { return }
            self.isToneHigh.toggle()
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }

    func stopAlarm() {
        isPlaying = false
        pulseTimer?.invalidate()
        pulseTimer = nil
        audioEngine?.stop()
        audioEngine = nil
        sourceNode = nil
    }
}
