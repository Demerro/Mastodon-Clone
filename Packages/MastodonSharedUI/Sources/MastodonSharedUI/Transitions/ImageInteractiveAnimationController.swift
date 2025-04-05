//
//  ImageInteractiveAnimationController.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 27.03.25.
//

import UIKit
import UIKitUtilities

@MainActor
public final class ImageInteractiveAnimationController: NSObject {
    
    private let imageView: UIImageView = {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerCurve = .continuous
        return $0
    }(UIImageView(frame: .zero))
    
    private var appearanceAnimator: UIViewPropertyAnimator!
    
    private var transitionContext: UIViewControllerContextTransitioning?
    
    private let fromItemDelegate: ImageAnimationTransitioningDelegate
    
    private let toItemDelegate: ImageAnimationTransitioningDelegate
    
    public init(fromItemDelegate: ImageAnimationTransitioningDelegate, toItemDelegate: ImageAnimationTransitioningDelegate) {
        self.fromItemDelegate = fromItemDelegate
        self.toItemDelegate = toItemDelegate
    }
}

extension ImageInteractiveAnimationController: UIViewControllerInteractiveTransitioning {
    
    public func startInteractiveTransition(_ transitionContext: any UIViewControllerContextTransitioning) {
        self.transitionContext = transitionContext
        guard let fromView = transitionContext.view(forKey: .from),
              let toView = transitionContext.view(forKey: .to),
              let fromItem = fromItemDelegate.item,
              let toItem = toItemDelegate.item
        else {
            assertionFailure("Can't perform interactive animation")
            return
        }
        
        fromItemDelegate.willTransitionItem()
        toItemDelegate.willTransitionItem()
        
        imageView.image = fromItem.image
        imageView.layer.cornerRadius = fromItem.cornerRadius
        
        let containerView = transitionContext.containerView
        imageView.frame = fromItemDelegate.itemFrame(in: containerView)
        containerView.addSubview(toView)
        containerView.addSubview(fromView)
        containerView.addSubview(imageView)
        
        appearanceAnimator = UIViewPropertyAnimator(duration: 0.0, timingParameters: UISpringTimingParameters(dampingRatio: 0.825, frequencyResponse: 0.3))
        appearanceAnimator.addAnimations { [self] in
            fromView.alpha = 0.0
            imageView.layer.cornerRadius = toItem.cornerRadius
        }
    }
}

extension ImageInteractiveAnimationController {
    
    public func update(with percentageComplete: CGFloat, translation: CGPoint) {
        guard let transitionContext else { return }
        let imageScale = 1.0 - 0.6 * percentageComplete
        imageView.transform = CGAffineTransform(translationX: translation.x, y: translation.y)
            .scaledBy(x: imageScale, y: imageScale)
        appearanceAnimator.fractionComplete = percentageComplete
        transitionContext.updateInteractiveTransition(percentageComplete)
    }
    
    public func completeTransition(withoutFinishing: Bool) {
        guard let transitionContext else { return }
        appearanceAnimator.isReversed = withoutFinishing
        
        let containerView = transitionContext.containerView

        let frame: CGRect = if withoutFinishing {
            fromItemDelegate.itemFrame(in: containerView)
        } else {
            toItemDelegate.itemFrame(in: containerView)
        }
        
        let animator = UIViewPropertyAnimator(duration: 0.0, timingParameters: UISpringTimingParameters(dampingRatio: 0.825, frequencyResponse: 0.3))
        animator.addAnimations { [self] in
            imageView.transform = .identity
            imageView.frame = frame
        }
        animator.addCompletion { [weak self] _ in
            guard let self else { return }
            imageView.removeFromSuperview()
            imageView.image = nil
            withoutFinishing ? transitionContext.cancelInteractiveTransition() : transitionContext.finishInteractiveTransition()
            transitionContext.completeTransition(!withoutFinishing)
            fromItemDelegate.didTransitionItem()
            toItemDelegate.didTransitionItem()
            self.transitionContext = nil
        }
        animator.startAnimation()
        appearanceAnimator.continueAnimation(withTimingParameters: nil, durationFactor: animator.duration / appearanceAnimator.duration)
    }
}

extension ImageInteractiveAnimationController: UIViewControllerAnimatedTransitioning {
    
    public func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        0.0
    }
    
    public func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
    }
}
