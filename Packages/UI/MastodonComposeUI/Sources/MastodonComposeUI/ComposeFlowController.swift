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
    
    private let composeViewController = ComposeViewController(postStatusStore: PostStatusStore())
    
    public weak var flowDelegate: (any Delegate)? = nil
    
    public init() {
        super.init(rootViewController: composeViewController)
    }
}

extension ComposeFlowController: ComposeViewController.Delegate {
    
    func composeViewController(_ viewController: ComposeViewController, didUploadStatus status: Status) {
        flowDelegate?.composeFlowController(self, didFinishWithUploadedStatus: status)
    }
}

extension ComposeFlowController {
    
    @MainActor
    public protocol Delegate: AnyObject {
        func composeFlowController(_ composeFlowController: ComposeFlowController, didFinishWithUploadedStatus status: Status)
    }
}
