//
//  SKAction+Extensions.swift
//  SpaceRunner
//
//  Created by Todd Dube : 2025
//  Purpose: SKAction extensions for enhanced animation and timing functionality.
//

import SpriteKit

public extension SKAction {
  /**
   * Performs an action after the specified delay.
   */
     func afterDelay(_ delay: TimeInterval, performAction action: SKAction) -> SKAction {
        return SKAction.sequence([SKAction.wait(forDuration: delay), action])
  }

  /**
   * Performs a block after the specified delay.
   */
  /*
     * Abiguous refefence for this -
     func afterDelay(delay: TimeInterval, runBlock block: @escaping ()->()) -> SKAction {
        return SKAction.afterDelay(delay, performAction: SKAction.run(block))
 
  }
*/
    
  /**
   * Removes the node from its parent after the specified delay.
   */
    // 12/07/2019 - commented out until I can resolve this issue 
    // func removeFromParentAfterDelay(delay: TimeInterval) -> SKAction {
    //    return SKAction.afterDelay(delay, SKAction.removeFromParent())
  }

  /**
   * Creates an action to perform a parabolic jump.
   */
func jumpToHeight(_ height: CGFloat, duration: TimeInterval, originalPosition: CGPoint) -> SKAction {
    return SKAction.customAction(withDuration: duration) {(node, elapsedTime) in
      let fraction = elapsedTime / CGFloat(duration)
      let yOffset = height * 4 * fraction * (1 - fraction)
      node.position = CGPoint(x: originalPosition.x, y: originalPosition.y + yOffset)
    }
  }

