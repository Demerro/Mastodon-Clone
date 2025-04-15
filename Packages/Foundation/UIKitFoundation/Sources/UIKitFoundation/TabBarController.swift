//
//  TabBarController.swift
//  UIKitFoundation
//
//  Created by Nikita Prokhorchuk on 29.12.24.
//

import UIKit
import FoundationUtilities

open class TabBarController: UITabBarController {
    
    public init(viewControllers: [UIViewController]) {
        super.init(nibName: nil, bundle: nil)
        self.viewControllers = viewControllers
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError()
    }
    
    open override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        let items = tabBar.value(forKey: valueKey(from: "X2l0ZW1z")) as! [NSObject] // _items
        for item in items {
            let button = item.value(forKey: valueKey(from: "X3ZpZXc=")) as! UIControl // _view
            button.addGestureRecognizer(HighlightTabBarButtonGestureRecognizer())
        }
    }
}

fileprivate final class HighlightTabBarButtonGestureRecognizer: UIGestureRecognizer {
    
    private var imageView: UIImageView? {
        view?.value(forKey: valueKey(from: "X2ltYWdlVmlldw==")) as? UIImageView // _imageView
    }
    
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        cancelsTouchesInView = false
        delaysTouchesBegan = false
        delaysTouchesEnded = false
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: CATransaction.animationDuration(), delay: 0.0) { [self] in
            imageView?.layer.transform = CATransform3DScale(CATransform3DIdentity, 0.8, 0.8, 0.8)
        }
        if #available(iOS 17.0, *) { imageView?.removeSymbolEffect(ofType: .bounce, animated: true) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesCancelled(touches, with: event)
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: CATransaction.animationDuration(), delay: 0.0) { [self] in
            imageView?.layer.transform = CATransform3DIdentity
        }
        if #available(iOS 17.0, *) { imageView?.addSymbolEffect(.bounce) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: CATransaction.animationDuration(), delay: 0.0) { [self] in
            imageView?.layer.transform = CATransform3DIdentity
        }
        if #available(iOS 17.0, *) { imageView?.addSymbolEffect(.bounce) }
    }
}
