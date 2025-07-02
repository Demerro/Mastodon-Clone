//
//  ComposeFlowController.swift
//  MastodonComposeUI
//
//  Created by Nikita Prokhorchuk on 26.05.25.
//

import UIKit
import UIKitFoundation
import MastodonKit

public final class ComposeFlowController: NavigationController {
    
    public init() {
        let composeViewController = ComposeViewController(postStatusStore: PostStatusStore())
        super.init(rootViewController: composeViewController)
    }
}
