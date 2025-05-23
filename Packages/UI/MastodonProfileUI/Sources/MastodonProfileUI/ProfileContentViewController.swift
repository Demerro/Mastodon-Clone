//
//  ProfileContentViewController.swift
//  MastodonProfileUI
//
//  Created by Nikita Prokhorchuk on 27.04.25.
//

import UIKit
import UIKitFoundation
import SwiftUtilities
import FoundationUtilities
import MastodonCoreUI
import MastodonSharedUI
import MastodonKit

@MainActor
protocol ProfileContentViewControllerDelegate: AnyObject {
    
    func profileContentViewController(_ viewController: ProfileContentViewController, didSelectImageView imageView: UIImageView)
    
    func profileContentViewControllerShouldRefresh(_ viewController: ProfileContentViewController)
}

final class ProfileContentViewController: ViewController {
    
    let profileView = ProfileView(frame: .zero)
    
    private let feedWithoutReplies = FeedContentViewController()
    private let feedWithoutReblogs = FeedContentViewController()
    private let feedWithMediaOnly = FeedContentViewController()
    private let aboutViewController = AboutViewController()
    
    private lazy var viewControllers = [feedWithoutReplies, feedWithoutReblogs, feedWithMediaOnly, aboutViewController]
    
    private(set) var currentIndex = 0
    
    private var contentOffsetsY = [Int: CGFloat]()
    
    private var navigationBarBackgroundView: UIView? {
        navigationController?.navigationBar.value(forKey: valueKey(from: "X2JhY2tncm91bmRWaWV3")) as? UIView
    }
    
    var headerConfiguration = HeaderView.Configuration() {
        didSet { profileView.headerView.configuration = headerConfiguration }
    }
    
    var sectionConfiguration = SectionConfiguration() {
        didSet { applySectionConfiguration() }
    }
    
    weak var delegate: (any ProfileContentViewControllerDelegate)?
    
    weak var feedContentViewControllerDelegate: (any FeedContentViewControllerDelegate)? {
        didSet {
            feedWithoutReplies.delegate = feedContentViewControllerDelegate
            feedWithoutReblogs.delegate = feedContentViewControllerDelegate
            feedWithMediaOnly.delegate = feedContentViewControllerDelegate
        }
    }
    
    weak var aboutViewControllerDelegate: (any AboutViewControllerDelegate)? {
        didSet { aboutViewController.delegate = aboutViewControllerDelegate }
    }
    
    override func setupCommon() {
        super.setupCommon()
        
        profileView.categorySegmentedControl.delegate = self
        
        profileView.pagingCollectionView.pagingDelegate = self
        profileView.pagingCollectionView.dataSource = self
        
        profileView.overlayScrollView.delegate = self
        profileView.containerScrollView.addGestureRecognizer(profileView.overlayScrollView.panGestureRecognizer)
        
        profileView.refreshControl.addAction(UIAction { [unowned self] _ in
            delegate?.profileContentViewControllerShouldRefresh(self)
        }, for: .valueChanged)
        
        for viewController in viewControllers {
            addChild(viewController)
            let scrollView = viewController.view as! UIScrollView
            scrollView.panGestureRecognizer.require(toFail: profileView.overlayScrollView.panGestureRecognizer)
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.showsVerticalScrollIndicator = false
            scrollView.bounces = false
            if let feedCollectionView = scrollView as? FeedCollectionView {
                feedCollectionView.observer = self
            }
        }
        profileView.headerView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer)))
    }
    
    override func loadView() {
        view = profileView
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        for subview in navigationBarBackgroundView?.subviews ?? [] where subview is UIVisualEffectView {
            let visualEffectView = subview as! UIVisualEffectView
            let setAllowsGroupFilteringSelector = NSSelectorFromEncodedString("X3NldEFsbG93c0dyb3VwRmlsdGVyaW5nOg==") // _setAllowsGroupFiltering:
            let setGroupNameSelector = NSSelectorFromEncodedString("X3NldEdyb3VwTmFtZTo=") // _setGroupName:
            if visualEffectView.responds(to: setGroupNameSelector), visualEffectView.responds(to: setAllowsGroupFilteringSelector) {
                visualEffectView.perform(setAllowsGroupFilteringSelector, with: true)
                visualEffectView.perform(setGroupNameSelector, with: CategorySegmentedControl.visualEffectGroupName)
            }
            break
        }
    }
}

