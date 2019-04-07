//
//  GameTextures.swift
//  SpaceRunner
//
//  Created by Todd Dube on 3/20/16.
//  Copyright © 2016 Todd Dube. All rights reserved.
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
