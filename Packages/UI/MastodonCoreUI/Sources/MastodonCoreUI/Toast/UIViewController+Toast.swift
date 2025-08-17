//
//  UIViewController+Toast.swift
//  MastodonCoreUI
//
//  Created by Nikita Prokhorchuk on 15.08.25.
//

import UIKit
import UIKitUtilities

extension UIViewController {
    
    public func presentToast(text: String, image: UIImage? = nil) {
        guard let window = view.window, !window.subviews.contains(where: { $0 is ToastView }) else { return }
        
        let toastView = ToastView(frame: .zero)
        toastView.configuration = if let image {
            ToastView.DefaultConfiguration(text: text, image: image)
        } else {
            ToastView.TextConfiguration(text: text)
        }
        
        addToast(toastView, to: window)
    }
    
    public func presentLoadingToast(text: String) {
        guard let window = view.window, !window.subviews.contains(where: { $0 is ToastView }) else { return }
        
        let toastView = ToastView(frame: .zero)
        toastView.configuration = ToastView.LoadingConfiguration(text: text)
        
        addToast(toastView, to: window)
    }
    
    public func dismissToast() {
        guard let window = view.window, let toastView = window.subviews.first(where: { $0 is ToastView }) as? ToastView else { return }
        let animator = UIViewPropertyAnimator(duration: 0.0, timingParameters: UISpringTimingParameters(frequencyResponse: 0.5))
        animator.addAnimations {
            toastView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            toastView.alpha = 0.0
        }
        animator.addCompletion { _ in
            toastView.removeFromSuperview()
        }
        animator.startAnimation()
    }
}

extension UIViewController {
    
    private func addToast(_ toastView: ToastView, to window: UIWindow) {
        toastView.translatesAutoresizingMaskIntoConstraints = false
        
        window.addSubview(toastView)
        NSLayoutConstraint.activate([
            toastView.centerXAnchor.constraint(equalTo: window.centerXAnchor),
            window.bottomAnchor.constraint(equalTo: toastView.centerYAnchor, constant: 150.0),
        ])
        toastView.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        toastView.alpha = 0.0
        toastView.layoutIfNeeded()
        
        let animator = UIViewPropertyAnimator(duration: 0.0, timingParameters: UISpringTimingParameters(frequencyResponse: 0.5))
        animator.addAnimations {
            toastView.transform = .identity
            toastView.alpha = 1.0
        }
        animator.startAnimation()
    }
}
