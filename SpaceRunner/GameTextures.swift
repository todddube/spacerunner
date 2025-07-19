//
//  GameTextures.swift
//  SpaceRunner
//
//  Created by Todd Dube : 2025
//  Purpose: Centralized texture loading and management for all game sprites and assets.
//

import Foundation
import SpriteKit

let GameTexturesSharedInstance = GameTextures()

class GameTextures {
    
    class var sharedInstance:GameTextures {
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
    
    // MARK: - Public conviences functions
    func textureWithName(name:String) -> SKTexture {
        return SKTexture(imageNamed: name)
    }
    
    func spriteWithName(name:String) -> SKSpriteNode {
        return SKSpriteNode(imageNamed: name)
    }
}
