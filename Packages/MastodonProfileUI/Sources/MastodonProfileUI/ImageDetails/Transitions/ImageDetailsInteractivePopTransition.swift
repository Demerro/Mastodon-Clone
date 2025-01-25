//
//  ImageDetailsInteractivePopTransition.swift
//  MastodonProfileUI
//
//  Created by Nikita Prokhorchuk on 17.01.25.
//

import UIKit
import SwiftUtilities
import UIKitUtilities

@MainActor
final class ImageDetailsInteractivePopTransition: NSObject {
    
    private var transitionContext: (any UIViewControllerContextTransitioning)!
    
    private var fromItemDelegate: (any ImageDetailsTransitioningDelegate)!
    
    private var toItemDelegate: (any ImageDetailsTransitioningDelegate)!
    
    private var appearanceAnimator: UIViewPropertyAnimator!
    
    private let imageView: UIImageView = {
        $0.contentMode = .scaleAspectFit
        $0.clipsToBounds = true
        $0.layer.cornerCurve = .continuous
        return $0
    }(UIImageView(frame: .zero))
}

extension ImageDetailsInteractivePopTransition {
    
    func updateInteractiveTransition(with gestureRecognizer: UIPanGestureRecognizer) {
        guard let transitionContext else { return }
        
        let maxTranslation = transitionContext.containerView.frame.height / 2.0
        let translation = gestureRecognizer.translation(in: nil)
        let velocity = gestureRecognizer.velocity(in: nil)
        let percentageComplete = clamp(abs(translation.y) / maxTranslation, min: 0.0, max: 1.0)
        let transitionImageScale = 1.0 - 0.6 * percentageComplete
        
        switch gestureRecognizer.state {
        case .cancelled, .failed:
            completeTransition(true)
        case .changed:
            imageView.transform = CGAffineTransform(scaleX: transitionImageScale, y: transitionImageScale)
            imageView.center = fromItemDelegate.itemFrame(in: transitionContext.containerView, forTransitionWith: transitionContext).center + CGVector(to: translation)
            transitionContext.updateInteractiveTransition(percentageComplete)
            appearanceAnimator.fractionComplete = percentageComplete
        case .ended:
            completeTransition(percentageComplete < 0.2, with: velocity)
        default:
            break
        }
    }
    
    private func completeTransition(_ didCancel: Bool, with gestureRecognizerVelocity: CGPoint = .zero) {
        appearanceAnimator.isReversed = didCancel
        
        let containerView = transitionContext.containerView

        let frame: CGRect = if didCancel {
            fromItemDelegate.itemFrame(in: containerView, forTransitionWith: transitionContext)
        } else {
            toItemDelegate.itemFrame(in: containerView, forTransitionWith: transitionContext)
        }
        let velocity = initialAnimationVelocity(for: gestureRecognizerVelocity, from: imageView.frame.center, to: frame.center)
        
        let animator = UIViewPropertyAnimator(duration: 0.0, timingParameters: UISpringTimingParameters(dampingRatio: 0.825, frequencyResponse: 0.5, initialVelocity: velocity))
        animator.addAnimations { [self] in
            imageView.transform = .identity
            imageView.frame = frame
        }
        animator.addCompletion { [weak self] _ in
            guard let self else { return }
            imageView.removeFromSuperview()
            imageView.image = nil
            didCancel ? transitionContext.cancelInteractiveTransition() : transitionContext.finishInteractiveTransition()
            transitionContext.completeTransition(!didCancel)
            fromItemDelegate.didTransitionItemWith(context: transitionContext)
            toItemDelegate.didTransitionItemWith(context: transitionContext)
            transitionContext = nil
        }
        animator.startAnimation()
        appearanceAnimator.continueAnimation(withTimingParameters: nil, durationFactor: animator.duration / appearanceAnimator.duration)
    }
    
    private func initialAnimationVelocity(for gestureVelocity: CGPoint, from currentPosition: CGPoint, to finalPosition: CGPoint) -> CGVector {
        var animationVelocity = CGVector.zero
        let yDistance = finalPosition.y - currentPosition.y
        if yDistance != 0.0 {
            animationVelocity.dy = gestureVelocity.y / yDistance
        }
        return animationVelocity
    }
}

extension ImageDetailsInteractivePopTransition: UIViewControllerInteractiveTransitioning {
    
    func startInteractiveTransition(_ transitionContext: any UIViewControllerContextTransitioning) {
        guard let fromView = transitionContext.view(forKey: .from),
              let toView = transitionContext.view(forKey: .to),
              let fromViewController = transitionContext.viewController(forKey: .from),
              let toViewController = transitionContext.viewController(forKey: .to),
              let fromItemDelegate = fromViewController as? ImageDetailsTransitioningDelegate,
              let toItemDelegate = toViewController as? ImageDetailsTransitioningDelegate
        else { preconditionFailure() }
        
        self.transitionContext = transitionContext
        self.fromItemDelegate = fromItemDelegate
        self.toItemDelegate = toItemDelegate
        
        fromItemDelegate.willTransitionItemWith(context: transitionContext, coordinator: fromViewController.transitionCoordinator)
        toItemDelegate.willTransitionItemWith(context: transitionContext, coordinator: toViewController.transitionCoordinator)
        
        let fromItem = fromItemDelegate.item(forTransitionWith: transitionContext)
        imageView.image = fromItem.image
        imageView.layer.cornerRadius = fromItem.cornerRadius
        imageView.layer.borderWidth = fromItem.borderWidth
        imageView.layer.borderColor = fromItem.borderColor

        let containerView = transitionContext.containerView
        imageView.frame = fromItemDelegate.itemFrame(in: containerView, forTransitionWith: transitionContext)
        containerView.addSubview(toView)
        containerView.addSubview(fromView)
        containerView.addSubview(imageView)
        
        let toItem = toItemDelegate.item(forTransitionWith: transitionContext)
        appearanceAnimator = UIViewPropertyAnimator(duration: 0.0, dampingRatio: 0.825) { [imageView] in
            fromView.alpha = 0.0
            imageView.layer.cornerRadius = toItem.cornerRadius
            imageView.layer.borderWidth = toItem.borderWidth
            imageView.layer.borderColor = toItem.borderColor
        }
        
        toViewController.tabBarController?.setTabBar(hidden: false, alongside: appearanceAnimator)
    }
}

extension ImageDetailsInteractivePopTransition: UIViewControllerAnimatedTransitioning {
    
    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        0.0
    }
    
    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
    }
}
