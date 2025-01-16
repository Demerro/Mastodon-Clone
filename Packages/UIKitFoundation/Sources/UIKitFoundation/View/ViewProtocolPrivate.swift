//
//  ViewProtocolPrivate.swift
//  UIKitFoundation
//
//  Created by Nikita Prokhorchuk on 14.01.25.
//

protocol ViewProtocolPrivate: ViewProtocol {
    
    var setupFlags: SetupFlags { get set }
}

extension ViewProtocolPrivate {
    
    func _layoutSubviews() {
        if _slowPath(!setupFlags.layoutSubviewsVisitedOnce) {
            setupFlags.layoutSubviewsVisitedOnce = true
            setupAfterLayoutSubviews()
        }
    }
}
