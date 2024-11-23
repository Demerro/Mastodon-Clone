//
//  AppDelegate.swift
//  Mastodon-Clone
//
//  Created by Nikita Prokhorchuk on 23.11.24.
//

import UIKit

final class AppDelegate: UIResponder, UIApplicationDelegate {
  
  func application(
    _ application: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    let sceneConfiguration = UISceneConfiguration(
      name: nil,
      sessionRole: connectingSceneSession.role
    )
    sceneConfiguration.delegateClass = SceneDelegate.self
    return sceneConfiguration
  }
}
