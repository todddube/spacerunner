//
//  ShipBreakEffect.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Provides two ship-disassembly effects triggered by meteor collisions:
//
//  1. playHitEffect(for:in:)
//     Non-fatal hit — the ship's four texture quadrants burst outward ~44 pt
//     then snap back together in ~0.3 s total. The player sprite is briefly
//     hidden while fragments are visible, then restored so normal blinking
//     immunity can take over.
//
//  2. playDestroyEffect(for:in:)
//     Final-life kill — four quadrant fragments plus four coloured debris
//     shards explode outward, spin, shrink, and fade. A white flash fires
//     at the ship's position. The player is hidden permanently (endGame()
//     handles the scene transition).
//
//  IMPLEMENTATION NOTES
//  - All fragments are SKCropNode (quadrants) or SKShapeNode (debris).
//  - Fragments are added to `scene` at `player.position` / `player.zPosition`
//    so they sit in the correct layer stack.
//  - Neither method modifies Player game-state — call player.hitMeteor() /
//    player.gameOver() separately as before.
//  - Both methods are no-ops when player.immune is true (caller should check).
//
//  REQUIRES @MainActor — all SpriteKit mutations on the main thread.
//

import SpriteKit

@MainActor
enum ShipBreakEffect {

    // MARK: - Non-fatal hit

    /// Scatter-and-snap animation for a surviving hit.
    /// Fragments fly out ~44 pt and return in ~0.30 s, then the player's
    /// alpha is restored so `blinkPlayer()` can take over.
    static func playHitEffect(for player: Player, in scene: SKScene) {
        let texture  = GameTextures.sharedInstance.textureWithName(name: SpriteName.Player)
        let shipSize = player.size
        let origin   = player.position

        let frags = makeQuadrantFragments(texture: texture, size: shipSize)
        for f in frags {
            f.position  = origin
            f.zPosition = player.zPosition + 2
            scene.addChild(f)
        }

        // Conceal the player sprite while the fragments stand in.
        player.alpha = 0

        // Outward scatter directions (one per quadrant corner).
        let dirs: [CGVector] = [
            CGVector(dx: -46, dy:  46),   // top-left
            CGVector(dx:  46, dy:  46),   // top-right
            CGVector(dx: -46, dy: -46),   // bottom-left
            CGVector(dx:  46, dy: -46),   // bottom-right
        ]

        for (i, frag) in frags.enumerated() {
            let d = dirs[i]
            let burst  = SKAction.moveBy(x: d.dx, y: d.dy, duration: 0.11)
            burst.timingMode = .easeOut
            let twist  = SKAction.rotate(byAngle: (i % 2 == 0 ? 1 : -1) * 0.48, duration: 0.11)
            frag.run(.group([burst, twist]))
        }

        // After scatter settles, snap every fragment back.
        scene.run(.wait(forDuration: 0.12)) {
            for (i, frag) in frags.enumerated() {
                let d = dirs[i]
                let snapBack = SKAction.moveBy(x: -d.dx, y: -d.dy, duration: 0.17)
                snapBack.timingMode = .easeIn
                let unTwist  = SKAction.rotate(toAngle: 0, duration: 0.17)
                frag.run(.sequence([
                    .group([snapBack, unTwist]),
                    .removeFromParent()
                ]))
            }
            // Restore player just as the last fragment lands.
            player.run(.sequence([
                .wait(forDuration: 0.18),
                .fadeIn(withDuration: 0.04)
            ]))
        }
    }

    // MARK: - Fatal destroy

