//
//  AuthorizationFlowController.swift
//  MastodonAuthorizationUI
//
//  Created by Nikita Prokhorchuk on 24.11.24.
//

import AuthenticationServices
import UIKit
import UIKitFoundation
import MastodonKit

@MainActor
public protocol AuthorizationFlowControllerDelegate: AnyObject {
    
    func authorizationFlowControllerDidFinish(_ viewController: AuthorizationFlowController)
}

public final class AuthorizationFlowController: NavigationController {
    
    private let instancesViewController = InstancesViewController()
    
    public weak var flowDelegate: (any AuthorizationFlowControllerDelegate)?
    
    public init() {
        super.init(rootViewController: instancesViewController)
        instancesViewController.delegate = self
        navigationBar.prefersLargeTitles = true
    }
}

extension AuthorizationFlowController: InstancesViewControllerDelegate {
    
    package func instancesViewController(_ viewController: InstancesViewController, didSelectInstance instance: Instance) {
        let url = AuthorizationService.shared.makeAuthorizationURL(instanceName: instance.name)
        let session = AuthorizationService.shared.makeWebAuthenticationSession(url: url) { [self] in
            flowDelegate?.authorizationFlowControllerDidFinish(self)
        }
        session.presentationContextProvider = self
        session.start()
    }
}

extension AuthorizationFlowController: ASWebAuthenticationPresentationContextProviding {
    
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        view.window.unsafelyUnwrapped
    }
}
