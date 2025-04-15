//
//  ApplicationFlowController.swift
//  MastodonApplicationUI
//
//  Created by Nikita Prokhorchuk on 23.11.24.
//

import UIKit
import UIKitFoundation
import MastodonMainUI
import MastodonAuthorizationUI
import MastodonKit

public final class ApplicationFlowController: ViewController {
    
    private lazy var authorizationFlowController = AuthorizationFlowController()
    
    private lazy var mainFlowController = MainFlowController()
    
    public override func setupCommon() {
        super.setupCommon()
        if AuthorizationService.shared.isAuthorized {
            mainFlowController.willMove(toParent: self)
            view.addSubview(mainFlowController.view)
            addChild(mainFlowController)
        } else {
            authorizationFlowController.willMove(toParent: self)
            view.addSubview(authorizationFlowController.view)
            addChild(authorizationFlowController)
            authorizationFlowController.flowDelegate = self
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        (AuthorizationService.shared.isAuthorized ? mainFlowController : authorizationFlowController).didMove(toParent: self)
    }
}

extension ApplicationFlowController: AuthorizationFlowControllerDelegate {

    public func authorizationFlowControllerDidFinish(_ viewController: AuthorizationFlowController) {
        view.addSubview(mainFlowController.view)
        addChild(mainFlowController)
        mainFlowController.didMove(toParent: self)
        transition(from: viewController, to: mainFlowController, duration: CATransaction.animationDuration(), options: .transitionCrossDissolve, animations: nil)
    }
}
