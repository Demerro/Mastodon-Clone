//
//  CGPoint+Extras.swift
//  UIKitUtilities
//
//  Created by Nikita Prokhorchuk on 22.01.25.
//

import CoreGraphics

extension CGPoint {

    // MARK: - Operators

    public static func +(lhs: CGPoint, rhs: CGVector) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.dx, y: lhs.y + rhs.dy)
    }

    public static func -(lhs: CGPoint, rhs: CGVector) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.dx, y: lhs.y - rhs.dy)
    }

    public static func +=(lhs: inout CGPoint, rhs: CGVector) {
        lhs = lhs + rhs
    }

    public static func -=(lhs: inout CGPoint, rhs: CGVector) {
        lhs = lhs - rhs
    }

    public static func -(lhs: CGPoint, rhs: CGPoint) -> CGVector {
        return CGVector(dx: lhs.x - rhs.x, dy: lhs.y - rhs.y)
    }


    // MARK: - Miscellaneous

    public func distance(to other: CGPoint) -> CGFloat {
        return hypot(other.x - self.x, other.y - self.y)
    }
}
