//
//  ShipAssemblyAnimation.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Plays a "parts assembling" intro animation on the menu scene.
//  The Player texture is split into four quadrant crop-nodes that scatter off
//  screen, then fly in from the corners and snap together with a cyan flash,
//  revealing the full assembled ship which then idles with a gentle float
//  and engine-glow effect.
//
//  USAGE
//      let assembly = ShipAssemblyAnimation()
//      assembly.runAssembly(in: self, at: assemblyPoint) {
//          // called when ship finishes assembling
//      }
//
//  RESPONSIBILITIES
//  - buildQuadrantParts()      — four SKCropNodes, each showing one quadrant
//                                of the Player texture, positioned off-screen
//  - animatePartsIn(…)         — staggered spring-like fly-in from each corner
//  - flashAndReveal(…)         — cyan flash, dissolve parts, reveal clean sprite
//  - startIdleEffects()        — floating loop + pulsing engine-glow dots
//  - dismiss(completion:)      — fly assembled ship off top, then remove self
//
//  REQUIRES @MainActor — all SpriteKit node mutations on the main thread
//

import SpriteKit

@MainActor
class ShipAssemblyAnimation: SKNode {

    // MARK: - Private types

    /// Defines one quadrant fragment: which pixel region to show and where it starts.
    private struct QuadrantDef {
        /// Center of the white mask rectangle in the crop node's local space
        /// (i.e. relative to the ship sprite which is anchored at (0, 0)).
        let maskCenter: CGPoint
        /// Size of the mask rectangle.
        let maskSize: CGSize
        /// Starting position relative to `self` (off-screen corner).
        let scatter: CGPoint
        /// Small initial rotation for each part — straightens as it arrives.
        let startRotation: CGFloat
    }

    // MARK: - Private state

    private var shipTexture: SKTexture!
    private var shipSize: CGSize = .zero
    private var partNodes: [SKCropNode] = []
    private var assembledShip: SKSpriteNode?

    /// Scale applied to the raw texture so the ship reads large on the menu.
    private let displayScale: CGFloat = 1.8

    // MARK: - Init

