//
//  UIBar+Extras.swift
//  MastodonCoreUI
//
//  Created by Nikita Prokhorchuk on 25.05.25.
//

import UIKit
import FoundationUtilities

extension UINavigationBar {
    
    public var backgroundView: UIView? {
        value(forKey: backgroundViewKey) as? UIView
    }
    
    public var visualEffectView: UIVisualEffectView? {
        for subview in backgroundView?.subviews ?? [] where subview is UIVisualEffectView {
            return subview as? UIVisualEffectView
        }
        return nil
    }
}

extension UITabBar {
    
    public var backgroundView: UIView? {
        value(forKey: backgroundViewKey) as? UIView
    }
    
    public var visualEffectView: UIVisualEffectView? {
        for subview in backgroundView?.subviews ?? [] where subview is UIVisualEffectView {
            return subview as? UIVisualEffectView
        }
        return nil
    }
}

fileprivate let backgroundViewKey = valueKey(from: "X2JhY2tncm91bmRWaWV3")
