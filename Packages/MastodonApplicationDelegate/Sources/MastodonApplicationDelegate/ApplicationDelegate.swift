//
//  ApplicationDelegate.swift
//  MastodonApplicationDelegate
//
//  Created by Nikita Prokhorchuk on 23.11.24.
//

import UIKit

public final class ApplicationDelegate: NSObject, UIApplicationDelegate {
    
    public func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfiguration = UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        sceneConfiguration.delegateClass = SceneDelegate.self
        return sceneConfiguration
    }
}
