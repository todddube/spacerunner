# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

SpaceRunner is an iOS game built with SpriteKit/Swift. It's a space-themed endless runner where the player controls a ship, avoids meteors, and collects stars.

## Build System and Commands

This is an Xcode project that uses the standard iOS development workflow:

- **Build**: Open `SpaceRunner.xcodeproj` in Xcode and use Cmd+B to build
- **Run**: Use Cmd+R to run on simulator or connected device
- **Test**: Use Cmd+U to run unit tests (located in `SpaceRunnerTests/`)
- **UI Tests**: UI tests are available in `SpaceRunnerUITests/`

The project targets iOS with support for both iPhone and iPad orientations.

## Code Architecture

### Scene Management
The game follows a scene-based architecture using SpriteKit:
- `GameViewController.swift` - Main view controller that initializes the game
- `MenuScene.swift` - Main menu with play button and title
- `GameScene.swift` - Primary gameplay scene with game state management
- `GameOverScene.swift` - End game scene with retry functionality

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
- `ScoreBoard.swift` - Score display and high score tracking
- `StatusBar.swift` - Game UI elements during play

### Resource Management
- `GameTextures.swift` - Centralized texture loading and management
- `GameAudio.swift` - Sound effect and music management
- `GameFonts.swift` - Font loading and text styling
- `GameParticles.swift` - Particle effect definitions
- `Constants.swift` - Game constants, sprite names, physics categories, and layer z-positions

### Utilities
- `Math.swift` - Mathematical helper functions
- `Colors.swift` - Color definitions
- `GameShaders.swift` - Custom shader effects
- `SKTUtils/` library - Extended SpriteKit utilities for animations and effects

### Assets Structure
- Game sprites organized in `Assets.xcassets` with sprite atlases for performance
- Audio files in `GameResources/Sounds/` and `GameResources/Music/`
- Custom font (`editundo.ttf`) for game text
- Particle effect files (`.sks`) for explosions and visual effects

## Development Notes

- Debug mode can be enabled by setting `kDebug = true` in `Constants.swift`
- Game supports both iPhone and iPad with responsive sizing via `kViewSize` and `kDeviceTablet`
- Physics collision detection uses category bitmasks defined in `Contact` class
- All sprite names are centralized in the `SpriteName` class for consistency
- Game uses z-position layers defined in `GameLayer` class for proper rendering order