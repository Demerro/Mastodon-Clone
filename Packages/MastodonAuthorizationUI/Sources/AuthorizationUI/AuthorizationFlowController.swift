//
//  AuthorizationFlowController.swift
//  MastodonAuthorizationUI
//
//  Created by Nikita Prokhorchuk on 24.11.24.
//

import AuthenticationServices
import UIKit
import UIKitFoundation
import AuthorizationDomain
import InstancesUI
import InstancesDomain

public final class AuthorizationFlowController: NavigationController {
    
    private let authorizationService = AuthorizationService()
    
    private let instancesViewController = InstancesViewController()
    
    public init() {
        super.init(rootViewController: instancesViewController)
        instancesViewController.delegate = self
        navigationBar.prefersLargeTitles = true
    }
}

extension AuthorizationFlowController: InstancesViewControllerDelegate {
    
    package func instancesViewController(_ viewController: InstancesViewController, didSelectInstance instance: Instance) {
        let url = authorizationService.makeAuthorizationURL(instanceName: instance.name)
        let session = authorizationService.makeWebAuthenticationSession(url: url)
        session.presentationContextProvider = self
        session.start()
    }
}

extension AuthorizationFlowController: ASWebAuthenticationPresentationContextProviding {
    
    public func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        view.window.unsafelyUnwrapped
    }
}
