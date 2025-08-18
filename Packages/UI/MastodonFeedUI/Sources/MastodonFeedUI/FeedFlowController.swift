//
//  FeedFlowController.swift
//  MastodonFeedUI
//
//  Created by Nikita Prokhorchuk on 25.01.25.
//

import UIKit
import UIKitFoundation
import MastodonSharedUI

public final class FeedFlowController: NavigationController {

    public let feedContainerViewController = FeedContainerViewController()
    
    public init() {
        super.init(rootViewController: feedContainerViewController)
        tabBarItem = UITabBarItem(title: nil, image: UIImage(systemName: "house")!, selectedImage: UIImage(systemName: "house.fill")!)
    }
}
