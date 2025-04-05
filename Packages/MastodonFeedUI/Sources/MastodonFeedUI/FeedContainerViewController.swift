//
//  FeedContainerViewController.swift
//  MastodonFeedUI
//
//  Created by Nikita Prokhorchuk on 1.02.25.
//

import UIKit
import SafariServices
import UIKitFoundation
import MastodonCoreUI
import MastodonSharedUI
import MastodonFeedDomain

final class FeedContainerViewController: ViewController {
    
    let contentViewController = FeedContentViewController()
    
    private var imageDetailsViewController: ImageDetailsViewController!
    
    private var videoDetailsViewController: VideoDetailsViewController!
    
    private let loadingViewController: LoadingViewController = {
        var configuration = UnavailableConfiguration.loading()
        configuration.text = "Loading feed..."
        return LoadingViewController(contentConfiguration: configuration)
    }()
    
    private lazy var emptyViewController: EmptyViewController = {
        var configuration = UnavailableConfiguration.empty()
        configuration.image = UIImage(systemName: "house.slash")
        configuration.text = "Feed is currently unavailable"
        configuration.secondaryText = "Try again."
        return EmptyViewController(contentConfiguration: configuration)
    }()
    
    override func setupCommon() {
        super.setupCommon()
        title = "Feed"
        emptyViewController.delegate = self
        contentViewController.delegate = self
        fetchFeed()
    }
}

extension FeedContainerViewController {
    
    private func fetchFeed() {
        switchStateViewController(to: loadingViewController)
        Task {
            do {
                let request = AccountStatusesRequest(networkService: .api, instanceHost: "mastodon.social", accessToken: "SJzgmWQDDp8MtTp7yxAd5_taoVtqj40zGRrM871tWuk", accountID: "113520982452809377")
                let statuses = try await withThrowingTaskGroup(of: Status.self) { taskGroup in
                    let statuses = try await request.response()
                    for var status in statuses {
                        taskGroup.addTask {
                            guard !status.content.isEmpty else { return status }
                            var content = try NSAttributedString(data: Data(status.content.utf8), options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil).string
                            content.removeLast()
                            status.content = content
                            return status
                        }
                    }
                    return try await taskGroup
                        .reduce(into: [Status]()) { $0.append($1) }
                        .sorted { $0.createdAt > $1.createdAt }
                }
                contentViewController.configuration = .init(statuses: statuses)
                switchStateViewController(to: contentViewController)
                setContentScrollView(contentViewController.collectionView)
            } catch {
                switchStateViewController(to: emptyViewController)
            }
        }
    }
}

extension FeedContainerViewController: EmptyViewControllerDelegate {
    
    func emptyViewControllerDidTapRetryButton(_ viewController: EmptyViewController) {
        fetchFeed()
    }
}

extension FeedContainerViewController: FeedContentViewControllerDelegate {

    func feedContentViewController(_ viewController: FeedContentViewController, didSelectImage image: UIImage) {
        let imageDetailsViewController = ImageDetailsViewController(image: image)
        imageDetailsViewController.transitioningDelegate = self
        imageDetailsViewController.delegate = self
        imageDetailsViewController.modalPresentationStyle = .fullScreen
        self.imageDetailsViewController = imageDetailsViewController
        present(imageDetailsViewController, animated: true)
    }
    
    func feedContentViewController(_ viewController: FeedContentViewController, didSelectVideoWithURL url: URL, previewImage image: UIImage) {
        let videoDetailsViewController = VideoDetailsViewController(thumbnailImage: image, videoURL: url)
        videoDetailsViewController.transitioningDelegate = self
        videoDetailsViewController.delegate = self
        videoDetailsViewController.modalPresentationStyle = .fullScreen
        self.videoDetailsViewController = videoDetailsViewController
        present(videoDetailsViewController, animated: true)
    }
    
    func feedContentViewController(_ viewController: FeedContentViewController, didSelectURL url: URL) {
        present(SFSafariViewController(url: url), animated: true)
    }
}

extension FeedContainerViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        if presented === imageDetailsViewController {
            ImageAnimationController(fromItemDelegate: contentViewController, toItemDelegate: imageDetailsViewController)
        } else if presented === videoDetailsViewController {
            ImageAnimationController(fromItemDelegate: contentViewController, toItemDelegate: videoDetailsViewController)
        } else {
            nil
        }
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        if dismissed === imageDetailsViewController {
            ImageAnimationController(fromItemDelegate: imageDetailsViewController, toItemDelegate: contentViewController)
        } else if dismissed === videoDetailsViewController {
            ImageAnimationController(fromItemDelegate: videoDetailsViewController, toItemDelegate: contentViewController)
        } else {
            nil
        }
    }
    
    func interactionControllerForDismissal(using animator: any UIViewControllerAnimatedTransitioning) -> (any UIViewControllerInteractiveTransitioning)? {
        if let imageDetailsViewController, imageDetailsViewController.isInteractivelyDismissing {
            let animationController = ImageInteractiveAnimationController(fromItemDelegate: imageDetailsViewController, toItemDelegate: contentViewController)
            imageDetailsViewController.interactiveAnimationController = animationController
            return animationController
        } else if let videoDetailsViewController, videoDetailsViewController.isInteractivelyDismissing {
            let animationController = ImageInteractiveAnimationController(fromItemDelegate: videoDetailsViewController, toItemDelegate: contentViewController)
            videoDetailsViewController.interactiveAnimationController = animationController
            return animationController
        } else {
            return nil
        }
    }
}

extension FeedContainerViewController: ImageDetailsViewControllerDelegate {
    
    func imageDetailsViewControllerDidFinish(_ viewController: ImageDetailsViewController) {
        imageDetailsViewController = nil
    }
}

extension FeedContainerViewController: VideoDetailsViewControllerDelegate {
    
    func videoDetailsViewControllerDidFinish(_ viewController: VideoDetailsViewController) {
        videoDetailsViewController = nil
    }
}