extension ProfileContentViewController {
    
    private func recalculateContentSize(_ contentSize: CGSize) -> CGSize {
        let systemSpacing = 16.0
        let safeAreaBottomInset = view.safeAreaInsets.bottom
        let safeAreaTopInset = view.safeAreaInsets.top
        let maxHeaderHeight = profileView.headerView.bounds.height + systemSpacing
        let contentHeight = max(contentSize.height, view.frame.height - safeAreaTopInset - safeAreaBottomInset)
        return CGSize(width: contentSize.width, height: contentHeight + maxHeaderHeight + safeAreaBottomInset)
    }
    
    @objc
    private func handleTapGestureRecognizer(_ gestureRecognizer: UITapGestureRecognizer) {
        let headerView = profileView.headerView
        let point = gestureRecognizer.location(in: profileView.headerView)
        let imageView: UIImageView
        if headerView.convert(headerView.avatarImageView.frame, to: view).contains(point) {
            imageView = headerView.avatarImageView
        } else if headerView.convert(headerView.headerImageView.frame, to: view).contains(point) {
            imageView = headerView.headerImageView
        } else {
            return
        }
        delegate?.profileContentViewController(self, didSelectImageView: imageView)
    }
}

extension ProfileContentViewController: CategorySegmentedControlDelegate {
    
    func categorySegmentedControl(_ segmentedControl: CategorySegmentedControl, didSelectItemAt index: Int) {
        profileView.pagingCollectionView.scrollToItem(at: IndexPath(item: index, section: 0), at: .centeredHorizontally, animated: true)
    }
}

extension ProfileContentViewController: PagingCollectionViewDelegate {
    
    func collectionViewDidBeginPaging(_ collectionView: PagingCollectionView, from fromIndexPath: IndexPath, to toIndexPath: IndexPath) {
        profileView.categorySegmentedControl.startInteractiveAnimation(toSelectedIndex: toIndexPath.item)
    }
    
    func collectionViewDidEndPaging(_ collectionView: PagingCollectionView, at indexPath: IndexPath) {
        let selectedIndex = profileView.categorySegmentedControl.state.selectedIndex
        let newIndex = indexPath.item

        let segmentedControl = profileView.categorySegmentedControl
        if selectedIndex == newIndex {
            segmentedControl.finishInteractiveAnimation()
        } else {
            segmentedControl.cancelInteractiveAnimation()
        }

        currentIndex = newIndex

        let savedOffsetY = contentOffsetsY[currentIndex] ?? profileView.containerScrollView.contentOffset.y
        profileView.overlayScrollView.contentOffset.y = savedOffsetY

        if let scrollView = viewControllers[currentIndex].view as? UIScrollView {
            profileView.overlayScrollView.contentSize = recalculateContentSize(scrollView.contentSize)
        }
    }
    
    func collectionViewDidPaging(_ collectionView: PagingCollectionView, withProgress progress: CGFloat) {
        profileView.categorySegmentedControl.updateInteractiveAnimation(progress)
    }
}

extension ProfileContentViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewControllers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PagingCollectionViewCell.identifier, for: indexPath) as! PagingCollectionViewCell
        cell.hostedView = viewControllers[indexPath.item].view
        return cell
    }
}

