//
//  ShipBreakEffect.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Ship destruction and hit effects triggered by meteor collisions.
//
//  1. playHitEffect(for:in:)
//     Non-fatal — four quadrant fragments burst outward ~44 pt then snap
//     back in ~0.3 s. Player sprite is hidden during the animation, then
//     restored so normal blinking immunity can take over.
//
//  2. playDestroyEffect(for:in:)
//     Final-life kill — multi-layer explosion:
//       · White flash + expanding orange shockwave ring
//       · Four ship-texture quadrant fragments, fire-tinted, spin outward
//       · Seven metallic hull panels / struts / wing-tip shards
//       · Ten coloured neon debris squares with additive glow
//       · Fire-burst emitter (white → yellow → orange → red)
//       · Smoke-plume emitter (white → gray → black → clear, rises upward)
//
//  REQUIRES @MainActor — all SpriteKit mutations on the main thread.
//

import SpriteKit

@MainActor
enum ShipBreakEffect {

    // MARK: - Non-fatal hit

    /// Scatter-and-snap animation for a surviving hit.
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

        player.alpha = 0

        let dirs: [CGVector] = [
            CGVector(dx: -46, dy:  46),
            CGVector(dx:  46, dy:  46),
            CGVector(dx: -46, dy: -46),
            CGVector(dx:  46, dy: -46),
        ]

        for (i, frag) in frags.enumerated() {
            let d = dirs[i]
            let burst = SKAction.moveBy(x: d.dx, y: d.dy, duration: 0.11)
            burst.timingMode = .easeOut
            let twist = SKAction.rotate(byAngle: (i % 2 == 0 ? 1 : -1) * 0.48, duration: 0.11)
            frag.run(.group([burst, twist]))
        }

