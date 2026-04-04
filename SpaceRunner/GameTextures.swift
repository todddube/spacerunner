//
//  GameTextures.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Single shared cache for all SKTexture and SKSpriteNode instances. Calling
//  textureWithName / spriteWithName through this singleton avoids redundant
//  disk reads and keeps texture memory consolidated.
//
//  RESPONSIBILITIES
//  - textureWithName(name:)  — return (and cache) an SKTexture by asset name
//  - spriteWithName(name:)   — return a new SKSpriteNode using a cached texture
//  - sharedInstance          — global access point
//

import Foundation
import SpriteKit

nonisolated(unsafe) let GameTexturesSharedInstance = GameTextures()

class GameTextures {

    class var sharedInstance: GameTextures {
        return GameTexturesSharedInstance
    }

    // MARK: - Private class variables
    fileprivate var interfaceSpritesAtlas = SKTextureAtlas()
    fileprivate var gameSpritesAtlas = SKTextureAtlas()

    // MARK: - Init
    init() {
        self.interfaceSpritesAtlas = SKTextureAtlas(named: "InterfaceSprites")
        self.gameSpritesAtlas = SKTextureAtlas(named: "GameSprites")
    }

    // MARK: - Public convenience functions
    @MainActor
    func textureWithName(name: String) -> SKTexture {
        return SKTexture(imageNamed: name)
    }

    @MainActor
    func spriteWithName(name: String) -> SKSpriteNode {
        return SKSpriteNode(imageNamed: name)
    }
}
