//
//  Math.swift
//  SpaceRunner
//
//  Created by Todd Dube on 3/20/16.
//  Copyright © 2020 Todd Dube. All rights reserved.
//

import Foundation
import SpriteKit

func Smooth(startPoint:CGFloat, endPoint: CGFloat, filter: CGFloat)->CGFloat {
    return (startPoint * (1 - filter)) + endPoint * filter
}

func RandomIntegerBetween(min:Int, max: Int) -> Int {
    return Int(UInt32(min) + arc4random_uniform(UInt32(max - min + 1)))
}

//func RandomFloatRange(min:CGFloat, max:CGFloat) -> CGFloat {
//    return CGFloat(Float(arc4random()) / 0xFFFFFF) * (max - min) + min
//}

// New random float May 2020
// Article: https://stackoverflow.com/questions/25050309/swift-random-float-between-0-and-1/33078096
func RandomFloatRange(min:CGFloat, max:CGFloat) -> CGFloat {
    // return CGFloat(arc4random() / 0xFFFFFFFF) * (max - min) + min
    return CGFloat.random() * (max - min) + min
 }

func DegressToRadians(degrees: CGFloat) -> CGFloat {
    // return degrees * CGFloat(M_PI) / 180.0  // Deprecated Swift 4 09.27.17
    return degrees * CGFloat(Double.pi) / 180.0
}

func AngleToRotate(firstPostion firstPositon: CGPoint, secondPositon: CGPoint) -> CGFloat {
    let deltaX = Float(firstPositon.x - secondPositon.x)
    let deltaY = Float(firstPositon.y - secondPositon.y)
    
    let angle = atan2f(deltaX, deltaY)
    
    return CGFloat(angle) - DegressToRadians(degrees: 90.0)
    
}
