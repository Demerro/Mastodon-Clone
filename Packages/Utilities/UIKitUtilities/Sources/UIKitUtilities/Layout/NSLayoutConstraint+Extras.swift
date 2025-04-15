//
//  NSLayoutConstraint+Extras.swift
//  UIKitUtilities
//
//  Created by Nikita Prokhorchuk on 4.12.24.
//

import UIKit

extension NSLayoutConstraint {
    
    public func identifier(_ newIdentifier: String?) -> NSLayoutConstraint {
        identifier = newIdentifier
        return self
    }
    
    public func priority(_ newPriority: UILayoutPriority) -> Self {
        priority = newPriority
        return self
    }
}