    override init() { super.init() }
    required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }

    // MARK: - Public API

    /// Adds `self` to `scene`, builds the scattered parts, and runs the
    /// full assembly sequence.  `completion` fires after the ship is revealed
    /// but before the idle-float loop starts.
    func runAssembly(in scene: SKScene,
                     at position: CGPoint,
                     completion: (() -> Void)? = nil) {
        self.position = position
        scene.addChild(self)

        shipTexture = GameTextures.sharedInstance.textureWithName(name: SpriteName.Player)
        let raw = shipTexture.size()
        shipSize = CGSize(width: raw.width * displayScale,
                          height: raw.height * displayScale)

        buildQuadrantParts()
        animatePartsIn {
            self.flashAndReveal(completion: completion)
        }
    }

    /// Flies the assembled ship off the top of the screen, then removes `self`.
    func dismiss(completion: (() -> Void)? = nil) {
        removeAction(forKey: "float")
        let up   = SKAction.moveBy(x: 0, y: 110, duration: 0.42)
        up.timingMode = .easeIn
        let fade = SKAction.fadeOut(withDuration: 0.36)
        let group = SKAction.group([up, fade])
        run(SKAction.sequence([group, .removeFromParent()])) {
            completion?()
        }
    }

    // MARK: - Build parts

    private func buildQuadrantParts() {
        let hW = shipSize.width  / 2
        let hH = shipSize.height / 2

        // Four quadrants — each reveals one corner of the ship texture.
        // scatter: where the part starts (relative to self, i.e., off-screen).
        let quads: [QuadrantDef] = [
            // Top-left  → comes from upper-left
            QuadrantDef(maskCenter:    CGPoint(x: -hW / 2,  y:  hH / 2),
                        maskSize:      CGSize(width: hW, height: hH),
                        scatter:       CGPoint(x: -310, y:  520),
                        startRotation:  0.35),
            // Top-right → comes from upper-right
            QuadrantDef(maskCenter:    CGPoint(x:  hW / 2,  y:  hH / 2),
                        maskSize:      CGSize(width: hW, height: hH),
                        scatter:       CGPoint(x:  310, y:  520),
                        startRotation: -0.35),
            // Bottom-left  → comes from lower-left
            QuadrantDef(maskCenter:    CGPoint(x: -hW / 2,  y: -hH / 2),
                        maskSize:      CGSize(width: hW, height: hH),
                        scatter:       CGPoint(x: -310, y: -520),
                        startRotation: -0.35),
            // Bottom-right → comes from lower-right
            QuadrantDef(maskCenter:    CGPoint(x:  hW / 2,  y: -hH / 2),
                        maskSize:      CGSize(width: hW, height: hH),
                        scatter:       CGPoint(x:  310, y: -520),
                        startRotation:  0.35),
        ]

        for quad in quads {
            let crop = SKCropNode()

            // Full-size ship sprite centered at origin inside the crop node.
            let sprite = SKSpriteNode(texture: shipTexture,
                                      color: .white,
                                      size: shipSize)
            sprite.colorBlendFactor = 0
            crop.addChild(sprite)

            // Opaque white rectangle — only the covered region is rendered.
            let mask = SKSpriteNode(color: .white, size: quad.maskSize)
            mask.position = quad.maskCenter
            crop.maskNode = mask

            // Position off-screen with a slight initial twist.
            crop.position = quad.scatter
            crop.zRotation = quad.startRotation
            crop.alpha = 0

            addChild(crop)
            partNodes.append(crop)
        }
    }

    // MARK: - Part animation

    private func animatePartsIn(completion: @escaping () -> Void) {
        let flyDuration: TimeInterval = 0.58
        var maxTime: TimeInterval = 0

        for (index, part) in partNodes.enumerated() {
            let stagger = Double(index) * 0.13

            // Fade in as part starts moving.
            let fadeIn = SKAction.fadeIn(withDuration: 0.28)

            // Fly to assembly center with a deceleration curve.
            let fly = SKAction.move(to: .zero, duration: flyDuration)
            fly.timingMode = .easeOut

            // Straighten the initial twist as it arrives.
            let straighten = SKAction.rotate(toAngle: 0, duration: flyDuration)
            straighten.timingMode = .easeOut

            // Tiny bounce on landing to sell the snap-together feel.
            let bounceIn  = SKAction.scale(to: 1.06, duration: 0.07)
            let bounceOut = SKAction.scale(to: 1.00, duration: 0.07)
            let bounce    = SKAction.sequence([bounceIn, bounceOut])

            let flightGroup = SKAction.group([fadeIn, fly, straighten])
            let seq = SKAction.sequence([
                .wait(forDuration: stagger),
                flightGroup,
                bounce
            ])
            part.run(seq)

            maxTime = max(maxTime, stagger + flyDuration + 0.14)
        }

        // Small extra wait so all bounces finish before the flash fires.
        run(.wait(forDuration: maxTime + 0.08)) { completion() }
    }

    // MARK: - Flash and reveal

    private func flashAndReveal(completion: (() -> Void)?) {
        // 1. Two rapid full-screen flashes — added to the parent scene so they
        //    cover the entire display regardless of this node's position.
        if let scene = self.scene {
            for (delay, peakAlpha) in [(0.0, CGFloat(0.80)), (0.17, CGFloat(0.50))] {
                let flash = SKSpriteNode(
                    color: Colors.colorFromRGB(rgbvalue: Colors.Magic),
                    size: kViewSize)
                flash.position  = CGPoint(x: kViewSize.width / 2, y: kViewSize.height / 2)
                flash.blendMode = .add
                flash.alpha     = 0
                flash.zPosition = 50
                scene.addChild(flash)

                flash.run(SKAction.sequence([
                    .wait(forDuration: delay),
                    .fadeAlpha(to: peakAlpha, duration: 0.04),
                    .fadeAlpha(to: 0.00,      duration: 0.11),
                    .removeFromParent()
                ]))
            }
        }

        // 2. Dissolve the crop-node fragments behind the flash.
        for part in partNodes {
            part.run(SKAction.sequence([
                .wait(forDuration: 0.04),
                .fadeOut(withDuration: 0.14),
                .removeFromParent()
            ]))
        }
        partNodes.removeAll()

        // 3. Reveal the clean assembled ship sprite.
        let ship = SKSpriteNode(texture: shipTexture, color: .white, size: shipSize)
        ship.colorBlendFactor = 0
        ship.alpha = 0
        ship.zPosition = 5
        assembledShip = ship
        addChild(ship)

        ship.run(SKAction.sequence([
            .wait(forDuration: 0.06),
            .fadeIn(withDuration: 0.20)
        ])) {
            self.startIdleEffects()
            completion?()
        }
    }

    // MARK: - Idle effects

    private func startIdleEffects() {
        // Gentle vertical float loop.
        let float = SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 0, y: 7, duration: 1.7),
            SKAction.moveBy(x: 0, y: -7, duration: 1.7)
        ]))
        run(float, withKey: "float")

        // Pulsing engine-glow dots below the ship body.
        guard let ship = assembledShip else { return }
        let engineY: CGFloat = -shipSize.height * 0.44

        let glowSpecs: [(color: SKColor, xOff: CGFloat, radius: CGFloat)] = [
            (Colors.colorFromRGB(rgbvalue: Colors.EngineGreen),  0, 5.0),
            (Colors.colorFromRGB(rgbvalue: Colors.EngineYellow), 0, 3.5),
            (.cyan,                                               0, 2.5),
        ]

        for (idx, spec) in glowSpecs.enumerated() {
            let dot = SKShapeNode(circleOfRadius: spec.radius)
            dot.fillColor   = spec.color
            dot.strokeColor = .clear
            dot.position    = CGPoint(x: spec.xOff, y: engineY - CGFloat(idx) * 4)
            dot.alpha       = 0.9
            ship.addChild(dot)

            let half = 0.52 + Double(idx) * 0.11
            let pulse = SKAction.repeatForever(SKAction.sequence([
                .fadeAlpha(to: 0.20, duration: half),
                .fadeAlpha(to: 1.00, duration: half)
            ]))
            dot.run(pulse)
        }
    }
}
