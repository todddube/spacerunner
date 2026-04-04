# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SpaceRunner is an iOS game built with SpriteKit/Swift targeting iOS 18+. It's a space-themed endless runner where the player controls a ship, avoids meteors, and collects stars. The project includes modern iOS 18 features like SwiftUI overlays, accessibility enhancements, and advanced audio management.

## Build System and Commands

This is an Xcode project that uses the standard iOS development workflow:

### GUI Commands (Xcode)
- **Build**: Open `SpaceRunner.xcodeproj` in Xcode and use Cmd+B to build
- **Run**: Use Cmd+R to run on simulator or connected device
- **Test**: Use Cmd+U to run unit tests (located in `SpaceRunnerTests/`)
- **UI Tests**: UI tests are available in `SpaceRunnerUITests/`

### Command Line Commands (for Claude Code)
- **List schemes**: `xcodebuild -list -project SpaceRunner.xcodeproj`
- **Build for simulator**: `xcodebuild -project SpaceRunner.xcodeproj -scheme SpaceRunner -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' build`
- **Build for any simulator**: `xcodebuild -project SpaceRunner.xcodeproj -scheme SpaceRunner -configuration Debug -destination 'platform=iOS Simulator' build`
- **Run tests**: `xcodebuild -project SpaceRunner.xcodeproj -scheme SpaceRunner -configuration Debug -destination 'platform=iOS Simulator,name=iPhone 16' test`
- **Clean**: `xcodebuild -project SpaceRunner.xcodeproj -scheme SpaceRunner clean`
- **Extract errors only**: `xcodebuild ... build 2>&1 | grep -E "(error:|warning:)" | head -20`

**Note**: The project targets iOS 18+ and supports portrait orientation only. Building for physical devices requires proper provisioning profiles.

## Code Architecture

### Scene Management
The game follows a scene-based architecture using SpriteKit:
- `GameViewController.swift` - Modern iOS 18+ view controller with SwiftUI overlay support
- `MenuScene.swift` - Original main menu with play button and title
- `EnhancedMenuScene.swift` - Modern enhanced menu with liquid glass effects, dynamic lighting, and advanced animations
- `GameScene.swift` - Primary gameplay scene with game state management
- `GameOverScene.swift` - End game scene with retry functionality
- `GameMenuScene.swift` - Additional menu scene functionality

### Game State Management
`GameScene` handles four main game states via a `GameState` enum:
- `tutorial` - Initial instructions
- `running` - Active gameplay
- `paused` - Game paused state
- `gameOver` - End game state

### Core Game Components
- `Player.swift` - Player ship with movement and collision
- `Meteor.swift` + `MeteorController.swift` - Obstacle generation and management
- `Star.swift` + `StarController.swift` - Collectible item system
- `Background.swift` - Scrolling background management

### UI Components
Button classes for game interaction:
- `PlayButton.swift`, `StartButton.swift`, `RetryButton.swift`, `PauseButton.swift`
- `ModernStartButton.swift` - iOS 18+ style button with liquid glass effects and animations
- `ScoreBoard.swift` - Score display and high score tracking
- `StatusBar.swift` - Game UI elements during play
- `StatusBar+GlassEffect.swift` - Glass-styled UI elements with blurred backgrounds and animations

### Enhanced Visual Systems
- `ParallaxBackground.swift` - Multi-layer parallax scrolling with depth perception
- `NebulaSystem.swift` - Animated space nebulae with floating effects
- `DynamicLighting.swift` - Real-time lighting system with ambient and explosive effects
- `EnhancedParticleManager.swift` - Advanced particle systems for explosions and effects
- `CameraEffects.swift` - Cinematic camera system with shake, zoom, and slow motion
- `AnimationController.swift` - Centralized animation management with spring animations
- `Player+EnhancedEffects.swift` - Enhanced ship effects with multi-layered engine trails

### Resource Management
- `GameTextures.swift` - Centralized texture loading and management
- `GameAudio.swift` - Modern AVAudioEngine-based audio system with spatial audio support
- `GameAudio+SpatialEffects.swift` - 3D audio positioning with distance and panning
- `GameFonts.swift` - Font loading and text styling
- `GameParticles.swift` - Particle effect definitions
- `GameSettings.swift` - Game configuration and user preferences
- `Constants.swift` - Game constants, sprite names, physics categories, and layer z-positions

**Audio System**: Uses `GameAudio.shared.playSoundEffect(.buttonTap)` instead of old `sharedInstance` pattern.

### Utilities
- `Math.swift` - Mathematical helper functions
- `Colors.swift` - Color definitions
- `GameShaders.swift` - Custom shader effects
- `CGPoint+Extensions.swift` - Core Graphics extensions for vector operations
- `SKTUtils/` library - Extended SpriteKit utilities for animations and effects

