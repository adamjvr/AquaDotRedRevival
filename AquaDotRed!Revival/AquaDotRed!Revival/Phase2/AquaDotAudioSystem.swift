import AVFoundation
import Foundation

/// Persistent pooled audio backend. Phase 3B adds the five recovered tween-level
/// music tracks and the recovered Game Over/High Score speech without returning
/// to the old per-event AVAudioPlayer allocation pattern.
final class AquaDotAudioSystem {
    private let preferences = AquaDotPreferences.shared
    private let engine = AVAudioEngine()
    private let musicNode = AVAudioPlayerNode()
    private let tweenNode = AVAudioPlayerNode()
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

    deinit { stopAll() }

    var activeVoiceCount: Int {
        oneShotNodes.filter { $0.isPlaying }.count
            + (musicNode.isPlaying ? 1 : 0)
            + (tweenNode.isPlaying ? 1 : 0)
            + (specialNode.isPlaying ? 1 : 0)
    }

    var cachedSoundCount: Int { buffers.count }

    func synchronizePreferences() {
        musicNode.volume = preferences.muteAll || preferences.disableMusic
            ? 0 : Float(0.55 * preferences.musicVolume)
        tweenNode.volume = preferences.muteAll || preferences.disableMusic
            ? 0 : Float(0.72 * preferences.musicVolume)
        specialNode.volume = preferences.muteAll
            ? 0 : Float(0.44 * preferences.soundEffectsVolume)
    }

    func startLevelMusic(variant: Int) {
        let level = max(1, min(6, variant))
        let key = "OGS_Music_level\(level)"

        tweenNode.stop()
        musicNode.stop()
        guard !preferences.muteAll,
              !preferences.disableMusic,
              let buffer = buffers[key],
              ensureEngineRunning() else { return }

        musicNode.volume = Float(0.55 * preferences.musicVolume)
        musicNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        musicNode.play()
    }

    func stopMusic() { musicNode.stop() }

    /// Play the recovered end-of-level music for the guide/binary-confirmed five
    /// quality bands. Returns the actual decoded duration so the tween screen can
    /// remain visible for the original track instead of an arbitrary 2.35 sec.
    @discardableResult
    func playLevelResult(_ quality: AquaDotLevelQuality) -> TimeInterval {
        let key: String
        switch quality {
        case .yuk: key = "OGS_Music_tween_yuk"
        case .okay: key = "OGS_Music_tween_okay"
        case .good: key = "OGS_Music_tween_good"
        case .veryGood: key = "OGS_Music_tween_veryGood"
        case .wowBest: key = "OGS_Music_tween_wowBest"
        }

        musicNode.stop()
        tweenNode.stop()
        guard !preferences.muteAll,
              !preferences.disableMusic,
              let buffer = buffers[key],
              ensureEngineRunning() else { return 0 }

        tweenNode.volume = Float(0.72 * preferences.musicVolume)
        tweenNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        tweenNode.play()
        return buffer.format.sampleRate > 0
            ? Double(buffer.frameLength) / buffer.format.sampleRate
            : 0
    }

    func playHighScoreCue() {
        play("OGS_Speak_highScore", volume: 0.92)
    }

    func stopAll() {
        musicNode.stop()
        tweenNode.stop()
        specialNode.stop()
        oneShotNodes.forEach { $0.stop() }
        if engine.isRunning { engine.stop() }
    }

    func resumeSpecialPower(_ power: AquaDotSpecialPower) {
        startSpecialLoop(power, playIntro: false)
    }

    func handle(_ events: [AquaDotGameEvent]) {
        for event in events {
            switch event {
            case .dotEaten:
                play("OGS_General_eatSmallDot", volume: 0.65)
            case .dotTransformed, .sproutStarted:
                break
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
            case .gameOver:
                stopSpecialLoop()
                musicNode.stop()
                tweenNode.stop()
                play("OGS_Speak_gameOver", volume: 0.94)
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
        guard !engineConfigured else { return }

        // AVAudioPlayerNode requires a scheduled buffer's channel count to match
        // the player's configured output format. Phase 3B added stereo tween-level
        // music to a pool whose ordinary gameplay sounds are mono. The old code
        // connected *every* player node using an arbitrary `buffers.values.first`
        // format, so the first level-complete event could schedule a stereo tween
        // on a mono tweenNode and AVFAudio would raise an Objective-C exception.
        //
        // Use deterministic formats per playback family instead. AVAudioMixerNode
        // is specifically designed to accept differently formatted input busses.
        guard let gameplayFormat = buffers["OGS_General_eatSmallDot"]?.format
                ?? buffers.values.first?.format else { return }
        let levelMusicFormat = buffers["OGS_Music_level1"]?.format ?? gameplayFormat
        let tweenFormat = buffers["OGS_Music_tween_okay"]?.format ?? levelMusicFormat
        let specialFormat = buffers["OGS_Loops_yummy_invisible"]?.format ?? gameplayFormat

        engineConfigured = true

        engine.attach(musicNode)
        engine.attach(tweenNode)
        engine.attach(specialNode)
        oneShotNodes.forEach { engine.attach($0) }

        engine.connect(musicNode, to: engine.mainMixerNode, format: levelMusicFormat)
        engine.connect(tweenNode, to: engine.mainMixerNode, format: tweenFormat)
        engine.connect(specialNode, to: engine.mainMixerNode, format: specialFormat)
        oneShotNodes.forEach {
            engine.connect($0, to: engine.mainMixerNode, format: gameplayFormat)
        }

        engine.mainMixerNode.outputVolume = 1
        engine.prepare()
        _ = ensureEngineRunning()
        synchronizePreferences()

        print(
            "AquaDot audio Phase 3B.1: persistent engine ready, \(buffers.count) original sounds cached, " +
            "gameplay \(gameplayFormat.channelCount)ch, music \(levelMusicFormat.channelCount)ch, " +
            "tween \(tweenFormat.channelCount)ch, special \(specialFormat.channelCount)ch, " +
            "\(oneShotNodes.count) one-shot voices"
        )
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

        if playIntro { play("OGS_Loops_\(stem)_start", volume: 0.62) }
        let key = "OGS_Loops_\(stem)"
        guard !preferences.muteAll,
              let buffer = buffers[key],
              ensureEngineRunning() else { return }

        specialNode.volume = Float(0.44 * preferences.soundEffectsVolume)
        specialNode.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        specialNode.play()
    }

    private func stopSpecialLoop() { specialNode.stop() }

    private func play(_ key: String, volume: Float = 0.75) {
        guard !preferences.muteAll,
              let buffer = buffers[key],
              ensureEngineRunning() else { return }

        let node = oneShotNodes[nextOneShotNode]
        nextOneShotNode = (nextOneShotNode + 1) % oneShotNodes.count
        node.stop()
        node.volume = volume * Float(preferences.soundEffectsVolume)
        node.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        node.play()
    }
}
