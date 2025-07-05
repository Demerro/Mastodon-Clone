//
//  ProfileContainerViewController.swift
//  MastodonProfileUI
//
//  Created by Nikita Prokhorchuk on 13.01.25.
//

import UIKit
import SafariServices
import UIKitFoundation
import MastodonCoreUI
import MastodonSharedUI
import MastodonKit
import MastodonUtilities
import FoundationUtilities

final class ProfileContainerViewController: ViewController {
    
    private let accountStore = AccountStore(username: nil)
    
    let contentViewController = ProfileContentViewController()
    
    private var imageDetailsViewController: ImageDetailsViewController? = nil
    
    private var videoDetailsViewController: VideoDetailsViewController? = nil
    
    private var selectionItem: SelectionItem?
    
    private let loadingViewController: LoadingViewController = {
        var configuration = UnavailableConfiguration.loading()
        configuration.text = "Loading profile..."
        return LoadingViewController(contentConfiguration: configuration)
    }()
    
    private lazy var emptyViewController: EmptyViewController = {
        var configuration = UnavailableConfiguration.empty()
        configuration.image = UIImage(systemName: "person.slash")
        configuration.text = "Profile is currently unavailable"
        configuration.secondaryText = "Try again."
        return EmptyViewController(contentConfiguration: configuration)
    }()
    
    private var task: Task<Void, Never>?
    
    private var isPaginatingBySection = [Int: Bool]()
    
    override func setupCommon() {
        super.setupCommon()
        
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(customView: makeBlurBarButton(image: UIImage(systemName: "gear")!)),
            UIBarButtonItem(customView: makeBlurBarButton(image: UIImage(systemName: "square.and.arrow.up")!)),
            UIBarButtonItem(customView: makeBlurBarButton(image: UIImage(systemName: "star")!)),
            UIBarButtonItem(customView: makeBlurBarButton(image: UIImage(systemName: "bookmark")!)),
            UIBarButtonItem(customView: makeBlurBarButton(image: UIImage(systemName: "number")!)),
        ]
        
        emptyViewController.delegate = self
        contentViewController.delegate = self
        contentViewController.feedContentViewControllerDelegate = self
        contentViewController.aboutViewControllerDelegate = self
        setContentScrollView(contentViewController.profileView.overlayScrollView)
        fetchProfile()
    }
    
    deinit {
        task?.cancel()
    }
}

extension ProfileContainerViewController {
    
    private func fetchProfile() {
        switchStateViewController(to: loadingViewController)
        task = Task {
            await performProfileFetch(shouldShowLoadingViewController: true)
        }
    }

    private func fetchProfileWithoutLoadingController() {
        task = Task {
            await performProfileFetch(shouldShowLoadingViewController: false)
        }
    }

    private func performProfileFetch(shouldShowLoadingViewController: Bool) async {
        do {
            try await accountStore.fetchAccount()
            guard let account = accountStore.account else {
                switchStateViewController(to: emptyViewController)
                assertionFailure("Account is unexpectedly nil")
                return
            }

            var headerConfiguration = HeaderView.Configuration()
            headerConfiguration.displayName = account.displayName
            headerConfiguration.username = account.username
            headerConfiguration.note = account.note
            headerConfiguration.postsCount = account.statusesCount
            headerConfiguration.followingCount = account.followingCount
            headerConfiguration.followersCount = account.followersCount
            contentViewController.headerConfiguration = headerConfiguration
            
            contentViewController.sectionConfiguration = ProfileContentViewController.SectionConfiguration(section: .about(account.fields), reloadData: true)

            shouldShowLoadingViewController ? switchStateViewController(to: contentViewController) : contentViewController.profileView.refreshControl.endRefreshing()

            async let headerImage = try? ImageDownloader.shared.loadAnimatedImage(from: account.header, allowedDiskStorage: true)
            async let avatarImage = try? ImageDownloader.shared.loadAnimatedImage(from: account.avatar, allowedDiskStorage: true)
            headerConfiguration.headerImage = await headerImage
            headerConfiguration.avatarImage = await avatarImage
            contentViewController.headerConfiguration = headerConfiguration

            fetchStatuses()
        } catch {
            switchStateViewController(to: emptyViewController)
        }
        
        func fetchStatuses() {
            Task {
                try? await accountStore.statusesWithoutReblogsStore.refreshStatuses()
                let statuses = accountStore.statusesWithoutReblogsStore.statuses
                contentViewController.sectionConfiguration = .init(section: .withoutReblogs(statuses), reloadData: true)
            }

            Task {
                try? await accountStore.statusesWithoutRepliesStore.refreshStatuses()
                let statuses = accountStore.statusesWithoutRepliesStore.statuses
                contentViewController.sectionConfiguration = .init(section: .withoutReplies(statuses), reloadData: true)
            }

            Task {
                try? await accountStore.statusesWithMediaOnlyStore.refreshStatuses()
                let statuses = accountStore.statusesWithMediaOnlyStore.statuses
                contentViewController.sectionConfiguration = .init(section: .withMediaOnly(statuses), reloadData: true)
            }
        }
    }
}