### Assets Structure
- Game sprites organized in `Assets.xcassets` with sprite atlases for performance
- Audio files in `GameResources/Sounds/` and `GameResources/Music/`
- Custom font (`editundo.ttf`) for game text
- Particle effect files (`.sks`) for explosions and visual effects

### Documentation
- `ENHANCED_GRAPHICS_README.md` - Comprehensive documentation of the enhanced graphics and animation system

## Development Notes

- Debug mode can be enabled by setting `kDebug = true` in `Constants.swift`
- Game supports both iPhone and iPad with responsive sizing via `kViewSize` and `kDeviceTablet`
- Physics collision detection uses category bitmasks defined in `Contact` class
- All sprite names are centralized in the `SpriteName` class for consistency
- Game uses z-position layers defined in `GameLayer` class for proper rendering order
- The project uses `@MainActor` and `@Observable` for modern Swift concurrency
- All view controllers are marked `@available(iOS 18.0, *)` for modern iOS features

## Enhanced Graphics System

The game now features a comprehensive enhanced graphics system with:
- **Multi-layer parallax backgrounds** with three depth layers for convincing 3D depth
- **Dynamic lighting system** with ambient lighting, player-following light sources, and explosion flashes
- **Advanced particle systems** with multi-intensity explosion effects and debris simulation
- **Liquid glass UI effects** matching iOS 18+ design trends with shimmer and glow effects
- **Cinematic camera effects** including screen shake, zoom pulse, and slow motion
- **Spatial audio integration** with 3D positioning and environmental effects
- **Modern animation system** with spring animations and micro-interactions

### Enhanced Menu System

The new `EnhancedMenuScene` provides a modern iOS 18+ menu experience featuring:
- **Liquid glass button effects** with shimmer animations and interactive feedback
- **Dynamic lighting and ambience** creating atmospheric depth
- **Multi-layer parallax backgrounds** with animated nebula systems
- **Staggered entrance animations** with spring-based transitions
- **Touch sparkle effects** providing visual feedback on interaction
- **Author and version information** prominently displayed with breathing animations
- **Camera shake integration** for dramatic intro and transition effects
- **Modern typography and styling** matching iOS 18+ design language

The enhanced menu uses all the same visual systems as the game for a cohesive experience.

Note: The enhanced graphics system includes both original and duplicate versions of some files (with " 2" suffix) from development iterations.

## Modern iOS 18+ Features

### SwiftUI Integration
- `SwiftUI/GameOverlay.swift` - Modern SwiftUI overlay system for game menus
- `SwiftUI/PauseMenuView.swift` - SwiftUI pause menu with accessibility support
- `SwiftUI/SettingsView.swift` - Settings interface with dynamic type support

### Accessibility
- `Accessibility/AccessibilityManager.swift` - Centralized accessibility management
- VoiceOver support, haptic feedback, and motion preferences
- Dynamic type support throughout SwiftUI components

## Known Issues & Project File Management

### Missing Project References
Some files exist in the filesystem but are not properly included in the Xcode project:
- `SpaceRunner/SwiftUI/` folder contents
- `SpaceRunner/Accessibility/` folder contents

To fix: Add these files to the Xcode project manually via "Add Files to Project".

### Common Build Errors
1. **"cannot find type 'GameOverlay'"** - SwiftUI files not in project
2. **"cannot find 'AccessibilityManager'"** - Accessibility files not in project
3. **"GameAudio has no member 'sharedInstance'"** - Use `GameAudio.shared` instead
4. **Audio method errors** - Use `playSoundEffect(.buttonTap)` instead of property access
5. **Main actor isolation warnings** - Expected with Swift 6, usually safe to ignore
6. **Duplicate filename errors** - Remove duplicate files with " 2" suffix from development iterations
7. **CGPoint+Extensions.swift conflict** - Remove root-level duplicate, use SKTUtils version
8. **Type conversion errors** - Ensure proper Float/CGFloat conversions for physics and animation properties
9. **Missing sound effects** - Check GameAudio.SoundEffect enum for available audio files before referencing

### Common Runtime Errors
6. **"GSFont: file doesn't exist"** - Custom font path issue in Info.plist
   - Font files are in `GameResources/Fonts/Base.lproj/editundo.ttf`
   - Info.plist must reference: `GameResources/Fonts/Base.lproj/editundo.ttf`
   - GameFonts.swift includes fallback to system font if custom font fails

7. **No game music playing** - Audio initialization and session issues
   - GameAudio now initializes in AppDelegate.didFinishLaunching
   - Audio session changed from `.ambient` to `.playback` for proper game music
   - Music volume increased from 0.15 to 0.6 for audibility
   - Async initialization ensures audio is ready before music attempts to play

### Troubleshooting
- Always build for iOS Simulator to avoid provisioning issues
- Use `grep -E "(error:|warning:)"` to filter build output for actual issues
- Check that all SwiftUI and Accessibility files are added to the target
- Ensure deployment target is set to iOS 18.0+