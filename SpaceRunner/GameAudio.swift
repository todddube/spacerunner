//
//  GameAudio.swift
//  SpaceRunner
//
//  Created by Todd Dube : 2025
//  Purpose: Modern audio engine with AVAudioEngine, spatial audio support, and proper session management for iOS 18+.
//

import Foundation
import AVFoundation
import OSLog
import Observation

@available(iOS 18.0, *)
@MainActor
@Observable
final class GameAudio {
    static let shared = GameAudio()
    
    // MARK: - Audio Resources
    enum MusicTrack: String, CaseIterable {
        case game = "GameMusic.mp3"
        
        var fileName: String { rawValue }
    }
    
    enum SoundEffect: String, CaseIterable {
        case shieldUp = "ShieldUp.caf"
        case shieldDown = "ShieldDown.caf"
        case buttonTap = "ButtonTap.caf"
        case explosion = "Explosion.caf"
        case pickup = "Pickup.caf"
        
        var fileName: String { rawValue }
    }
    
    // MARK: - Observable Properties
    private(set) var isInitialized: Bool = false
    private(set) var isMusicPlaying: Bool = false
    private(set) var musicVolume: Float = 0.15 {
        didSet { updateMusicVolume() }
    }
    private(set) var effectsVolume: Float = 1.0
    
    // MARK: - Private Properties
    private let audioEngine = AVAudioEngine()
    private let musicPlayerNode = AVAudioPlayerNode()
    private let effectsMixer = AVAudioMixerNode()
    private let musicMixer = AVAudioMixerNode()
    
    private var currentMusicBuffer: AVAudioPCMBuffer?
    private var soundEffectBuffers: [SoundEffect: AVAudioPCMBuffer] = [:]
    
    private let logger = Logger(subsystem: "com.todddube.spacerunner", category: "GameAudio")
    
    // MARK: - Initialization
    private init() {
        Task {
            await setupAudioEngine()
        }
    }
    
    // MARK: - Audio Engine Setup
    private func setupAudioEngine() async {
        do {
            try await configureAudioSession()
            setupAudioGraph()
            try audioEngine.start()
            await preloadAudioFiles()
            isInitialized = true
            logger.info("Audio engine initialized successfully")
        } catch {
            logger.error("Failed to initialize audio engine: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func configureAudioSession() async throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.ambient, mode: .gameChat, options: [.mixWithOthers])
        try session.setActive(true)
    }
    
    private func setupAudioGraph() {
        audioEngine.attach(musicPlayerNode)
        audioEngine.attach(musicMixer)
        audioEngine.attach(effectsMixer)
        
        // Connect music path
        audioEngine.connect(musicPlayerNode, to: musicMixer, format: nil)
        audioEngine.connect(musicMixer, to: audioEngine.mainMixerNode, format: nil)
        
        // Connect effects path
        audioEngine.connect(effectsMixer, to: audioEngine.mainMixerNode, format: nil)
        
        // Set initial volumes
        musicMixer.outputVolume = musicVolume
        effectsMixer.outputVolume = effectsVolume
    }
    
    private func preloadAudioFiles() async {
        await withTaskGroup(of: Void.self) { group in
            // Preload music
            for track in MusicTrack.allCases {
                group.addTask {
                    await self.loadMusicFile(track)
                }
            }
            
            // Preload sound effects
            for effect in SoundEffect.allCases {
                group.addTask {
                    await self.loadSoundEffect(effect)
                }
            }
        }
    }
    
    private func loadMusicFile(_ track: MusicTrack) async {
        guard let url = Bundle.main.url(forResource: track.fileName, withExtension: nil) else {
            logger.error("Could not find music file: \(track.fileName)")
            return
        }
        
        do {
            let file = try AVAudioFile(forReading: url)
            let format = file.processingFormat
            let frameCount = UInt32(file.length)
            
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                logger.error("Could not create buffer for music file: \(track.fileName)")
                return
            }
            
            try file.read(into: buffer)
            
            await MainActor.run {
                if track == .game {
                    self.currentMusicBuffer = buffer
                }
            }
        } catch {
            logger.error("Failed to load music file \(track.fileName): \(error.localizedDescription)")
        }
    }
    
    private func loadSoundEffect(_ effect: SoundEffect) async {
        guard let url = Bundle.main.url(forResource: effect.fileName, withExtension: nil) else {
            logger.error("Could not find sound effect file: \(effect.fileName)")
            return
        }
        
        do {
            let file = try AVAudioFile(forReading: url)
            let format = file.processingFormat
            let frameCount = UInt32(file.length)
            
            guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
                logger.error("Could not create buffer for sound effect: \(effect.fileName)")
                return
            }
            
            try file.read(into: buffer)
            
            await MainActor.run {
                self.soundEffectBuffers[effect] = buffer
            }
        } catch {
            logger.error("Failed to load sound effect \(effect.fileName): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Public Audio Control
    func playBackgroundMusic(_ track: MusicTrack = .game) {
        guard isInitialized, let buffer = currentMusicBuffer else {
            logger.warning("Audio not initialized or music buffer not loaded")
            return
        }
        
        stopBackgroundMusic()
        
        musicPlayerNode.scheduleBuffer(buffer, at: nil, options: .loops) { [weak self] in
            Task { @MainActor in
                self?.isMusicPlaying = false
            }
        }
        
        musicPlayerNode.play()
        isMusicPlaying = true
        logger.info("Started playing background music: \(track.fileName)")
    }
    
    func stopBackgroundMusic() {
        guard isMusicPlaying else { return }
        
        musicPlayerNode.stop()
        isMusicPlaying = false
        logger.info("Stopped background music")
    }
    
    func pauseBackgroundMusic() {
        guard isMusicPlaying else { return }
        
        musicPlayerNode.pause()
        isMusicPlaying = false
        logger.info("Paused background music")
    }
    
    func resumeBackgroundMusic() {
        guard isInitialized, !isMusicPlaying else { return }
        
        musicPlayerNode.play()
        isMusicPlaying = true
        logger.info("Resumed background music")
    }
    
    func playSoundEffect(_ effect: SoundEffect) {
        guard isInitialized, let buffer = soundEffectBuffers[effect] else {
            logger.warning("Sound effect not loaded: \(effect.fileName)")
            return
        }
        
        let playerNode = AVAudioPlayerNode()
        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: effectsMixer, format: buffer.format)
        
        playerNode.scheduleBuffer(buffer, at: nil) { [weak self] in
            Task { @MainActor in
                self?.audioEngine.detach(playerNode)
            }
        }
        
        playerNode.play()
    }
    
    // MARK: - Volume Control
    func setMusicVolume(_ volume: Float) {
        musicVolume = max(0.0, min(1.0, volume))
    }
    
    func setEffectsVolume(_ volume: Float) {
        effectsVolume = max(0.0, min(1.0, volume))
        effectsMixer.outputVolume = effectsVolume
    }
    
    private func updateMusicVolume() {
        musicMixer.outputVolume = musicVolume
    }
    
    // MARK: - Lifecycle
    func handleAppBackground() {
        pauseBackgroundMusic()
    }
    
    func handleAppForeground() {
        Task {
            try? await configureAudioSession()
            if !isMusicPlaying && currentMusicBuffer != nil {
                resumeBackgroundMusic()
            }
        }
    }
}
