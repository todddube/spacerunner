//
//  GameAudio.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Full-featured audio manager built on AVAudioEngine. Pre-loads all music
//  and sound-effect buffers at startup, converts them to the engine's native
//  format to prevent static, and plays them through a pooled node system so
//  multiple effects can overlap without dynamic node creation.
//
//  AUDIO GRAPH
//  musicPlayerNode → musicMixer ─┐
//                                 ├─→ mainMixerNode → outputNode
//  effectsPlayerPool → effectsMixer ┘
//
//  PUBLIC API
//  - initializeAudio()            — async setup; call once from AppDelegate
//  - playBackgroundMusic(_:)      — loop GameMusic.mp3 through music path
//  - pauseBackgroundMusic()       — pause without discarding buffer position
//  - resumeBackgroundMusic()      — continue from paused position
//  - stopBackgroundMusic()        — stop and reset music player
//  - playSoundEffect(_:)          — fire-and-forget from the player node pool
//  - setMusicVolume(_:)           — 0.0 – 1.0 master music volume
//  - setEffectsVolume(_:)         — 0.0 – 1.0 master effects volume
//  - handleAppBackground()        — pause music when app backgrounds
//  - handleAppForeground()        — reconfigure session and resume music
//
//  SPATIAL EXTENSIONS  → see GameAudio+SpatialEffects.swift
//
//  REQUIRES iOS 18.0+  — @Observable, @MainActor, @preconcurrency AVFoundation
//

