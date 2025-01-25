//
//  ProfileFlowController.swift
//  MastodonProfileUI
//
//  Created by Nikita Prokhorchuk on 28.12.24.
//

import UIKit
import UIKitFoundation

public final class ProfileFlowController: NavigationController {
    
    private var currentAnimationTransition: UIViewControllerAnimatedTransitioning? = nil
    
    private let profileContainerViewController = ProfileContainerViewController()
    
    public init() {
        super.init(rootViewController: profileContainerViewController)
        delegate = self
        tabBarItem = UITabBarItem(title: "Profile", image: UIImage(systemName: "person")!, selectedImage: UIImage(systemName: "person.fill")!)
        profileContainerViewController.contentViewController.delegate = self
    }
}

extension ProfileFlowController: UINavigationControllerDelegate {
    
    public func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        if operation == .push, toVC is ImageDetailsViewController {
            let transition = ImageDetailsTransition(operation: operation)
            currentAnimationTransition = transition
            return transition
        }

        if operation == .pop, let fromVC = fromVC as? ImageDetailsViewController {
            if fromVC.isInteractivelyDismissing {
                let transition = ImageDetailsInteractivePopTransition()
                currentAnimationTransition = transition
                fromVC.transitionController = transition
                return transition
            } else {
                let transition = ImageDetailsTransition(operation: operation)
                currentAnimationTransition = transition
                return transition
            }
        }
        
        currentAnimationTransition = nil
        return nil
    }
    
    public func navigationController(_ navigationController: UINavigationController, interactionControllerFor animationController: any UIViewControllerAnimatedTransitioning) -> (any UIViewControllerInteractiveTransitioning)? {
        currentAnimationTransition as? UIViewControllerInteractiveTransitioning
    }
}

extension ProfileFlowController: ProfileContentViewControllerDelegate {
    
    func profileContentViewController(_ viewController: ProfileContentViewController, didSelectImage image: UIImage) {
        let imageDetailsViewController = ImageDetailsViewController(image: image)
        imageDetailsViewController.delegate = self
        pushViewController(imageDetailsViewController, animated: true)
    }
}

extension ProfileFlowController: ImageDetailsViewControllerDelegate {
    
    func imageDetailsViewControllerDidFinish(_ viewController: ImageDetailsViewController) {
        popViewController(animated: true)
        currentAnimationTransition = nil
    }
}
