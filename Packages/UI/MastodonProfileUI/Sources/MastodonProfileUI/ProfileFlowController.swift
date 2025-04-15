//
//  ProfileFlowController.swift
//  MastodonProfileUI
//
//  Created by Nikita Prokhorchuk on 28.12.24.
//

import UIKit
import UIKitFoundation
import MastodonSharedUI

public final class ProfileFlowController: NavigationController {
    
    private let profileContainerViewController = ProfileContainerViewController()
    
    public init() {
        super.init(rootViewController: profileContainerViewController)
        tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "person")!, selectedImage: UIImage(systemName: "person.fill")!)
        profileContainerViewController.contentViewController.delegate = self
    }
}

extension ProfileFlowController: ProfileContentViewControllerDelegate {
    
    func profileContentViewController(_ viewController: ProfileContentViewController, didSelectImage image: UIImage) {
        let imageDetailsViewController = ImageDetailsViewController(image: image)
        pushViewController(imageDetailsViewController, animated: true)
    }
}
