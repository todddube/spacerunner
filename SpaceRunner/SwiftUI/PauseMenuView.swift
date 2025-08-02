//
//  PauseMenuView.swift
//  SpaceRunner
//
//  Created by Todd Dube : 2025
//  Purpose: Modern SwiftUI pause menu with iOS 18 design patterns and full accessibility support.
//

import SwiftUI

@available(iOS 18.0, *)
struct PauseMenuView: View {
    @Binding var isPresented: Bool
    @Binding var showingSettings: Bool
    
    let onResume: () -> Void
    let onRestart: () -> Void
    let onMainMenu: () -> Void
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    @State private var audioManager = GameAudio.shared
    @State private var gameSettings = GameSettings.shared
    
    var body: some View {
        ZStack {
            // Background blur
            Color.black.opacity(0.7)
                .ignoresSafeArea()
                .onTapGesture {
                    dismissMenu()
                }
            
            // Menu content
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Text("Game Paused")
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)
                    
                    if dynamicTypeSize.isAccessibilitySize {
                        Text("Choose an option below")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Game Paused. Choose an option below.")
                
                // Game stats
                GameStatsView()
                
                // Menu buttons
                VStack(spacing: 16) {
                    PauseMenuButton(
                        title: "Resume Game",
                        icon: "play.fill",
                        color: .green,
                        action: {
                            playButtonSound()
                            onResume()
                        }
                    )
                    .keyboardShortcut(.space, modifiers: [])
                    
                    PauseMenuButton(
                        title: "Settings",
                        icon: "gearshape.fill",
                        color: .blue,
                        action: {
                            playButtonSound()
                            showSettings()
                        }
                    )
                    
                    PauseMenuButton(
                        title: "Restart Game",
                        icon: "arrow.clockwise",
                        color: .orange,
                        action: {
                            playButtonSound()
                            onRestart()
                        }
                    )
                    
                    PauseMenuButton(
                        title: "Main Menu",
                        icon: "house.fill",
                        color: .red,
                        action: {
                            playButtonSound()
                            onMainMenu()
                        }
                    )
                }
            }
            .padding(32)
            .background {
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.3), radius: 20, y: 10)
            }
            .padding(.horizontal, 20)
            .scaleEffect(isPresented ? 1.0 : 0.8)
            .opacity(isPresented ? 1.0 : 0.0)
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Pause menu")
    }
    
    // MARK: - Actions
    private func dismissMenu() {
        withAnimation(.easeInOut(duration: reduceMotion ? 0.1 : 0.3)) {
            isPresented = false
        }
        onResume()
    }
    
    private func showSettings() {
        withAnimation(.easeInOut(duration: reduceMotion ? 0.1 : 0.3)) {
            showingSettings = true
        }
    }
    
    private func playButtonSound() {
        audioManager.playSoundEffect(.buttonTap)
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()
    }
}

// MARK: - Game Stats View
struct GameStatsView: View {
    @State private var gameSettings = GameSettings.shared
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 20) {
                StatItem(
                    title: "Best Score",
                    value: "\(gameSettings.bestScore)",
                    icon: "trophy.fill",
                    color: .yellow
                )
                
                StatItem(
                    title: "Best Stars",
                    value: "\(gameSettings.bestStars)",
                    icon: "star.fill",
                    color: .blue
                )
                
                StatItem(
                    title: "Best Streak",
                    value: "\(gameSettings.bestStreak)",
                    icon: "flame.fill",
                    color: .orange
                )
            }
        }
        .padding(.vertical, 16)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(.black.opacity(0.2))
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Game statistics: Best score \(gameSettings.bestScore), Best stars \(gameSettings.bestStars), Best streak \(gameSettings.bestStreak)")
    }
}

// MARK: - Stat Item
struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
            
            Text(value)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Pause Menu Button
struct PauseMenuButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(color)
                    .frame(width: 24)
                
                Text(title)
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.white.opacity(0.1))
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.2), lineWidth: 1)
                    }
            }
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: reduceMotion ? 0.05 : 0.1), value: isPressed)
        }
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
        .accessibilityHint("Double tap to \(title.lowercased())")
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        
        PauseMenuView(
            isPresented: .constant(true),
            showingSettings: .constant(false),
            onResume: {},
            onRestart: {},
            onMainMenu: {}
        )
    }
    .preferredColorScheme(.dark)
}