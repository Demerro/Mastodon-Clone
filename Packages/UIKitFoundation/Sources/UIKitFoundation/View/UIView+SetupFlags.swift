//
//  UIView+SetupFlags.swift
//  UIKitFoundation
//
//  Created by Nikita Prokhorchuk on 23.11.24.
//

import UIKit

extension UIView {
    
    struct SetupFlags {

        var updateConstraintsVisitedOnce = false
        
        var layoutSubviewsVisitedOnce = false
    }
}
