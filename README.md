# SpaceRnnrz

An iOS space-themed endless runner game built with SpriteKit targeting iOS 18+.

## Overview

SpaceRnnrz is a fast-paced endless runner where players control a spaceship, dodge meteors, and collect stars while surviving as long as possible in the depths of space.

## Features

- **Modern iOS 18+ Architecture**: Built with @Observable patterns, async/await, and SwiftUI integration
- **Endless Gameplay**: Procedurally generated meteors and collectible stars
- **Progressive Difficulty**: Game speed and meteor frequency increase over time
- **Scoring System**: Points for survival time and star collection with streak bonuses
- **Lives System**: Multiple chances with visual life indicators
- **Accessibility Support**: VoiceOver, Dynamic Type, and haptic feedback
- **Audio Experience**: Spatial audio effects with AVAudioEngine

## Technical Highlights

- **SpriteKit Game Engine**: Smooth 60fps gameplay with optimized physics
- **SwiftUI Overlays**: Modern menu systems and settings interfaces
- **Responsive Design**: Supports both iPhone and iPad with adaptive layouts
- **Performance Optimized**: Sprite atlases, object pooling, and efficient collision detection

## Requirements

- iOS 18.0+
- Xcode 16+
- Swift 6+

## Getting Started

1. Open `SpaceRnnrz.xcodeproj` in Xcode
2. Select your target device/simulator
3. Build and run (⌘R)

## Game Controls

- **Tap anywhere**: Move ship up
- **Release**: Ship falls with gravity
- **Pause Button**: Top-left corner to pause/resume

## Architecture

The game follows a clean scene-based architecture:
- `GameScene`: Main gameplay logic and state management
- `MenuScene`: Main menu and navigation
- `Player`: Ship movement and collision handling
- `MeteorController`/`StarController`: Object spawning and management
- Modern font and audio systems with iOS 18+ features

Built with modern iOS development practices including proper memory management, accessibility support, and responsive design patterns.
