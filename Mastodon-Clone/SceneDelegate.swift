//
//  SceneDelegate.swift
//  Mastodon-Clone
//
//  Created by Nikita Prokhorchuk on 23.11.24.
//

import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
  
  var window: UIWindow?
  
  func scene(
    _ scene: UIScene,
    willConnectTo session: UISceneSession,
    options connectionOptions: UIScene.ConnectionOptions
  ) {
    let window = UIWindow(windowScene: scene as! UIWindowScene)
    window.rootViewController = ViewController()
    window.makeKeyAndVisible()
    self.window = window
  }
}
