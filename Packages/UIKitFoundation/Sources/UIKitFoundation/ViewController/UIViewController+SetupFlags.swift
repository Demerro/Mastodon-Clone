//
//  ViewController+SetupFlags.swift
//  UIKitFoundation
//
//  Created by Nikita Prokhorchuk on 23.11.24.
//

import UIKit

extension UIViewController {
    
    struct SetupFlags {
        
        var updateViewConstraintsVisitedOnce = false
        
        var viewDidLayoutSubviewsVisitedOnce = false
    }
}
