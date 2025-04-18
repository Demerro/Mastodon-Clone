//
//  UIViewController+Transition.swift
//  MastodonCoreUI
//
//  Created by Nikita Prokhorchuk on 1.02.25.
//

import UIKit

extension UIViewController {
    
    public func switchStateViewController(to viewController: UIViewController) {
        let currentViewController = children.first
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.view.frame = view.frame
        viewController.didMove(toParent: self)
        if let currentViewController {
            currentViewController.willMove(toParent: nil)
            transition(from: currentViewController, to: viewController, duration: CATransaction.animationDuration(), options: .transitionCrossDissolve, animations: nil)
            currentViewController.view.removeFromSuperview()
            currentViewController.removeFromParent()
        }
    }
}
