//
//  MainFlowController.swift
//  MastodonMainUI
//
//  Created by Nikita Prokhorchuk on 29.12.24.
//

import UIKit
import UIKitFoundation
import MastodonProfileUI

public final class MainFlowController: TabBarController {
    
    private let profileFlowController = ProfileFlowController()
    
    public init() {
        super.init(viewControllers: [profileFlowController])
    }
}
