//
//  SceneDelegate.swift
//  MastodonApplicationDelegate
//
//  Created by Nikita Prokhorchuk on 23.11.24.
//

import UIKit
import MastodonApplicationUI

public final class SceneDelegate: NSObject, UISceneDelegate {
    
    public var window: UIWindow?
    
    public func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        let window = UIWindow(windowScene: scene as! UIWindowScene)
        window.rootViewController = ApplicationFlowController()
        window.makeKeyAndVisible()
        self.window = window
    }
}
