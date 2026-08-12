import AVFoundation
import Foundation

/// Phase 2.1 audio backend.
///
/// Phase 2 instantiated an AVAudioPlayer for every dot. AquaDot can generate
/// hundreds of one-shot events per level, so that design repeatedly entered
/// CoreAudio/HAL setup and eventually produced overload messages on real Macs.
///
/// This implementation builds one persistent AVAudioEngine, decodes the shipped
/// lossless runtime copies once, and reuses a small pool of AVAudioPlayerNodes.
/// The original `.adrs` bytes remain untouched in preservation/.
final class AquaDotAudioSystem {
    private let preferences = AquaDotPreferences.shared
    private let engine = AVAudioEngine()
    private let musicNode = AVAudioPlayerNode()
    private let specialNode = AVAudioPlayerNode()
    private let oneShotNodes: [AVAudioPlayerNode] = (0..<10).map { _ in AVAudioPlayerNode() }

    private var buffers: [String: AVAudioPCMBuffer] = [:]
    private var nextOneShotNode = 0
    private var lastDamageSoundTime: TimeInterval = 0
    private var engineConfigured = false

    init(bundle: Bundle = .main) {
        preloadBuffers(bundle: bundle)
        configureEngine()
    }

    deinit {
        stopAll()
    }

    var activeVoiceCount: Int {
        oneShotNodes.filter { $0.isPlaying }.count
            + (musicNode.isPlaying ? 1 : 0)
            + (specialNode.isPlaying ? 1 : 0)
    }

    var cachedSoundCount: Int { buffers.count }

    func synchronizePreferences() {
        musicNode.volume = preferences.muteAll || preferences.disableMusic
            ? 0
            : Float(0.55 * preferences.musicVolume)
        specialNode.volume = preferences.muteAll
            ? 0
            : Float(0.44 * preferences.soundEffectsVolume)
    }

    func startLevelMusic(variant: Int) {
        let level = max(1, min(6, variant))
        let key = "OGS_Music_level\(level)"

        musicNode.stop()
        guard !preferences.muteAll,
              !preferences.disableMusic,
              let buffer = buffers[key],
              ensureEngineRunning() else { return }

        musicNode.volume = Float(0.55 * preferences.musicVolume)
        musicNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        musicNode.play()
    }

    func stopMusic() {
        musicNode.stop()
    }

    func stopAll() {
        musicNode.stop()
        specialNode.stop()
        oneShotNodes.forEach { $0.stop() }
        if engine.isRunning { engine.stop() }
    }

    /// Restore an already-active ability after leaving the retained game scene
    /// for Options/Opening. Unlike a fresh activation, this does not replay the
    /// original short start cue.
    func resumeSpecialPower(_ power: AquaDotSpecialPower) {
        startSpecialLoop(power, playIntro: false)
    }

    func handle(_ events: [AquaDotGameEvent]) {
        for event in events {
            switch event {
            case .dotEaten:
                play("OGS_General_eatSmallDot", volume: 0.65)
            case .munchEaten:
                break
            case .munchStarted:
                play("OGS_General_bugsRunRunRun", volume: 0.75)
            case .munchEnded:
                break
            case let .goodieSpawned(kind, _):
                switch kind {
                case .yummy: play("OGS_Goodie_Dots_yummyPopIn")
                case .yuk: play("OGS_Goodie_Dots_yukPopIn")
                case .bonus: play("OGS_Goodie_Dots_bonusPopIn")
                case .multiplier: play("OGS_Goodie_Dots_multiplierPopIn")
                }
            case let .goodieEaten(kind, _):
                switch kind {
                case .yummy: play("OGS_Speak_yummy", volume: 0.85)
                case .yuk: play("OGS_General_eatYukDot", volume: 0.85)
                case .bonus: play("OGS_Speak_bonus", volume: 0.85)
                case .multiplier: play("OGS_Speak_multiply", volume: 0.85)
                }
            case .specialPowerAvailable:
                break
            case let .specialPowerActivated(power):
                startSpecialLoop(power, playIntro: true)
            case .specialPowerEnded:
                stopSpecialLoop()
            case let .bugEaten(_, points):
                play(points <= 500 ? "OGS_General_eatBug" : "OGS_General_2eatBug", volume: 0.9)
            case .playerDamaged:
                let now = Date.timeIntervalSinceReferenceDate
                if now - lastDamageSoundTime > 0.25 {
                    play("OGS_Loops_eekThatHurts_start", volume: 0.60)
                    lastDamageSoundTime = now
                }
            case .lifeLost:
                stopSpecialLoop()
                play("OGS_General_aquadotDeath", volume: 0.9)
            case .lifeGained:
                play("OGS_General_aquadotRebirth", volume: 0.9)
            case .wrapped:
                play("OGS_Loops_warping_start", volume: 0.65)
            case .levelCompleted:
                break
            case let .paused(paused):
                if paused { play("OGS_Speak_pause", volume: 0.75) }
            }
        }
    }

