//
//  ProfileContainerViewController.swift
//  MastodonProfileUI
//
//  Created by Nikita Prokhorchuk on 13.01.25.
//

import UIKit
import UIKitFoundation
import MastodonCoreUI
import MastodonAccountsDomain

final class ProfileContainerViewController: ViewController {
    
    private let profileStore = ProfileStore()
    
    private var task: Task<Void, Error>?
    
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
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        task?.cancel()
        task = nil
    }
}

extension ProfileContainerViewController {
    
    private func fetchProfile() {
        transition(to: loadingViewController)
        task = Task {
            do {
                guard let profile = try await profileStore.profile else { return }
                let configuration = ProfileContentViewController.Configuration(
                    headerURL: profile.header,
                    avatarURL: profile.avatar,
                    displayName: profile.displayName,
                    username: "@\(profile.username)@\(profileStore.instanceName)",
                    note: profile.note,
                    postsCount: profile.statusesCount,
                    followersCount: profile.followersCount,
                    followingCount: profile.followingCount,
                    creationFormattedDate: profile.createdAt,
                    fields: []
                )
                contentViewController.configuration = configuration
                transition(to: contentViewController)
            } catch {
                transition(to: emptyViewController)
            }
        }
    }
    
    private func parse(stringDate: String) async -> String {
        let isoDateFormatter = ISO8601DateFormatter()
        isoDateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        dateFormatter.timeStyle = .none
        
        return dateFormatter.string(from: isoDateFormatter.date(from: stringDate)!)
    }
}

extension ProfileContainerViewController {
    
    private func transition(to viewController: ViewController) {
        let currentViewController = children.first { $0 is EmptyViewController || $0 is LoadingViewController }
        viewController.willMove(toParent: self)
        addChild(viewController)
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
        viewController.view.frame = view.frame
        if let currentViewController {
            transition(from: currentViewController, to: viewController, duration: CATransaction.animationDuration(), options: .transitionCrossDissolve, animations: nil)
        }
    }
}

extension ProfileContainerViewController: EmptyViewControllerDelegate {
    
    func emptyViewControllerDidTapRetryButton(_ viewController: EmptyViewController) {
        fetchProfile()
    }
}

extension ProfileContainerViewController: ImageDetailsTransitioningDelegate {
    
    func willTransitionItemWith(context: any UIViewControllerContextTransitioning, coordinator: (any UIViewControllerTransitionCoordinator)?) {
        contentViewController.lastSelectedImageView!.isHidden = true
    }
    
    func item(forTransitionWith context: any UIViewControllerContextTransitioning) -> ImageDetailsItem {
        let imageView = contentViewController.lastSelectedImageView!
        return ImageDetailsItem(image: imageView.image!, cornerRadius: imageView.layer.cornerRadius, borderWidth: imageView.layer.borderWidth, borderColor: imageView.layer.borderColor)
    }
    
    func itemFrame(in view: UIView, forTransitionWith context: any UIViewControllerContextTransitioning) -> CGRect {
        let imageView = contentViewController.lastSelectedImageView!
        return contentViewController.profileView.convert(imageView.frame, to: view)
    }
    
    func didTransitionItemWith(context: any UIViewControllerContextTransitioning) {
        contentViewController.lastSelectedImageView!.isHidden = false
    }
}
