//
//  Math.swift
//  SpaceRunner
//
//  © 2026 Todd Dube. All rights reserved.
//
//  PURPOSE
//  Lightweight math helpers used throughout the game. Uses GameplayKit's
//  seeded random sources for reproducible, high-quality randomness — a
//  best practice for iOS 26 / Swift 6 game development.
//
//  CONTENTS
//  - Smooth(_:_:filter:)           — linear interpolation (lerp) between two CGFloat values
//  - RandomIntegerBetween(min:max:) — uniform random Int in [min, max] via GameplayKit
//  - RandomFloatRange(min:max:)    — uniform random CGFloat in [min, max] via GameplayKit
//  - DegressToRadians(degrees:)   — convert degrees → radians
//  - AngleToRotate(…)             — heading angle between two CGPoints
//

import Foundation
import SpriteKit
import GameplayKit

// MARK: - Shared random source (arc4random-seeded, cryptographic quality)
nonisolated(unsafe) let sharedRandom = GKARC4RandomSource()

// MARK: - Interpolation
func Smooth(startPoint: CGFloat, endPoint: CGFloat, filter: CGFloat) -> CGFloat {
    return (startPoint * (1 - filter)) + endPoint * filter
}

// MARK: - Integer random [min, max] inclusive
func RandomIntegerBetween(min: Int, max: Int) -> Int {
    guard max >= min else { return min }
    let distribution = GKRandomDistribution(randomSource: sharedRandom, lowestValue: min, highestValue: max)
    return distribution.nextInt()
}

// MARK: - Float random [min, max]
func RandomFloatRange(min: CGFloat, max: CGFloat) -> CGFloat {
    guard max > min else { return min }
    let t = CGFloat(sharedRandom.nextUniform())
    return min + t * (max - min)
}

// MARK: - Angle conversions
func DegressToRadians(degrees: CGFloat) -> CGFloat {
    return degrees * CGFloat(Double.pi) / 180.0
}

func AngleToRotate(firstPostion firstPositon: CGPoint, secondPositon: CGPoint) -> CGFloat {
    let deltaX = Float(firstPositon.x - secondPositon.x)
    let deltaY = Float(firstPositon.y - secondPositon.y)
    let angle = atan2f(deltaX, deltaY)
    return CGFloat(angle) - DegressToRadians(degrees: 90.0)
}