    private func preloadBuffers(bundle: Bundle) {
        let roots: [String?] = ["OriginalAudioRuntime", nil]
        var seen = Set<URL>()

        for subdirectory in roots {
            for url in bundle.urls(forResourcesWithExtension: "m4a", subdirectory: subdirectory) ?? [] {
                guard seen.insert(url).inserted else { continue }
                do {
                    let file = try AVAudioFile(forReading: url)
                    guard file.length > 0,
                          file.length <= AVAudioFramePosition(UInt32.max),
                          let buffer = AVAudioPCMBuffer(
                            pcmFormat: file.processingFormat,
                            frameCapacity: AVAudioFrameCount(file.length)
                          ) else { continue }
                    try file.read(into: buffer)
                    buffers[url.deletingPathExtension().lastPathComponent] = buffer
                } catch {
                    print("AquaDot audio: could not preload \(url.lastPathComponent): \(error)")
                }
            }
        }
    }

    private func configureEngine() {
        guard !engineConfigured, let format = buffers.values.first?.format else { return }
        engineConfigured = true

        let nodes = [musicNode, specialNode] + oneShotNodes
        for node in nodes {
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
        }

        engine.mainMixerNode.outputVolume = 1
        engine.prepare()
        _ = ensureEngineRunning()
        synchronizePreferences()

        print("AquaDot audio Phase 2.1: persistent engine ready, \(buffers.count) original sounds cached, \(oneShotNodes.count) one-shot voices")
    }

    @discardableResult
    private func ensureEngineRunning() -> Bool {
        guard engineConfigured else { return false }
        if engine.isRunning { return true }
        do {
            try engine.start()
            return true
        } catch {
            print("AquaDot audio: AVAudioEngine could not start: \(error)")
            return false
        }
    }

    private func startSpecialLoop(_ power: AquaDotSpecialPower, playIntro: Bool) {
        stopSpecialLoop()

        let stem: String
        switch power {
        case let .yummy(value): stem = "yummy_\(value.rawValue)"
        case let .yuk(value): stem = "yuk_\(value.rawValue)"
        }

        if playIntro {
            play("OGS_Loops_\(stem)_start", volume: 0.62)
        }
        let key = "OGS_Loops_\(stem)"
        guard !preferences.muteAll,
              let buffer = buffers[key],
              ensureEngineRunning() else { return }

        specialNode.volume = Float(0.44 * preferences.soundEffectsVolume)
        specialNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        specialNode.play()
    }

    private func stopSpecialLoop() {
        specialNode.stop()
    }

    private func play(_ key: String, volume: Float = 0.75) {
        guard !preferences.muteAll,
              let buffer = buffers[key],
              ensureEngineRunning() else { return }

        let node = oneShotNodes[nextOneShotNode]
        nextOneShotNode = (nextOneShotNode + 1) % oneShotNodes.count

        // Reusing a node rather than allocating an AVAudioPlayer is the important
        // performance fix. Ten voices are enough to overlap rapid dot/bug events
        // without unbounded CoreAudio object creation.
        node.stop()
        node.volume = volume * Float(preferences.soundEffectsVolume)
        node.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        node.play()
    }
}
