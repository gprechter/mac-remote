//
//  UICustomGestureRecognizer.swift
//  MacmoteRemote
//
//  Created by Griffin Prechter on 4/17/18.
//  Copyright © 2018 Griffin Prechter. All rights reserved.
//

import Foundation
import UIKit
import UIKit.UIGestureRecognizerSubclass

class UICustomGestureRecognizer : UIGestureRecognizer {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        print("BEGAN")
        if let touch = touches.first {
            if #available(iOS 9.0, *) {
                    if touch.force >= touch.maximumPossibleForce {
                    } else if touch.force >= 4{
                        /*remoteService.send(code: "d0")
                         heavyImpact.impactOccurred()
                         isDragging = true
                         return*/
                        print("moving")
                    }
            }
        }
        state = .began
    }
}
