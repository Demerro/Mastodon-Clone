//
//  ImageAnimationController.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 26.03.25.
//

import UIKit
import UIKitUtilities

public final class ImageAnimationController: NSObject {
    
    private let imageView: UIImageView = {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerCurve = .continuous
        return $0
    }(UIImageView(frame: .zero))
    
    public let fromItemDelegate: ImageAnimationTransitioningDelegate
    
    public let toItemDelegate: ImageAnimationTransitioningDelegate
    
    public init(fromItemDelegate: ImageAnimationTransitioningDelegate, toItemDelegate: ImageAnimationTransitioningDelegate) {
        self.fromItemDelegate = fromItemDelegate
        self.toItemDelegate = toItemDelegate
    }
}

extension ImageAnimationController: UIViewControllerAnimatedTransitioning {
    
    public func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        0.0
    }
    
    public func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.viewController(forKey: .from)?.view,
              let toView = transitionContext.viewController(forKey: .to)?.view,
              let fromItem = fromItemDelegate.item,
              let toItem = toItemDelegate.item
        else {
            assertionFailure("Can't perform animation")
            return
        }
        
        fromItemDelegate.willTransitionItem()
        toItemDelegate.willTransitionItem()
        
        imageView.image = fromItem.image
        imageView.layer.cornerRadius = fromItem.cornerRadius
        
        let containerView = transitionContext.containerView
        imageView.frame = fromItemDelegate.itemFrame(in: containerView)
        containerView.addSubview(fromView)
        containerView.addSubview(toView)
        containerView.addSubview(imageView)
        containerView.layoutIfNeeded()
        toView.alpha = 0.0
        
        let animator = UIViewPropertyAnimator(duration: 0.0, timingParameters: UISpringTimingParameters(dampingRatio: 0.825, frequencyResponse: 0.3))
        animator.addAnimations { [unowned self] in
            imageView.frame = toItemDelegate.itemFrame(in: containerView)
            imageView.layer.cornerRadius = toItem.cornerRadius
            imageView.layer.borderColor = toItem.borderColor
            imageView.layer.borderWidth = toItem.borderWidth
            toView.alpha = 1.0
        }
        animator.addCompletion { [weak self] _ in
            guard let self else { return }
            imageView.removeFromSuperview()
            imageView.image = nil
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            fromItemDelegate.didTransitionItem()
            toItemDelegate.didTransitionItem()
        }
        animator.startAnimation()
    }
}
