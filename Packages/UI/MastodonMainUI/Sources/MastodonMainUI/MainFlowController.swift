//
//  MainFlowController.swift
//  MastodonMainUI
//
//  Created by Nikita Prokhorchuk on 29.12.24.
//

import UIKit
import UIKitFoundation
import MastodonFeedUI
import MastodonProfileUI

public final class MainFlowController: TabBarController {
    
    private let feedFlowController = FeedFlowController()
    
    private let profileFlowController = ProfileFlowController()
    
    public init() {
        super.init(viewControllers: [feedFlowController, profileFlowController])
        
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        tabBar.standardAppearance = appearance
        tabBar.scrollEdgeAppearance = appearance
    }
}