    /// Permanent explosion for the final life.
    /// The player is hidden immediately; four texture quadrants and four
    /// coloured debris shards spin outward, shrink, and fade out.
    static func playDestroyEffect(for player: Player, in scene: SKScene) {
        let texture  = GameTextures.sharedInstance.textureWithName(name: SpriteName.Player)
        let shipSize = player.size
        let origin   = player.position

        // Immediately conceal and freeze the player.
        player.alpha = 0
        player.removeAllActions()
        player.children.compactMap { $0 as? SKEmitterNode }.forEach { $0.isPaused = true }

        // Bright flash at the ship's position.
        addDestroyFlash(at: origin, size: shipSize, to: scene)

        // ── Quadrant texture fragments ───────────────────────────────────────
        let shipFrags = makeQuadrantFragments(texture: texture, size: shipSize)
        for f in shipFrags {
            f.position  = origin
            f.zPosition = player.zPosition + 2
            scene.addChild(f)
        }

        // ── Small coloured debris shards ────────────────────────────────────
        let shardColors: [SKColor] = [
            Colors.colorFromRGB(rgbvalue: Colors.EngineYellow),
            Colors.colorFromRGB(rgbvalue: Colors.EngineGreen),
            Colors.colorFromRGB(rgbvalue: Colors.Magic),
            Colors.colorFromRGB(rgbvalue: Colors.EngineRed),
        ]
        let debris: [SKShapeNode] = shardColors.map { color in
            let side = CGFloat.random(in: 5...9)
            let shard = SKShapeNode(rectOf: CGSize(width: side, height: side),
                                    cornerRadius: 1)
            shard.fillColor   = color
            shard.strokeColor = .clear
            shard.position    = origin
            shard.zPosition   = player.zPosition + 2
            scene.addChild(shard)
            return shard
        }

        // ── Explode everything outward ───────────────────────────────────────
        let allPieces: [SKNode] = shipFrags + debris
        let pieceCount = CGFloat(allPieces.count)

        for (i, piece) in allPieces.enumerated() {
            // Spread pieces in an even arc with a little random wobble.
            let baseAngle  = (CGFloat(i) / pieceCount) * .pi * 2
            let jitter     = CGFloat.random(in: -0.35...0.35)
            let angle      = baseAngle + jitter
            let distance   = CGFloat.random(in: 85...200)

            let dur = TimeInterval.random(in: 0.50...0.88)

            let move = SKAction.moveBy(x: cos(angle) * distance,
                                       y: sin(angle) * distance,
                                       duration: dur)
            move.timingMode = .easeOut

            let spinDir: CGFloat = (i % 2 == 0) ? 1 : -1
            let turns   = CGFloat.random(in: 1.3...2.6)
            let spin    = SKAction.rotate(byAngle: spinDir * turns * .pi * 2, duration: dur)

            let shrink  = SKAction.scale(to: CGFloat.random(in: 0.04...0.14), duration: dur)
            shrink.timingMode = .easeIn

            let fade    = SKAction.fadeOut(withDuration: dur * 0.80)

            piece.run(.sequence([
                .group([move, spin, shrink, fade]),
                .removeFromParent()
            ]))
        }
    }

    // MARK: - Private helpers

    /// Four SKCropNodes each revealing one quadrant of `texture` at `size`.
    private static func makeQuadrantFragments(texture: SKTexture,
                                              size: CGSize) -> [SKCropNode] {
        let hW = size.width  / 2
        let hH = size.height / 2
        let maskSz = CGSize(width: hW, height: hH)

        let defs: [CGPoint] = [
            CGPoint(x: -hW / 2,  y:  hH / 2),  // top-left
            CGPoint(x:  hW / 2,  y:  hH / 2),  // top-right
            CGPoint(x: -hW / 2,  y: -hH / 2),  // bottom-left
            CGPoint(x:  hW / 2,  y: -hH / 2),  // bottom-right
        ]

        return defs.map { maskCenter in
            let crop   = SKCropNode()
            let sprite = SKSpriteNode(texture: texture, color: .white, size: size)
            sprite.colorBlendFactor = 0
            crop.addChild(sprite)

            let mask   = SKSpriteNode(color: .white, size: maskSz)
            mask.position  = maskCenter
            crop.maskNode  = mask
            return crop
        }
    }

    /// Brief full-white flash at the ship's last position.
    private static func addDestroyFlash(at position: CGPoint,
                                        size: CGSize,
                                        to scene: SKScene) {
        let flash = SKSpriteNode(
            color: Colors.colorFromRGB(rgbvalue: Colors.ScreenFlash),
            size:  CGSize(width: size.width * 2.8, height: size.height * 2.8))
        flash.position  = position
        flash.zPosition = GameLayer.Interface
        flash.alpha     = 0
        scene.addChild(flash)

        flash.run(.sequence([
            .fadeAlpha(to: 1.0, duration: 0.04),
            .fadeAlpha(to: 0.0, duration: 0.28),
            .removeFromParent()
        ]))
    }
}
