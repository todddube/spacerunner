//
//  GameOverlay.swift
//  SpaceRunner
//
//  Created by Todd Dube : 2025
//  Purpose: SwiftUI overlay system for game menus with modern iOS 18 design and accessibility.
//

import SwiftUI
import SpriteKit

@available(iOS 18.0, *)
@MainActor
struct GameOverlay: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    @State private var gameSettings = GameSettings.shared
    @State private var audioManager = GameAudio.shared
    @State private var showingPauseMenu = false
    @State private var showingSettings = false
    
    let gameScene: GameScene
    
    var body: some View {
        ZStack {
            // Invisible overlay to detect taps
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture(perform: handleBackgroundTap)
            
            // Game UI overlays
            VStack {
                // Top UI
                HStack {
                    Spacer()
                    PauseButton(action: togglePauseMenu)
                        .padding(.trailing)
                }
                .padding(.top, 44) // Safe area
                
                Spacer()
                
                // Bottom UI - only show during tutorial
                if gameScene.gameState.currentPhase == .tutorial {
                    TutorialOverlay()
                        .transition(.opacity)
                }
            }
        }
        .overlay(alignment: .center) {
            // Pause menu overlay
            if showingPauseMenu {
                PauseMenuView(
                    isPresented: $showingPauseMenu,
                    showingSettings: $showingSettings,
                    onResume: resumeGame,
                    onRestart: restartGame,
                    onMainMenu: returnToMainMenu
                )
                .transition(.scale.combined(with: .opacity))
            }
        }
        .overlay(alignment: .center) {
            // Settings overlay
            if showingSettings {
                SettingsView(
                    isPresented: $showingSettings,
                    gameSettings: gameSettings,
                    audioManager: audioManager
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeInOut(duration: reduceMotion ? 0.1 : 0.3), value: showingPauseMenu)
        .animation(.easeInOut(duration: reduceMotion ? 0.1 : 0.3), value: showingSettings)
    }
    
    // MARK: - Actions
    private func handleBackgroundTap() {
        // Pass tap through to SpriteKit scene
    }
    
    private func togglePauseMenu() {
        withAnimation {
            showingPauseMenu.toggle()
        }
        
        if showingPauseMenu {
            Task {
                await gameScene.pauseGame()
            }
        }
        
        // Haptic feedback
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
        
        audioManager.playSoundEffect(.buttonTap)
    }
    
    private func resumeGame() {
        withAnimation {
            showingPauseMenu = false
        }
        
        Task {
            await gameScene.resumeGame()
        }
    }
    
    private func restartGame() {
        withAnimation {
            showingPauseMenu = false
        }
        
        Task {
            await gameScene.restartGame()
        }
    }
    
    private func returnToMainMenu() {
        withAnimation {
            showingPauseMenu = false
        }
        
        Task {
            await gameScene.returnToMainMenu()
        }
    }
}

// MARK: - Tutorial Overlay
struct TutorialOverlay: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Tap to move your ship")
                .font(.title2.weight(.semibold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
            
            Text("Avoid meteors • Collect stars")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.8))
                .multilineTextAlignment(.center)
            
            Button("Start Game") {
                // This will be handled by the SpriteKit scene
            }
            .buttonStyle(GameButtonStyle())
        }
        .padding(.horizontal, 32)
        .padding(.bottom, 44) // Safe area
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tutorial instructions: Tap to move your ship, avoid meteors, collect stars. Start game button available.")
    }
}

// MARK: - Modern Pause Button
struct PauseButton: View {
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            Image(systemName: "pause.circle.fill")
                .font(.title2)
                .foregroundStyle(.white)
                .background {
                    Circle()
                        .fill(.black.opacity(0.3))
                        .frame(width: 44, height: 44)
                }
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .pressEvents(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
        .accessibilityLabel("Pause game")
        .accessibilityHint("Double tap to pause the game")
    }
}

// MARK: - Press Events Modifier
extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

struct PressEventsModifier: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

// MARK: - Game Button Style
struct GameButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background {
                RoundedRectangle(cornerRadius: 25)
                    .fill(.blue.gradient)
                    .shadow(color: .blue.opacity(0.3), radius: 8, y: 4)
            }
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: reduceMotion ? 0.1 : 0.2), value: configuration.isPressed)
    }
}

#Preview {
    GameOverlay(gameScene: GameScene(size: CGSize(width: 375, height: 812)))
        .preferredColorScheme(.dark)
}