extension ProfileContainerViewController {
    
    private func showImageDetails(for image: UIImage) {
        let imageDetailsViewController = ImageDetailsViewController(image: image)
        imageDetailsViewController.transitioningDelegate = self
        imageDetailsViewController.delegate = self
        imageDetailsViewController.modalPresentationStyle = .fullScreen
        self.imageDetailsViewController = imageDetailsViewController
        present(imageDetailsViewController, animated: true)
    }
    
    private func makeBlurBarButton(image: UIImage) -> BlurButton {
        let blurButton = BlurButton(frame: .zero)
        blurButton.imageView.image = image
        let setAllowsGroupFilteringSelector = NSSelectorFromEncodedString("X3NldEFsbG93c0dyb3VwRmlsdGVyaW5nOg==") // _setAllowsGroupFiltering:
        let setGroupNameSelector = NSSelectorFromEncodedString("X3NldEdyb3VwTmFtZTo=") // _setGroupName:
        if blurButton.visualEffectView.responds(to: setAllowsGroupFilteringSelector), blurButton.visualEffectView.responds(to: setGroupNameSelector) {
            blurButton.visualEffectView.perform(setAllowsGroupFilteringSelector, with: true)
            blurButton.visualEffectView.perform(setGroupNameSelector, with: CategorySegmentedControl.visualEffectGroupName)
        }
        return blurButton
    }
}

extension ProfileContainerViewController: EmptyViewControllerDelegate {
    
    func emptyViewControllerDidTapRetryButton(_ viewController: EmptyViewController) {
        fetchProfile()
    }
}

extension ProfileContainerViewController: ProfileContentViewControllerDelegate {
    
    func profileContentViewController(_ viewController: ProfileContentViewController, didSelectImageView imageView: UIImageView) {
        guard imageDetailsViewController == nil, let image = imageView.image else { return }
        selectionItem = SelectionItem(view: imageView, image: image)
        showImageDetails(for: image)
    }
    
    func profileContentViewControllerShouldRefresh(_ viewController: ProfileContentViewController) {
        fetchProfileWithoutLoadingController()
    }
}

extension ProfileContainerViewController: ImageDetailsViewControllerDelegate {
    
    func imageDetailsViewControllerDidFinish(_ viewController: ImageDetailsViewController) {
        imageDetailsViewController = nil
    }
}

extension ProfileContainerViewController: VideoDetailsViewControllerDelegate {
    
    func videoDetailsViewControllerDidFinish(_ viewController: VideoDetailsViewController) {
        videoDetailsViewController = nil
    }
}

