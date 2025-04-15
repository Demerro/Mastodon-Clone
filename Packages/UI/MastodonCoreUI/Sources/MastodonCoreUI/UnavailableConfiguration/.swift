//
//  ContainerViewController.swift
//  MastodonCoreUI
//
//  Created by Nikita Prokhorchuk on 13.01.25.
//

import UIKit
import UIKitFoundation

open class ContainerViewController: ViewController {
    
    public func transition(to viewController: ViewController) {
        let currentViewController = children.first { $0 is EmptyViewController || $0 is LoadingViewController }
        viewController.willMove(toParent: self)
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
        viewController.view.frame = view.frame
        if let currentViewController {
            transition(from: currentViewController, to: viewController, duration: CATransaction.animationDuration(), options: .transitionCrossDissolve, animations: nil)
        }
    }
}