import Foundation
@preconcurrency import AVFoundation
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
    private(set) var musicVolume: Float = 0.6 {
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
    
    // Sound effect player pool to avoid dynamic node creation
    private var effectPlayerNodes: [AVAudioPlayerNode] = []
    private var availablePlayerNodes: [AVAudioPlayerNode] = []
    private let maxEffectPlayers = 4 // Reduced to prevent audio overload
    
    private let logger = Logger(subsystem: "com.todddube.spacerunner", category: "GameAudio")
    
    // MARK: - Initialization
    private init() {
        // Initialization happens asynchronously
    }
    
    func initializeAudio() async {
        guard !isInitialized else { return }
        await setupAudioEngine()
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
        try session.setCategory(.playback, mode: .gameChat, options: [.mixWithOthers])
        try session.setPreferredIOBufferDuration(0.005) // 5ms buffer for lower latency
        try session.setPreferredSampleRate(44100) // Standard sample rate
        try session.setActive(true)
        
        // Monitor for audio interruptions
        NotificationCenter.default.addObserver(
            forName: AVAudioSession.interruptionNotification,
            object: session,
            queue: .main
        ) { _ in
            self.logger.warning("Audio session interrupted - may cause HALC warnings")
        }
    }
    
    private func setupAudioGraph() {
        let format = audioEngine.outputNode.inputFormat(forBus: 0)

        audioEngine.attach(musicPlayerNode)
        audioEngine.attach(musicMixer)
        audioEngine.attach(effectsMixer)

        // Connect music path with consistent format
        audioEngine.connect(musicPlayerNode, to: musicMixer, format: format)
        audioEngine.connect(musicMixer, to: audioEngine.mainMixerNode, format: format)

        // Connect effects path with consistent format
        audioEngine.connect(effectsMixer, to: audioEngine.mainMixerNode, format: format)

        // Create and attach sound effect player pool
        setupEffectPlayerPool(format: format)

        // Set initial volumes
        musicMixer.outputVolume   = musicVolume
        effectsMixer.outputVolume = effectsVolume
    }
    
    private func setupEffectPlayerPool(format: AVAudioFormat) {
        effectPlayerNodes.removeAll()
        availablePlayerNodes.removeAll()
        
        for _ in 0..<maxEffectPlayers {
            let playerNode = AVAudioPlayerNode()
            audioEngine.attach(playerNode)
            audioEngine.connect(playerNode, to: effectsMixer, format: format)
            effectPlayerNodes.append(playerNode)
            availablePlayerNodes.append(playerNode)
        }
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
            let outputFormat = audioEngine.outputNode.inputFormat(forBus: 0)
            
            // Convert to engine's format to prevent static/distortion
            let converter = AVAudioConverter(from: file.processingFormat, to: outputFormat)
            guard let converter = converter else {
                logger.error("Could not create audio converter for: \(track.fileName)")
                return
            }
            
            let frameCount = UInt32(file.length)
            let outputFrameCount = UInt32(Double(frameCount) * outputFormat.sampleRate / file.processingFormat.sampleRate)
            
            guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: frameCount),
                  let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputFrameCount) else {
                logger.error("Could not create buffers for music file: \(track.fileName)")
                return
            }
            
            try file.read(into: inputBuffer)
            
            var error: NSError?
            // Use explicit input handler without Sendable closure
            let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
                outStatus.pointee = .haveData
                return inputBuffer
            }
            let status = converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)
            
            if let error = error {
                logger.error("Audio conversion failed for \(track.fileName): \(error.localizedDescription)")
                return
            }
            
            guard status == .haveData else {
                logger.error("Audio conversion returned unexpected status for \(track.fileName)")
                return
            }
            
            await MainActor.run {
                if track == .game {
                    self.currentMusicBuffer = outputBuffer
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
            let outputFormat = audioEngine.outputNode.inputFormat(forBus: 0)
            
            // Convert to engine's format to prevent static/distortion
            let converter = AVAudioConverter(from: file.processingFormat, to: outputFormat)
            guard let converter = converter else {
                logger.error("Could not create audio converter for: \(effect.fileName)")
                return
            }
            
            let frameCount = UInt32(file.length)
            let outputFrameCount = UInt32(Double(frameCount) * outputFormat.sampleRate / file.processingFormat.sampleRate)
            
            guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: file.processingFormat, frameCapacity: frameCount),
                  let outputBuffer = AVAudioPCMBuffer(pcmFormat: outputFormat, frameCapacity: outputFrameCount) else {
                logger.error("Could not create buffers for sound effect: \(effect.fileName)")
                return
            }
            
            try file.read(into: inputBuffer)
            
            var error: NSError?
            // Use explicit input handler without Sendable closure
            let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
                outStatus.pointee = .haveData
                return inputBuffer
            }
            let status = converter.convert(to: outputBuffer, error: &error, withInputFrom: inputBlock)
            
            if let error = error {
                logger.error("Audio conversion failed for \(effect.fileName): \(error.localizedDescription)")
                return
            }
            
            guard status == .haveData else {
                logger.error("Audio conversion returned unexpected status for \(effect.fileName)")
                return
            }
            
            await MainActor.run {
                self.soundEffectBuffers[effect] = outputBuffer
            }
        } catch {
            logger.error("Failed to load sound effect \(effect.fileName): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Public Audio Control
    func playBackgroundMusic(_ track: MusicTrack = .game) {
        Task {
            await ensureInitialized()
            await MainActor.run {
                guard isInitialized, let buffer = currentMusicBuffer else {
                    logger.warning("Audio not initialized or music buffer not loaded")
                    return
                }
                startPlayingMusic(buffer: buffer, track: track)
            }
        }
    }
    
    private func startPlayingMusic(buffer: AVAudioPCMBuffer, track: MusicTrack) {
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
    
    private func ensureInitialized() async {
        if !isInitialized {
            await initializeAudio()
        }
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
        
        guard let playerNode = getAvailablePlayerNode() else {
            logger.warning("No available player nodes for sound effect: \(effect.fileName)")
            return
        }
        
        // Store reference to avoid Sendable closure capture
        let nodeToReturn = playerNode
        playerNode.scheduleBuffer(buffer, at: nil) { [weak self] in
            Task { @MainActor [weak self, nodeToReturn] in
                self?.returnPlayerNode(nodeToReturn)
            }
        }
        
        playerNode.play()
    }
    
    private func getAvailablePlayerNode() -> AVAudioPlayerNode? {
        if !availablePlayerNodes.isEmpty {
            return availablePlayerNodes.removeFirst()
        }
        
        // If no nodes available, stop the oldest playing node and reuse it
        for node in effectPlayerNodes {
            if node.isPlaying {
                node.stop()
                return node
            }
        }
        
        return effectPlayerNodes.first
    }
    
    private func returnPlayerNode(_ node: AVAudioPlayerNode) {
        guard !availablePlayerNodes.contains(node) else { return }
        availablePlayerNodes.append(node)
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
        // Pause the entire engine so no sound effects fire while backgrounded
        audioEngine.pause()
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    func handleAppForeground() {
        Task {
            try? await configureAudioSession()
            // Restart the engine if it was paused during backgrounding
            if !audioEngine.isRunning {
                try? audioEngine.start()
            }
            if !isMusicPlaying && currentMusicBuffer != nil {
                resumeBackgroundMusic()
            }
        }
    }
}
