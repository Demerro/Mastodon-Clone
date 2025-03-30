//
//  UITabBarController+Extras.swift
//  MastodonCoreUI
//
//  Created by Nikita Prokhorchuk on 23.01.25.
//

import UIKit

extension UITabBarController {
    
    public func setTabBar(
        hidden: Bool,
        animated: Bool = true,
        alongside animator: UIViewPropertyAnimator? = nil
    ) {
        guard tabBar.isHidden != hidden else { return }
        
        if tabBar.isHidden, !hidden {
            tabBar.isHidden = false
        }
        
        if let animator {
            animator.addAnimations { [tabBar] in
                tabBar.alpha = hidden ? 0.0 : 1.0
            }
            animator.addCompletion { [weak tabBar] in
                if let tabBar, $0 == .end {
                    tabBar.isHidden = hidden
                }
            }
        } else {
            UIViewPropertyAnimator.runningPropertyAnimator(withDuration: CATransaction.animationDuration(), delay: 0.0) { [tabBar] in
                tabBar.alpha = hidden ? 0.0 : 1.0
            } completion: { [weak tabBar] in
                if let tabBar, $0 == .end {
                    tabBar.isHidden = hidden
                }
            }
        }
    }
}
