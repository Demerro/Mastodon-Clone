//
//  ProfileContainerViewController.swift
//  MastodonProfileUI
//
//  Created by Nikita Prokhorchuk on 13.01.25.
//

import UIKit
import UIKitFoundation
import MastodonCoreUI
import MastodonSharedUI

final class ProfileContainerViewController: ViewController {
    
    let contentViewController = ProfileContentViewController()
    
    private let loadingViewController: LoadingViewController = {
        var configuration = UnavailableConfiguration.loading()
        configuration.text = "Loading profile..."
        return LoadingViewController(contentConfiguration: configuration)
    }()
    
    private let emptyViewController: EmptyViewController = {
        var configuration = UnavailableConfiguration.empty()
        configuration.image = UIImage(systemName: "person.slash")
        configuration.text = "Profile is currently unavailable"
        configuration.secondaryText = "Try again."
        return EmptyViewController(contentConfiguration: configuration)
    }()
    
    override func setupCommon() {
        super.setupCommon()
        emptyViewController.delegate = self
        fetchProfile()
    }
    
    override var childForStatusBarStyle: UIViewController? {
        contentViewController
    }
}

extension ProfileContainerViewController {
    
    private func fetchProfile() {
        switchStateViewController(to: loadingViewController)
//        Task {
//            do {
//                guard let profile = try await profileStore.profile else { return }
//                let configuration = ProfileContentViewController.Configuration(
//                    headerURL: profile.header,
//                    avatarURL: profile.avatar,
//                    displayName: profile.displayName,
//                    username: "@\(profile.username)@\(profileStore.instanceName)",
//                    note: profile.note,
//                    postsCount: profile.statusesCount,
//                    followersCount: profile.followersCount,
//                    followingCount: profile.followingCount,
//                    creationFormattedDate: profile.createdAt,
//                    fields: []
//                )
//                contentViewController.configuration = configuration
//                switchStateViewController(to: contentViewController)
//            } catch {
//                switchStateViewController(to: emptyViewController)
//            }
//        }
    }
}

extension ProfileContainerViewController: EmptyViewControllerDelegate {
    
    func emptyViewControllerDidTapRetryButton(_ viewController: EmptyViewController) {
        fetchProfile()
    }
}
