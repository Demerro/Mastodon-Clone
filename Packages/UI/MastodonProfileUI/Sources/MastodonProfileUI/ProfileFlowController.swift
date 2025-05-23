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
    }
}