extension ProfileContentViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let topHeight = profileView.headerView.bounds.height - view.safeAreaInsets.top + 16.0
        profileView.overlayScrollView.scrollIndicatorInsets = UIEdgeInsets(top: topHeight + profileView.categorySegmentedControl.frame.height, left: 0.0, bottom: 0.0, right: 0.0)

        let offsetY = scrollView.contentOffset.y
        contentOffsetsY[currentIndex] = offsetY

        if offsetY < topHeight {
            syncHeaderScroll(offsetY: offsetY)
        } else {
            syncPageScroll(offsetY: offsetY, topHeight: topHeight)
        }

        updateNavigationBarAlpha(with: profileView.containerScrollView.contentOffset.y / topHeight)
        applyHeaderImageTransformIfNeeded(for: offsetY)
        
        func syncHeaderScroll(offsetY: CGFloat) {
            profileView.containerScrollView.contentOffset.y = offsetY
            for viewController in viewControllers {
                (viewController.view as? UIScrollView)?.contentOffset = .zero
            }
            contentOffsetsY.removeAll()

            if profileView.headerView.isHidden {
                profileView.headerView.isHidden = false
                profileView.categorySegmentedControl.visualEffectView.isHidden = true
            }
        }
        
        func syncPageScroll(offsetY: CGFloat, topHeight: CGFloat) {
            profileView.containerScrollView.contentOffset.y = topHeight
            if let pageScrollView = viewControllers[currentIndex].view as? UIScrollView {
                pageScrollView.contentOffset.y = offsetY - topHeight
            }

            if !profileView.headerView.isHidden {
                profileView.headerView.isHidden = true
                profileView.categorySegmentedControl.visualEffectView.isHidden = false
            }
        }
        
        func updateNavigationBarAlpha(with progress: CGFloat) {
            guard let navigationBarBackgroundView else { return }
            navigationBarBackgroundView.alpha = clamp(progress, min: 0.0, max: 1.0)
        }
        
        func applyHeaderImageTransformIfNeeded(for offsetY: CGFloat) {
            guard offsetY < 0.0 else { return }

            let imageView = profileView.headerView.headerImageView
            let imageHeight = imageView.bounds.height
            let scaleFactor = offsetY / imageHeight
            let translateY = -(imageHeight * (1.0 - scaleFactor) - imageHeight) / 2.0

            var transform = CATransform3DIdentity
            transform = CATransform3DTranslate(transform, 0.0, translateY, 0.0)
            transform = CATransform3DScale(transform, 1.0 - scaleFactor, 1.0 - scaleFactor, 1.0)

            imageView.transform3D = transform
        }
    }
}

extension ProfileContentViewController {
    
    private func applySectionConfiguration() {
        switch sectionConfiguration.section {
        case let .withoutReplies(statuses):
            feedWithoutReplies.configuration = FeedContentViewController.Configuration(statuses: statuses, reloadData: sectionConfiguration.reloadData)
        case let .withoutReblogs(statuses):
            feedWithoutReblogs.configuration = FeedContentViewController.Configuration(statuses: statuses, reloadData: sectionConfiguration.reloadData)
        case let .withMediaOnly(statuses):
            feedWithMediaOnly.configuration = FeedContentViewController.Configuration(statuses: statuses, reloadData: sectionConfiguration.reloadData)
        case let .about(fields):
            aboutViewController.fields = fields
        }
    }
}

extension ProfileContentViewController {
    
    enum Section {
        case withoutReplies([Status])
        case withoutReblogs([Status])
        case withMediaOnly([Status])
        case about([Field])
    }
    
    struct SectionConfiguration {
        
        var section = Section.withoutReplies([])
        
        var reloadData = false
    }
}

extension ProfileContentViewController: FeedCollectionView.Observer {
    
    func feedCollectionView(_ collectionView: FeedCollectionView, didChangeContentSize contentSize: CGSize) {
        let newContentSize = recalculateContentSize(contentSize)
        profileView.overlayScrollView.contentSize = newContentSize
        profileView.containerScrollView.contentSize = newContentSize
    }
}