extension ProfileContainerViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        if presented === imageDetailsViewController {
            ImageAnimationController(fromItemDelegate: self, toItemDelegate: imageDetailsViewController!)
        } else if presented === videoDetailsViewController {
            ImageAnimationController(fromItemDelegate: self, toItemDelegate: videoDetailsViewController!)
        } else {
            nil
        }
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> (any UIViewControllerAnimatedTransitioning)? {
        if dismissed === imageDetailsViewController {
            ImageAnimationController(fromItemDelegate: imageDetailsViewController!, toItemDelegate: self)
        } else if dismissed === videoDetailsViewController {
            ImageAnimationController(fromItemDelegate: videoDetailsViewController!, toItemDelegate: self)
        } else {
            nil
        }
    }
    
    func interactionControllerForDismissal(using animator: any UIViewControllerAnimatedTransitioning) -> (any UIViewControllerInteractiveTransitioning)? {
        if let imageDetailsViewController, imageDetailsViewController.isInteractivelyDismissing {
            let animationController = ImageInteractiveAnimationController(fromItemDelegate: imageDetailsViewController, toItemDelegate: self)
            imageDetailsViewController.interactiveAnimationController = animationController
            return animationController
        } else if let videoDetailsViewController, videoDetailsViewController.isInteractivelyDismissing {
            let animationController = ImageInteractiveAnimationController(fromItemDelegate: videoDetailsViewController, toItemDelegate: self)
            videoDetailsViewController.interactiveAnimationController = animationController
            return animationController
        } else {
            return nil
        }
    }
}

extension ProfileContainerViewController: FeedContentViewControllerDelegate {
    
    func feedContentViewController(_ viewController: MastodonSharedUI.FeedContentViewController, didSelectImageView imageView: UIImageView) {
        guard imageDetailsViewController?.presentedViewController == nil, let image = imageView.image else { return }
        selectionItem = SelectionItem(view: imageView, image: image)
        showImageDetails(for: image)
    }

    func feedContentViewController(_ viewController: FeedContentViewController, didSelectVideoWithURL url: URL, selectionItem: SelectionItem) {
        self.selectionItem = selectionItem
        let videoDetailsViewController = VideoDetailsViewController(thumbnailImage: selectionItem.image, videoURL: url)
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
    
    func feedContentViewControllerDidPagination(_ viewController: FeedContentViewController) {
        guard !(isPaginatingBySection[contentViewController.currentIndex] ?? false) else { return }
        isPaginatingBySection[contentViewController.currentIndex] = true
        Task {
            defer { isPaginatingBySection[contentViewController.currentIndex] = false }
            switch contentViewController.currentIndex {
            case 0:
                guard !accountStore.statusesWithoutReblogsStore.allStatusesDisplayed else { return }
                try? await accountStore.statusesWithoutReblogsStore.appendStatuses()
                let statuses = accountStore.statusesWithoutReblogsStore.statuses
                contentViewController.sectionConfiguration = .init(section: .withoutReblogs(statuses), reloadData: false)
            case 1:
                guard !accountStore.statusesWithoutRepliesStore.allStatusesDisplayed else { return }
                try? await accountStore.statusesWithoutRepliesStore.appendStatuses()
                let statuses = accountStore.statusesWithoutRepliesStore.statuses
                contentViewController.sectionConfiguration = .init(section: .withoutReplies(statuses), reloadData: false)
            case 2:
                guard !accountStore.statusesWithMediaOnlyStore.allStatusesDisplayed else { return }
                try? await accountStore.statusesWithMediaOnlyStore.appendStatuses()
                let statuses = accountStore.statusesWithMediaOnlyStore.statuses
                contentViewController.sectionConfiguration = .init(section: .withMediaOnly(statuses), reloadData: false)
            default:
                break
            }
        }
    }
}

extension ProfileContainerViewController: ImageAnimationTransitioningDelegate {
    
    func willTransitionItem() {
        guard let selectionItem else { return }
        selectionItem.view.alpha = 0.0
    }
    
    var item: TransitionItem? {
        if let selectionItem {
            TransitionItem(
                image: selectionItem.image,
                cornerRadius: selectionItem.view.layer.cornerRadius,
                borderColor: selectionItem.view.layer.borderColor,
                borderWidth: selectionItem.view.layer.borderWidth
            )
        } else {
            nil
        }
    }
    
    func itemFrame(in view: UIView) -> CGRect {
        if let selectionItem {
            selectionItem.view.superview!.convert(selectionItem.view.frame, to: view)
        } else {
            .null
        }
    }
    
    func didTransitionItem() {
        guard let selectionItem else { return }
        selectionItem.view.alpha = 1.0
    }
}

extension ProfileContainerViewController: AboutViewControllerDelegate {
    
    func aboutViewController(_ viewController: AboutViewController, didSelectURL url: URL) {
        present(SFSafariViewController(url: url), animated: true)
    }
}
