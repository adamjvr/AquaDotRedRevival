import AVFoundation
import Foundation

/// Modern playback backend for the original AquaDot audio.
/// Runtime copies are losslessly decoded from the shipped Ogg/Vorbis `.adrs`
/// resources into ALAC/m4a; preservation keeps every original `.adrs` byte intact.
final class AquaDotAudioSystem {
    private var resourceIndex: [String: URL] = [:]
    private var oneShots: [AVAudioPlayer] = []
    private var musicPlayer: AVAudioPlayer?
    private var specialPlayer: AVAudioPlayer?
    private var lastDamageSoundTime: TimeInterval = 0

    init(bundle: Bundle = .main) {
        let roots: [String?] = ["OriginalAudioRuntime", nil]
        for subdirectory in roots {
            for url in bundle.urls(forResourcesWithExtension: "m4a", subdirectory: subdirectory) ?? [] {
                resourceIndex[url.deletingPathExtension().lastPathComponent] = url
            }
        }
    }

    func startLevelMusic(variant: Int) {
        let level = max(1, min(6, variant))
        let key = "OGS_Music_level\(level)"
        guard let url = resourceIndex[key] else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0.55
            player.prepareToPlay()
            player.play()
            musicPlayer = player
        } catch {
            print("AquaDot audio: could not start original level music: \(error)")
        }
    }

    func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
    }

    func handle(_ events: [AquaDotGameEvent]) {
        oneShots.removeAll { !$0.isPlaying }
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
                startSpecialLoop(power)
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

    private func startSpecialLoop(_ power: AquaDotSpecialPower) {
        stopSpecialLoop()

        let stem: String
        switch power {
        case let .yummy(value): stem = "yummy_\(value.rawValue)"
        case let .yuk(value): stem = "yuk_\(value.rawValue)"
        }

        // The shipped resources contain a short ~250 ms start sound plus a
        // longer matching loop for every Yummy/Yuk ability. Preserve that pair.
        play("OGS_Loops_\(stem)_start", volume: 0.62)
        guard let url = resourceIndex["OGS_Loops_\(stem)"] else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = -1
            player.volume = 0.44
            player.prepareToPlay()
            player.play()
            specialPlayer = player
        } catch {
            print("AquaDot audio: could not start special-power loop \(stem): \(error)")
        }
    }

    private func stopSpecialLoop() {
        specialPlayer?.stop()
        specialPlayer = nil
    }

    private func play(_ key: String, volume: Float = 0.75) {
        guard let url = resourceIndex[key] else { return }
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.prepareToPlay()
            player.play()
            oneShots.append(player)
        } catch {
            print("AquaDot audio: could not play \(key): \(error)")
        }
    }
}
