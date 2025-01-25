//
//  ImageDetailsTransition.swift
//  MastodonProfileUI
//
//  Created by Nikita Prokhorchuk on 17.01.25.
//

import UIKit
import UIKitUtilities

@MainActor
final class ImageDetailsTransition: NSObject {
    
    private let imageView: UIImageView = {
        $0.contentMode = .scaleAspectFit
        $0.clipsToBounds = true
        $0.layer.cornerCurve = .continuous
        return $0
    }(UIImageView(frame: .zero))
    
    let operation: UINavigationController.Operation
    
    init(operation: UINavigationController.Operation) {
        self.operation = operation
    }
}

extension ImageDetailsTransition: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        0.38
    }
    
    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from),
              let toView = transitionContext.view(forKey: .to),
              let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to),
              let fromItemDelegate = fromViewController as? ImageDetailsTransitioningDelegate,
              let toItemDelegate = toViewController as? ImageDetailsTransitioningDelegate
        else { preconditionFailure() }
        
        fromItemDelegate.willTransitionItemWith(context: transitionContext, coordinator: fromViewController.transitionCoordinator)
        toItemDelegate.willTransitionItemWith(context: transitionContext, coordinator: toViewController.transitionCoordinator)
        
        let fromItem = fromItemDelegate.item(forTransitionWith: transitionContext)
        imageView.image = fromItem.image
        imageView.layer.cornerRadius = fromItem.cornerRadius
        imageView.layer.borderWidth = fromItem.borderWidth
        imageView.layer.borderColor = fromItem.borderColor
        
        let containerView = transitionContext.containerView
        imageView.frame = fromItemDelegate.itemFrame(in: containerView, forTransitionWith: transitionContext)
        containerView.addSubview(fromView)
        containerView.addSubview(toView)
        containerView.addSubview(imageView)
        containerView.layoutIfNeeded()
        
        toView.alpha = 0.0
        
        let toItem = toItemDelegate.item(forTransitionWith: transitionContext)
        
        let animator = UIViewPropertyAnimator(duration: transitionDuration(using: transitionContext), dampingRatio: 0.825)
        animator.addAnimations { [imageView] in
            toView.alpha = 1.0
            imageView.frame = toItemDelegate.itemFrame(in: containerView, forTransitionWith: transitionContext)
            imageView.layer.cornerRadius = toItem.cornerRadius
            imageView.layer.borderWidth = toItem.borderWidth
            imageView.layer.borderColor = toItem.borderColor
        }
        animator.addCompletion { [unowned imageView] _ in
            imageView.removeFromSuperview()
            imageView.image = nil
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            fromItemDelegate.didTransitionItemWith(context: transitionContext)
            toItemDelegate.didTransitionItemWith(context: transitionContext)
        }
        animator.startAnimation()
        
        switch operation {
        case .push:
            fromViewController.tabBarController?.setTabBar(hidden: true, alongside: animator)
        case .pop:
            toViewController.tabBarController?.setTabBar(hidden: false, alongside: animator)
        default:
            break
        }
    }
}
