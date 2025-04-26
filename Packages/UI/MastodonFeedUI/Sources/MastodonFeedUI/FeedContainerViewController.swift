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
import MastodonKit

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
    
    private let titleButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.title = "Following"
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.preferredFont(forTextStyle: .title3, compatibleWith: UITraitCollection(legibilityWeight: .bold))
            outgoing.foregroundColor = .label
            return outgoing
        }
        configuration.titleAlignment = .leading
        configuration.image = UIImage(systemName: "chevron.down.circle", withConfiguration: UIImage.SymbolConfiguration(textStyle: .caption1))
        configuration.baseForegroundColor = .secondaryLabel
        configuration.imagePadding = 10.0
        configuration.imagePlacement = .trailing
        let button = UIButton(configuration: configuration)
        button.contentHorizontalAlignment = .leading
        button.showsMenuAsPrimaryAction = true
        return button
    }()
    
    private(set) var state = State.following {
        didSet {
            titleButton.configuration?.title = state == .following ? "Following" : "Local"
            titleButton.menu = titleButtonMenu
            fetchFeed()
        }
    }
    
    private let timelineStore = TimelineStore()
    
    private var task: Task<Void, any Error>?
    
    private var isPaginating = false
    
    override func setupCommon() {
        super.setupCommon()
        titleButton.menu = titleButtonMenu
        navigationItem.leftBarButtonItem = UIBarButtonItem(customView: titleButton)
        emptyViewController.delegate = self
        contentViewController.delegate = self
        setContentScrollView(contentViewController.collectionView)
        fetchFeed()
    }
}

extension FeedContainerViewController {
    
    enum State {
        
        case following
        
        case local
    }
    
    private var titleButtonMenu: UIMenu {
        UIMenu(children: [
            UIAction(title: "Following", image: UIImage(systemName: "house"), state: state == .following ? .on : .off) { [unowned self] _ in
                state = .following
            },
            UIAction(title: "Local", image: UIImage(systemName: "building.2"), state: state == .local ? .on : .off) { [unowned self] _ in
                state = .local
            },
        ])
    }
}

extension FeedContainerViewController {
    
    private func fetchFeed() {
        switchStateViewController(to: loadingViewController)
        task?.cancel()
        task = Task {
            do {
                switch state {
                case .following:
                    try await timelineStore.refreshHomeTimeline()
                case .local:
                    try await timelineStore.refreshPublicTimeline()
                }
                contentViewController.configuration = await FeedContentViewController.Configuration(statuses: timelineStore.statuses, reloadData: true)
                switchStateViewController(to: contentViewController)
            } catch {
                switchStateViewController(to: emptyViewController)
            }
        }
    }
    
    private func fetchFeedWithoutLoadingController() {
        task?.cancel()
        task = Task {
            do {
                switch state {
                case .following:
                    try await timelineStore.refreshHomeTimeline()
                case .local:
                    try await timelineStore.refreshPublicTimeline()
                }
                contentViewController.configuration = await FeedContentViewController.Configuration(statuses: timelineStore.statuses, reloadData: true)
            } catch {
                switchStateViewController(to: emptyViewController)
            }
            contentViewController.collectionView.refreshControl?.endRefreshing()
        }
    }
    
    private func appendFeed() {
        guard !isPaginating else { return }
        isPaginating = true
        task?.cancel()
        task = Task {
            defer { isPaginating = false }
            switch state {
            case .following:
                try await timelineStore.appendHomeTimeline()
            case .local:
                try await timelineStore.appendPublicTimeline()
            }
            contentViewController.configuration = await FeedContentViewController.Configuration(statuses: timelineStore.statuses, reloadData: false)
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
    
    func feedContentViewController(_ viewController: FeedContentViewController, didSelectTextURL textUrl: URL) {
        present(SFSafariViewController(url: textUrl), animated: true)
    }
    
    func feedContentViewController(_ viewController: FeedContentViewController, didShareStatusURL statusUrl: URL) {
        present(UIActivityViewController(activityItems: [statusUrl], applicationActivities: nil), animated: true)
    }
    
    func feedContentViewControllerDidRefresh(_ viewController: FeedContentViewController) {
        fetchFeedWithoutLoadingController()
    }
    
    func feedContentViewControllerDidPagination(_ viewController: FeedContentViewController) {
        appendFeed()
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