        scene.run(.wait(forDuration: 0.12)) {
            for (i, frag) in frags.enumerated() {
                let d = dirs[i]
                let snapBack = SKAction.moveBy(x: -d.dx, y: -d.dy, duration: 0.17)
                snapBack.timingMode = .easeIn
                let unTwist = SKAction.rotate(toAngle: 0, duration: 0.17)
                frag.run(.sequence([.group([snapBack, unTwist]), .removeFromParent()]))
            }
            player.run(.sequence([.wait(forDuration: 0.18), .fadeIn(withDuration: 0.04)]))
        }
    }

    // MARK: - Fatal destroy

    /// Full multi-layer explosion for the final life.
    static func playDestroyEffect(for player: Player, in scene: SKScene) {
        let texture  = GameTextures.sharedInstance.textureWithName(name: SpriteName.Player)
        let shipSize = player.size
        let origin   = player.position
        let zBase    = player.zPosition

        // 1. Freeze the player immediately.
        player.alpha = 0
        player.removeAllActions()
        player.children.compactMap { $0 as? SKEmitterNode }.forEach { $0.isPaused = true }

        // 2. White flash at impact point.
        addDestroyFlash(at: origin, size: shipSize, to: scene)

        // 3. Expanding orange shockwave ring.
        addShockwave(at: origin, to: scene, zPos: zBase + 5)

        // 4. Fire burst from the explosion core.
        addFireBurst(at: origin, to: scene, zPos: zBase + 4)

        // 5. Four ship-texture quadrant pieces, fire-tinted.
        let shipFrags = makeQuadrantFragments(texture: texture, size: shipSize)
        for f in shipFrags {
            f.position  = origin
            f.zPosition = zBase + 2
            f.run(SKAction.colorize(
                with: UIColor(red: 1.0, green: 0.42, blue: 0.0, alpha: 1.0),
                colorBlendFactor: 0.55, duration: 0.0))
            scene.addChild(f)
        }

        // 6. Metallic hull panel / strut / wing-tip fragments.
        let hullFrags = makeHullFragments(at: origin, zPos: zBase + 2)
        for f in hullFrags { scene.addChild(f) }

        // 7. Coloured neon debris shards.
        let neonShards = makeNeonDebris(at: origin, zPos: zBase + 2)
        for f in neonShards { scene.addChild(f) }

        // 8. Explode all solid pieces outward.
        explodePieces(shipFrags + hullFrags + neonShards)

        // 9. Smoke plume starts slightly after fire so fire shows first.
        scene.run(.wait(forDuration: 0.10)) {
            addSmokePlume(at: origin, to: scene, zPos: zBase + 1)
        }
    }

    // MARK: - Particle emitters

    private static func addFireBurst(at position: CGPoint, to scene: SKScene, zPos: CGFloat) {
        let fire = SKEmitterNode()
        fire.position    = position
        fire.zPosition   = zPos
        fire.particleBlendMode = .add
        fire.particleTexture = GameTextures.sharedInstance.textureWithName(name: SpriteName.Magic)
        fire.particleBirthRate    = 260
        fire.numParticlesToEmit   = 130
        fire.particleLifetime     = 0.65
        fire.particleLifetimeRange = 0.28
        fire.emissionAngle        = .pi / 2       // upward
        fire.emissionAngleRange   = .pi * 1.35    // wide cone so fire engulfs the area
        fire.particleSpeed        = 145
        fire.particleSpeedRange   = 95
        fire.particleScale        = 1.1
        fire.particleScaleRange   = 0.55
        fire.particleScaleSpeed   = -1.1
        fire.particleAlpha        = 1.0
        fire.particleAlphaSpeed   = -1.9
        fire.xAcceleration        = 0
        fire.yAcceleration        = 55   // fire rises
        fire.particleColorBlendFactor = 1.0
        fire.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                UIColor.white,
                UIColor(red: 1.0, green: 0.96, blue: 0.40, alpha: 1.0),  // bright yellow
                UIColor(red: 1.0, green: 0.45, blue: 0.00, alpha: 1.0),  // orange
                UIColor(red: 0.85, green: 0.10, blue: 0.00, alpha: 0.65), // deep red
                UIColor.clear,
            ] as [Any],
            times: [0.0, 0.12, 0.38, 0.70, 1.0] as [NSNumber])
        scene.addChild(fire)
        fire.run(.sequence([
            .wait(forDuration: Double(fire.particleLifetime) + 0.4),
            .removeFromParent()
        ]))
    }

    private static func addSmokePlume(at position: CGPoint, to scene: SKScene, zPos: CGFloat) {
        let smoke = SKEmitterNode()
        smoke.position    = position
        smoke.zPosition   = zPos
        smoke.particleTexture = GameTextures.sharedInstance.textureWithName(name: SpriteName.Magic)
        smoke.particleBirthRate    = 55
        smoke.numParticlesToEmit   = 85
        smoke.particleLifetime     = 2.2
        smoke.particleLifetimeRange = 0.85
        smoke.emissionAngle        = .pi / 2   // upward
        smoke.emissionAngleRange   = .pi * 0.5 // narrower — smoke columns up
        smoke.particleSpeed        = 42
        smoke.particleSpeedRange   = 22
        smoke.particleScale        = 0.75
        smoke.particleScaleRange   = 0.35
        smoke.particleScaleSpeed   = 0.55   // billows outward as it rises
        smoke.particleAlpha        = 0.50
        smoke.particleAlphaSpeed   = -0.22
        smoke.xAcceleration        = 10     // slight lateral drift
        smoke.yAcceleration        = 58     // rises steadily
        smoke.particleColorBlendFactor = 1.0
        smoke.particleColorSequence = SKKeyframeSequence(
            keyframeValues: [
                UIColor(white: 0.90, alpha: 0.85),
                UIColor(white: 0.52, alpha: 0.62),
                UIColor(white: 0.22, alpha: 0.35),
                UIColor(white: 0.00, alpha: 0.00),
            ] as [Any],
            times: [0.0, 0.30, 0.65, 1.0] as [NSNumber])
        scene.addChild(smoke)
        smoke.run(.sequence([
            .wait(forDuration: Double(smoke.particleLifetime) + 0.5),
            .removeFromParent()
        ]))
    }

    // MARK: - Shockwave ring

    private static func addShockwave(at position: CGPoint, to scene: SKScene, zPos: CGFloat) {
        let ring = SKShapeNode(circleOfRadius: 2)
        ring.position    = position
        ring.strokeColor = UIColor(red: 1.0, green: 0.55, blue: 0.10, alpha: 0.95)
        ring.lineWidth   = 5
        ring.fillColor   = UIColor(red: 1.0, green: 0.85, blue: 0.30, alpha: 0.14)
        ring.blendMode   = .add
        ring.zPosition   = zPos
        scene.addChild(ring)

        ring.run(SKAction.sequence([
            SKAction.customAction(withDuration: 0.48) { node, elapsed in
                guard let s = node as? SKShapeNode else { return }
                let t = elapsed / 0.48
                let r = t * 140
                s.path  = UIBezierPath(ovalIn: CGRect(x: -r, y: -r,
                                                       width: r * 2, height: r * 2)).cgPath
                s.alpha     = 1.0 - t
                s.lineWidth = max(1.0, 5.0 * (1.0 - t))
            },
            .removeFromParent()
        ]))
    }

    // MARK: - Solid fragment builders

    private static func makeHullFragments(at origin: CGPoint, zPos: CGFloat) -> [SKShapeNode] {
        // Each tuple: (width, height, fill color) — varied shapes for visual diversity.
        let specs: [(CGFloat, CGFloat, UIColor)] = [
            (15, 5,  UIColor(white: 0.82, alpha: 1.0)),                          // fuselage panel
            (9,  9,  UIColor(white: 0.65, alpha: 1.0)),                          // hull chunk
            (20, 3,  UIColor(red: 0.90, green: 0.55, blue: 0.10, alpha: 1.0)),   // strut (hot)
            (6,  11, UIColor(white: 0.70, alpha: 1.0)),                          // side shard
            (13, 4,  UIColor(red: 0.92, green: 0.75, blue: 0.20, alpha: 1.0)),   // engine casing
            (5,  5,  UIColor(white: 0.55, alpha: 1.0)),                          // rivet block
            (17, 5,  UIColor(red: 0.72, green: 0.72, blue: 0.72, alpha: 1.0)),   // wing-tip strip
        ]
        return specs.map { (w, h, color) in
            let frag = SKShapeNode(rectOf: CGSize(width: w, height: h), cornerRadius: 1)
            frag.fillColor   = color
            frag.strokeColor = UIColor(white: 1.0, alpha: 0.45)
            frag.lineWidth   = 0.5
            frag.position    = origin
            frag.zPosition   = zPos
            frag.zRotation   = CGFloat.random(in: 0 ... .pi * 2)
            // Additive orange heat-glow on every hull piece.
            let glow = SKShapeNode(rectOf: CGSize(width: w * 2.2, height: h * 2.2), cornerRadius: 2)
            glow.fillColor   = UIColor(red: 1.0, green: 0.48, blue: 0.0, alpha: 0.22)
            glow.strokeColor = .clear
            glow.blendMode   = .add
            frag.addChild(glow)
            return frag
        }
    }

    private static func makeNeonDebris(at origin: CGPoint, zPos: CGFloat) -> [SKShapeNode] {
        let colors: [SKColor] = [
            Colors.colorFromRGB(rgbvalue: Colors.EngineYellow),
            Colors.colorFromRGB(rgbvalue: Colors.EngineGreen),
            Colors.colorFromRGB(rgbvalue: Colors.Magic),
            Colors.colorFromRGB(rgbvalue: Colors.EngineRed),
            Colors.colorFromRGB(rgbvalue: Colors.AccentCyan),
            Colors.colorFromRGB(rgbvalue: Colors.AccentMagenta),
            Colors.colorFromRGB(rgbvalue: Colors.AccentYellow),
            Colors.colorFromRGB(rgbvalue: Colors.DangerRed),
            Colors.colorFromRGB(rgbvalue: Colors.AccentCyan),
            Colors.colorFromRGB(rgbvalue: Colors.EngineGreen),
        ]
        return colors.map { color in
            let side = CGFloat.random(in: 4...11)
            let shard = SKShapeNode(rectOf: CGSize(width: side, height: side), cornerRadius: 2)
            shard.fillColor   = color
            shard.strokeColor = .clear
            shard.position    = origin
            shard.zPosition   = zPos
            let glow = SKShapeNode(rectOf: CGSize(width: side * 2.4, height: side * 2.4), cornerRadius: side)
            glow.fillColor   = color.withAlphaComponent(0.38)
            glow.strokeColor = .clear
            glow.blendMode   = .add
            shard.addChild(glow)
            return shard
        }
    }

    /// Four SKCropNodes each revealing one quadrant of `texture` at `size`.
    private static func makeQuadrantFragments(texture: SKTexture, size: CGSize) -> [SKCropNode] {
        let hW = size.width  / 2
        let hH = size.height / 2
        let maskSz = CGSize(width: hW, height: hH)
        let defs: [CGPoint] = [
            CGPoint(x: -hW / 2,  y:  hH / 2),
            CGPoint(x:  hW / 2,  y:  hH / 2),
            CGPoint(x: -hW / 2,  y: -hH / 2),
            CGPoint(x:  hW / 2,  y: -hH / 2),
        ]
        return defs.map { maskCenter in
            let crop   = SKCropNode()
            let sprite = SKSpriteNode(texture: texture, color: .white, size: size)
            sprite.colorBlendFactor = 0
            crop.addChild(sprite)
            let mask  = SKSpriteNode(color: .white, size: maskSz)
            mask.position = maskCenter
            crop.maskNode = mask
            return crop
        }
    }

    // MARK: - Explosion dispatcher

    private static func explodePieces(_ pieces: [SKNode]) {
        let total = CGFloat(pieces.count)
        for (i, piece) in pieces.enumerated() {
            let baseAngle = (CGFloat(i) / total) * .pi * 2
            let jitter    = CGFloat.random(in: -0.40...0.40)
            let angle     = baseAngle + jitter
            let distance  = CGFloat.random(in: 95...230)
            let dur       = TimeInterval.random(in: 0.52...0.98)

            let move = SKAction.moveBy(x: cos(angle) * distance,
                                       y: sin(angle) * distance,
                                       duration: dur)
            move.timingMode = .easeOut

            let spinDir: CGFloat = (i % 2 == 0) ? 1 : -1
            let turns   = CGFloat.random(in: 1.5...3.2)
            let spin    = SKAction.rotate(byAngle: spinDir * turns * .pi * 2, duration: dur)

            let shrink  = SKAction.scale(to: CGFloat.random(in: 0.04...0.16), duration: dur)
            shrink.timingMode = .easeIn

            let fade = SKAction.fadeOut(withDuration: dur * 0.78)

            piece.run(.sequence([
                .group([move, spin, shrink, fade]),
                .removeFromParent()
            ]))
        }
    }

    // MARK: - White flash

    private static func addDestroyFlash(at position: CGPoint, size: CGSize, to scene: SKScene) {
        let flash = SKSpriteNode(
            color: Colors.colorFromRGB(rgbvalue: Colors.ScreenFlash),
            size: CGSize(width: size.width * 2.8, height: size.height * 2.8))
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
