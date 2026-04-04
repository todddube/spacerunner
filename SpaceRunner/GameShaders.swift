//
//  GameShaders.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Thin wrapper that loads and caches custom GLSL fragment shaders from the
//  bundle, providing them as ready-to-use SKShader instances.
//
//  CONTENTS
//  - grayscaleShader  — applies a luminance-weighted desaturation (Grayscale.fsh)
//      used during game-over to drain the scene of colour
//  - shaderNamed(_:)  — internal cache-and-load helper; returns nil if the
//      shader source file is missing from the bundle
//

import Foundation
import SpriteKit

private class ShaderNames {
    class var GrayScale:String     {return "Grayscale.fsh"}
}

@MainActor let GameShadersSharedInstance = GameShaders()

@MainActor
class GameShaders {
    
    class var sharedInstance:GameShaders {
        return GameShadersSharedInstance
    }
    
    
    // MARK: - Private class constants
    fileprivate let shaderGrayscale = SKShader(fileNamed: ShaderNames.GrayScale)
    
    
    // MARK: - Init
    init() {
        
    }

    
    // MARK: - Shader Actions
    func shadeGray(node: SKNode) {
        if let sprite = node as? SKSpriteNode {
            sprite.shader = self.shaderGrayscale
            
            sprite.run(SKAction.wait(forDuration: 3.0), completion: {
                sprite.shader = nil
            })
        }
    }
}
