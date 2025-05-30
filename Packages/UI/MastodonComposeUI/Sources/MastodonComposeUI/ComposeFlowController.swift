//
//  ComposeFlowController.swift
//  MastodonComposeUI
//
//  Created by Nikita Prokhorchuk on 26.05.25.
//

import UIKit
import UIKitFoundation

public final class ComposeFlowController: NavigationController {
    
    private let composeViewController = ComposeViewController()
    
    public init() {
        super.init(rootViewController: composeViewController)
    }
}
