//
//  UISpringTimingParameters+Extras.swift
//  UIKitUtilities
//
//  Created by Nikita Prokhorchuk on 22.12.24.
//

import UIKit

extension UISpringTimingParameters {
    
    public convenience init(dampingRatio: Double = 0.825, frequencyResponse: Double = 0.5, initialVelocity: CGVector = .zero) {
        let mass = 1.0
        let stiffness = pow(2.0 * .pi / frequencyResponse, 2.0) * mass
        let dampingCoefficient = 4.0 * .pi * dampingRatio * mass / frequencyResponse
        self.init(mass: mass, stiffness: stiffness, damping: dampingCoefficient, initialVelocity: initialVelocity)
    }
}
