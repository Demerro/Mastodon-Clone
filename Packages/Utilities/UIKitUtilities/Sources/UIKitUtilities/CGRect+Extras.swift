//
//  CGRect+Extras.swift
//  UIKitUtilities
//
//  Created by Nikita Prokhorchuk on 22.01.25.
//

import CoreGraphics


extension CGRect {

    public var center: CGPoint {
        get {
            return CGPoint(x: self.midX, y: self.midY)
        }
        set {
            self.origin.x = newValue.x - self.size.width / 2.0
            self.origin.y = newValue.y - self.size.height / 2.0
        }
    }
}
