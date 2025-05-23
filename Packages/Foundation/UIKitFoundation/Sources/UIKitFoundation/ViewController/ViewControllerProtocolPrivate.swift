//
//  ViewControllerProtocolPrivate.swift
//  UIKitFoundation
//
//  Created by Nikita Prokhorchuk on 6.05.25.
//

import UIKit

internal protocol ViewControllerProtocolPrivate: ViewControllerProtocol {
    
    var setupFlags: SetupFlags { get set }
}

extension ViewControllerProtocolPrivate {
    
    func _viewDidLayoutSubviews() {
        if _slowPath(!setupFlags.viewDidLayoutSubviewsVisitedOnce) {
            setupFlags.viewDidLayoutSubviewsVisitedOnce = false
            setupAfterViewDidLayoutSubviews()
        }
    }
}
