# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SpaceRunner is an iOS game built with SpriteKit/Swift targeting iOS 26+. It's a space-themed endless runner where the player controls a ship, avoids meteors, and collects stars. It uses modern Swift 6 concurrency (`@Observable`, `@MainActor`, `async/await`), an AVAudioEngine audio system, and accessibility enhancements. (It is pure SpriteKit — there is no SwiftUI overlay in the build.)

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

**Note**: The project targets iOS 26+ and supports portrait orientation only. Building for physical devices requires proper provisioning profiles.

## Code Architecture

### Scene Management
The game follows a scene-based architecture using SpriteKit. There are exactly three scenes on disk, all live:
- `GameViewController.swift` - iOS 26+ view controller; presents `EnhancedMenuScene` then `GameScene`
- `EnhancedMenuScene.swift` - The main menu (the only menu). Liquid glass effects, dynamic lighting, ship-assembly intro
- `GameScene.swift` - Primary gameplay scene with game state management
- `GameOverScene.swift` - End game scene with retry (built from `SKLabelNode`s, no dedicated button/title nodes)

Note: `MenuScene.swift` and `GameMenuScene.swift` do NOT exist — earlier revisions referenced them but they were never in this tree.

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
- `PauseButton.swift` - Pause ↔ resume texture toggle
- `ModernStartButton.swift` - iOS 26+ style button with liquid glass effects and animations
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
- The deployment target is iOS 26.0, so no `@available` gating is needed for modern APIs

## Enhanced Graphics System

The game now features a comprehensive enhanced graphics system with:
- **Multi-layer parallax backgrounds** with three depth layers for convincing 3D depth
- **Dynamic lighting system** with ambient lighting, player-following light sources, and explosion flashes
- **Advanced particle systems** with multi-intensity explosion effects and debris simulation
- **Liquid glass UI effects** matching iOS 26+ design trends with shimmer and glow effects
- **Cinematic camera effects** including screen shake, zoom pulse, and slow motion
- **Spatial audio integration** with 3D positioning and environmental effects
- **Modern animation system** with spring animations and micro-interactions

### Enhanced Menu System

The new `EnhancedMenuScene` provides a modern iOS 26+ menu experience featuring:
- **Liquid glass button effects** with shimmer animations and interactive feedback
- **Dynamic lighting and ambience** creating atmospheric depth
- **Multi-layer parallax backgrounds** with animated nebula systems
- **Staggered entrance animations** with spring-based transitions
- **Touch sparkle effects** providing visual feedback on interaction
- **Author and version information** prominently displayed with breathing animations
- **Camera shake integration** for dramatic intro and transition effects
- **Modern typography and styling** matching iOS 26+ design language

The enhanced menu uses all the same visual systems as the game for a cohesive experience.

## Modern iOS 26+ Features

### SwiftUI Integration
The game is pure SpriteKit — there is currently **no** SwiftUI overlay in the build. The old
`SwiftUI/` scaffolding (`GameOverlay`, `PauseMenuView`, `SettingsView`) was never bridged into the
SpriteKit view (no `UIHostingController`) and has been removed. Pause and game-over UI are handled
in-scene via `StatusBar`, `PauseButton`, and `GameOverScene`. Re-introduce a `UIHostingController`
overlay here if SwiftUI menus are wanted later.

### Accessibility
- `Accessibility/AccessibilityManager.swift` - Centralized accessibility management
- VoiceOver support, haptic feedback, and motion preferences
- Dynamic type support throughout SwiftUI components

## Known Issues & Project File Management

### Project File Notes
- The active Xcode project is `SpaceRunner.xcodeproj`. (An abandoned rename experiment,
  `SpaceRnnrz.xcodeproj`, was removed — do not recreate it.)
- `SpaceRunner/Accessibility/AccessibilityManager.swift` IS in the target and used at runtime.
- When adding a new `.swift` file, make sure it is added to the `SpaceRunner` target, or it will
  silently never compile (this is how the old `SwiftUI/` folder became dead scaffolding).

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
- When adding a new `.swift` file, confirm it is added to the `SpaceRunner` target
- Ensure deployment target is set to iOS 26.0