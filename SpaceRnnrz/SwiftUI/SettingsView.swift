//
//  SettingsView.swift
//  SpaceRunner
//
//  Created by Todd Dube : 2025
//  Purpose: Modern SwiftUI settings screen with iOS 18 design, accessibility features, and audio controls.
//

import SwiftUI

@available(iOS 18.0, *)
struct SettingsView: View {
    @Binding var isPresented: Bool
    let gameSettings: GameSettings
    let audioManager: GameAudio
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    @State private var musicVolume: Float = 0.15
    @State private var effectsVolume: Float = 1.0
    @State private var showingResetAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color.black.opacity(0.9)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        HeaderView()
                        
                        // Audio Settings
                        AudioSettingsSection(
                            musicVolume: $musicVolume,
                            effectsVolume: $effectsVolume,
                            audioManager: audioManager
                        )
                        
                        // Game Statistics
                        GameStatisticsSection(gameSettings: gameSettings)
                        
                        // Reset Section
                        ResetSection(
                            showingAlert: $showingResetAlert,
                            gameSettings: gameSettings
                        )
                        
                        Spacer(minLength: 44)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Done") {
                        dismissSettings()
                    }
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.blue)
                }
            }
        }
        .onAppear {
            musicVolume = audioManager.musicVolume
            effectsVolume = audioManager.effectsVolume
        }
        .alert("Reset All Data", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetAllData()
            }
        } message: {
            Text("This will reset all your high scores and statistics. This action cannot be undone.")
        }
        .accessibilityElement(children: .contain)
    }
    
    // MARK: - Actions
    private func dismissSettings() {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
        
        audioManager.playSoundEffect(.buttonTap)
        
        withAnimation(.easeInOut(duration: reduceMotion ? 0.1 : 0.3)) {
            isPresented = false
        }
    }
    
    private func resetAllData() {
        gameSettings.resetAllStats()
        
        let impact = UINotificationFeedbackGenerator()
        impact.notificationOccurred(.success)
    }
}

// MARK: - Header View
struct HeaderView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 48))
                .foregroundStyle(.blue.gradient)
            
            Text("Settings")
                .font(.largeTitle.weight(.bold))
                .foregroundStyle(.white)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Settings")
    }
}

// MARK: - Audio Settings Section
struct AudioSettingsSection: View {
    @Binding var musicVolume: Float
    @Binding var effectsVolume: Float
    let audioManager: GameAudio
    
    var body: some View {
        SettingsSection(title: "Audio", icon: "speaker.wave.3.fill") {
            VStack(spacing: 16) {
                VolumeSlider(
                    title: "Music",
                    value: $musicVolume,
                    onChange: { volume in
                        audioManager.setMusicVolume(volume)
                    }
                )
                
                VolumeSlider(
                    title: "Sound Effects",
                    value: $effectsVolume,
                    onChange: { volume in
                        audioManager.setEffectsVolume(volume)
                        // Play test sound
                        audioManager.playSoundEffect(.pickup)
                    }
                )
            }
        }
    }
}

// MARK: - Volume Slider
struct VolumeSlider: View {
    let title: String
    @Binding var value: Float
    let onChange: (Float) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(.white)
                
                Spacer()
                
                Text("\(Int(value * 100))%")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.white.opacity(0.7))
                    .frame(width: 40, alignment: .trailing)
            }
            
            HStack(spacing: 12) {
                Image(systemName: "speaker.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
                
                Slider(value: $value, in: 0...1) { _ in
                    onChange(value)
                }
                .accentColor(.blue)
                
                Image(systemName: "speaker.wave.3.fill")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title) volume")
        .accessibilityValue("\(Int(value * 100)) percent")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment:
                value = min(1.0, value + 0.1)
            case .decrement:
                value = max(0.0, value - 0.1)
            @unknown default:
                break
            }
            onChange(value)
        }
    }
}

// MARK: - Game Statistics Section
struct GameStatisticsSection: View {
    let gameSettings: GameSettings
    
    var body: some View {
        SettingsSection(title: "Statistics", icon: "chart.bar.fill") {
            VStack(spacing: 12) {
                StatRow(title: "Best Score", value: "\(gameSettings.bestScore)", icon: "trophy.fill", color: .yellow)
                StatRow(title: "Best Stars", value: "\(gameSettings.bestStars)", icon: "star.fill", color: .blue)
                StatRow(title: "Best Streak", value: "\(gameSettings.bestStreak)", icon: "flame.fill", color: .orange)
            }
        }
    }
}

// MARK: - Stat Row
struct StatRow: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 24)
            
            Text(title)
                .font(.headline)
                .foregroundStyle(.white)
            
            Spacer()
            
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title): \(value)")
    }
}

// MARK: - Reset Section
struct ResetSection: View {
    @Binding var showingAlert: Bool
    let gameSettings: GameSettings
    
    var body: some View {
        SettingsSection(title: "Data", icon: "trash.fill") {
            Button(action: { showingAlert = true }) {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.title3)
                        .foregroundStyle(.red)
                    
                    Text("Reset All Data")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(.red)
                    
                    Spacer()
                }
                .padding(.vertical, 4)
            }
            .accessibilityLabel("Reset all data")
            .accessibilityHint("Double tap to reset all game statistics. You will be asked to confirm.")
        }
    }
}

// MARK: - Settings Section Container
struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.blue)
                
                Text(title)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
            }
            
            content
                .padding(.leading, 32)
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 16)
                .fill(.white.opacity(0.05))
                .overlay {
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                }
        }
    }
}

#Preview {
    SettingsView(
        isPresented: .constant(true),
        gameSettings: GameSettings.shared,
        audioManager: GameAudio.shared
    )
    .preferredColorScheme(.dark)
}