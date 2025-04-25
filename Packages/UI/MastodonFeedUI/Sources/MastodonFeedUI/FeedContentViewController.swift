//
//  FeedContentViewController.swift
//  MastodonFeedUI
//
//  Created by Nikita Prokhorchuk on 25.01.25.
//

import UIKit
import UIKitFoundation
import MastodonUtilities
import MastodonSharedUI
import MastodonKit

@MainActor
protocol FeedContentViewControllerDelegate: AnyObject {
    
    func feedContentViewController(_ viewController: FeedContentViewController, didSelectImage image: UIImage)
    
    func feedContentViewController(_ viewController: FeedContentViewController, didSelectVideoWithURL url: URL, previewImage image: UIImage)
    
    func feedContentViewController(_ viewController: FeedContentViewController, didSelectURL url: URL)
    
    func feedContentViewControllerDidRefresh(_ viewController: FeedContentViewController)
    
    func feedContentViewControllerDidPagination(_ viewController: FeedContentViewController)
}

final class FeedContentViewController: ViewController {
    
    private let imageDownloader = ImageDownloader()
    
    let collectionView: UICollectionView = {
        let listLayout = UICollectionViewCompositionalLayout.list(using: .init(appearance: .plain))
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: listLayout)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delaysContentTouches = false
        return collectionView
    }()
    
    private let relativeDateTimeFormatter: RelativeDateTimeFormatter = {
        $0.unitsStyle = .abbreviated
        return $0
    }(RelativeDateTimeFormatter())
    
    private lazy var dataSource = makeDataSource()
    
    var configuration: Configuration = Configuration(statuses: [], reloadData: true) {
        didSet { applyConfiguration() }
    }
    
    weak var delegate: (any FeedContentViewControllerDelegate)?
    
    private var selectionItem: SelectionItem?
    
    override func setupCommon() {
        collectionView.delegate = self
        collectionView.refreshControl = UIRefreshControl(frame: .zero, primaryAction: UIAction { [unowned self] _ in
            delegate?.feedContentViewControllerDidRefresh(self)
        })
    }
    
    override func loadView() {
        view = collectionView
    }
}

extension FeedContentViewController {
    
    private func applyConfiguration() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, ItemIdentifier>()
        snapshot.appendSections([.main])
        snapshot.appendItems(configuration.statuses.map(\.id))
        if configuration.reloadData {
            dataSource.applySnapshotUsingReloadData(snapshot)
            if !configuration.statuses.isEmpty {
                collectionView.scrollToItem(at: [0, 0], at: .top, animated: false)
            }
        } else {
            dataSource.apply(snapshot)
        }
    }
}

extension FeedContentViewController {
    
    private func makeTextPostCellRegistration() -> UICollectionView.CellRegistration<TextPostCollectionViewCell, ItemIdentifier> {
        .init { [unowned self] cell, indexPath, itemIdentifier in
            cell.itemIdentifier = itemIdentifier
            cell.delegate = self
            cell.layoutInvalidationDelegate = self
            
            let status = configuration.statuses[indexPath.item]
            let headerContentConfiguration = PostHeaderStackView.ContentConfiguration(
                displayName: status.account.displayName,
                time: relativeDateTimeFormatter.string(for: status.createdAt)!,
                username: status.account.username,
                eyeHidden: !status.sensitive
            )
            
            let buttonsConfiguration = PostButtonsStackView.Configuration(
                repliesCount: status.repliesCount,
                reblogsCount: status.reblogsCount,
                favoritesCount: status.favouritesCount,
                buttonFlags: .init(reblogsButtonToggled: status.reblogged, favoritesButtonToggled: status.favourited)
            )
            
            var spoilerConfiguration = SpoilerView.Configuration()
            spoilerConfiguration.text = status.sensitive ? status.spoilerText : nil
            
            var configuration = TextPostCollectionViewCell.Configuration()
            configuration.headerConfiguration = headerContentConfiguration
            configuration.content = status.content
            configuration.previewURL = status.previewCard?.url
            configuration.spoilerConfiguration = spoilerConfiguration
            configuration.buttonsConfiguration = buttonsConfiguration
            
            if let previewCard = status.previewCard {
                configuration.previewCardConfiguration = PreviewCardView.ContentConfiguration(
                    imageSize: CGSize(width: previewCard.width, height: previewCard.height),
                    title: previewCard.title,
                    description: previewCard.description,
                    providerHost: previewCard.url.host!
                )
            }
            
            cell.configuration = configuration
            
            Task {
                async let avatarImage = imageDownloader.loadAnimatedImage(from: status.account.avatar)
                if let previewImageURL = status.previewCard?.imageURL {
                    async let previewImage = imageDownloader.loadImage(from: previewImageURL)
                    let (downloadedAvatarImage, downloadedPreviewImage) = try await (avatarImage, previewImage)
                    guard cell.itemIdentifier as? ItemIdentifier == itemIdentifier else { return }
                    configuration.headerConfiguration = PostHeaderStackView.ImageConfiguration(avatarImage: downloadedAvatarImage)
                    configuration.previewCardConfiguration = PreviewCardView.ImageConfiguration(image: downloadedPreviewImage)
                } else {
                    let downloadedAvatarImage = try await avatarImage
                    guard cell.itemIdentifier as? ItemIdentifier == itemIdentifier else { return }
                    configuration.headerConfiguration = PostHeaderStackView.ImageConfiguration(avatarImage: downloadedAvatarImage)
                }
                cell.configuration = configuration
            }
        }
    }
    
    private func makeImageAttachmentCellRegistration() -> UICollectionView.CellRegistration<ImageAttachmentPostCollectionViewCell, ItemIdentifier> {
        return .init { [unowned self] cell, indexPath, itemIdentifier in
            cell.itemIdentifier = itemIdentifier
            cell.delegate = self
            cell.layoutInvalidationDelegate = self

            let status = configuration.statuses[indexPath.item]
            
            let headerContentConfiguration = PostHeaderStackView.ContentConfiguration(
                displayName: status.account.displayName,
                time: relativeDateTimeFormatter.string(for: status.createdAt)!,
                username: status.account.username,
                eyeHidden: !status.sensitive
            )
            
            let buttonsConfiguration = PostButtonsStackView.Configuration(
                repliesCount: status.repliesCount,
                reblogsCount: status.reblogsCount,
                favoritesCount: status.favouritesCount,
                buttonFlags: .init(reblogsButtonToggled: status.reblogged, favoritesButtonToggled: status.favourited)
            )
            
            let mediaAttachment = status.mediaAttachments.first!
            let imageAttachmentPreparationConfiguration = ImageAttachmentMosaicStackView.PreparationConfiguration(
                singleImageAspectRatio: mediaAttachment.meta!.original.width / mediaAttachment.meta!.original.height,
                imagesCount: status.mediaAttachments.count
            )
            
            var spoilerConfiguration = SpoilerView.Configuration()
            spoilerConfiguration.text = status.sensitive ? status.spoilerText : nil
            if status.sensitive {
                spoilerConfiguration.imageAttachmentMosaicStackViewConfiguration = imageAttachmentPreparationConfiguration
            }
            
            var configuration = ImageAttachmentPostCollectionViewCell.Configuration()
            configuration.headerConfiguration = headerContentConfiguration
            configuration.content = status.content
            configuration.imageAttachmentMosaicStackViewConfiguration = imageAttachmentPreparationConfiguration
            configuration.spoilerConfiguration = spoilerConfiguration
            configuration.buttonsConfiguration = buttonsConfiguration
            
            cell.configuration = configuration
            
            Task {
                async let avatarImage = imageDownloader.loadAnimatedImage(from: status.account.avatar)
                async let images = loadImages(from: status.mediaAttachments.map(\.previewURL))
                async let spoilerBlurhashes: [UIImage?] = if status.sensitive {
                    loadBlurHashImages(from: status.mediaAttachments)
                } else {
                    []
                }
                let (loadedSpoilerBlurhashes, downloadedAvatarImage, downloadedImages) = try await (spoilerBlurhashes, avatarImage, images)
                guard cell.itemIdentifier as? String == itemIdentifier else { return }
                configuration.headerConfiguration = PostHeaderStackView.ImageConfiguration(avatarImage: downloadedAvatarImage)
                configuration.imageAttachmentMosaicStackViewConfiguration = ImageAttachmentMosaicStackView.ContentConfiguration(images: downloadedImages)
                configuration.spoilerConfiguration.imageAttachmentMosaicStackViewConfiguration = ImageAttachmentMosaicStackView.ContentConfiguration(images: loadedSpoilerBlurhashes)
                cell.configuration = configuration
            }
        }
        
        @Sendable func loadImages(from urls: [URL]) async -> [UIImage?] {
            await withTaskGroup(of: (Int, UIImage?).self) { [weak self] taskGroup in
                guard let self else { return [] }
                for (index, url) in urls.enumerated() {
                    taskGroup.addTask {
                        (index, try? await self.imageDownloader.loadImage(from: url))
                    }
                }

                return await taskGroup
                    .reduce(into: [Int: UIImage?]()) { $0[$1.0] = $1.1 }
                    .lazy
                    .sorted { $0.key < $1.key }
                    .map { $0.value }
            }
        }

        @Sendable func loadBlurHashImages(from attachments: [MediaAttachment]) async -> [UIImage?] {
            await withTaskGroup(of: (Int, UIImage?).self) { taskGroup in
                for (index, attachment) in attachments.enumerated() {
                    taskGroup.addTask {
                        let image: UIImage? = {
                            guard let blurHash = attachment.blurHash,
                                  let meta = attachment.meta else { return nil }
                            return UIImage(blurHash: blurHash, size: CGSize(width: meta.small.width, height: meta.small.height))
                        }()
                        return (index, image)
                    }
                }

                return await taskGroup
                    .reduce(into: [Int: UIImage?]()) { $0[$1.0] = $1.1 }
                    .lazy
                    .sorted { $0.key < $1.key }
                    .map { $0.value }
            }
        }
    }
    
    private func makeVideoPreviewCellRegistration() -> UICollectionView.CellRegistration<VideoPreviewPostCollectionViewCell, ItemIdentifier> {
        .init { [unowned self] cell, indexPath, itemIdentifier in
            cell.itemIdentifier = itemIdentifier
            cell.delegate = self
            cell.layoutInvalidationDelegate = self
            
            let status = configuration.statuses[indexPath.item]
            let headerContentConfiguration = PostHeaderStackView.ContentConfiguration(
                displayName: status.account.displayName,
                time: relativeDateTimeFormatter.string(for: status.createdAt)!,
                username: status.account.username,
                eyeHidden: !status.sensitive
            )
            let buttonsConfiguration = PostButtonsStackView.Configuration(
                repliesCount: status.repliesCount,
                reblogsCount: status.reblogsCount,
                favoritesCount: status.favouritesCount,
                buttonFlags: .init(reblogsButtonToggled: status.reblogged, favoritesButtonToggled: status.favourited)
            )
            
            let video = status.mediaAttachments.first!
            let previewAspectRatio = video.meta!.original.width / video.meta!.original.height
            let videoPreviewViewConfiguration = VideoPreviewView.PreparationConfiguration(
                videoDuration: video.meta!.original.duration!,
                previewAspectRatio: previewAspectRatio
            )
            
            var spoilerConfiguration = SpoilerView.Configuration()
            spoilerConfiguration.text = status.sensitive ? status.spoilerText : nil
            if status.sensitive {
                spoilerConfiguration.imageAttachmentMosaicStackViewConfiguration = ImageAttachmentMosaicStackView.PreparationConfiguration(singleImageAspectRatio: previewAspectRatio, imagesCount: 1)
            }
            
            var configuration = VideoPreviewPostCollectionViewCell.Configuration()
            configuration.headerConfiguration = headerContentConfiguration
            configuration.content = status.content
            configuration.videoPreviewViewConfiguration = videoPreviewViewConfiguration
            configuration.spoilerConfiguration = spoilerConfiguration
            configuration.buttonsConfiguration = buttonsConfiguration
            
            cell.configuration = configuration
            
            Task {
                async let avatarImage = imageDownloader.loadAnimatedImage(from: status.account.avatar)
                async let previewImage = imageDownloader.loadImage(from: video.previewURL)
                let blurhashImage: UIImage? = if status.sensitive, let blurHash = video.blurHash, let meta = video.meta {
                    UIImage(blurHash: blurHash, size: CGSize(width: meta.small.width, height: meta.small.height))
                } else {
                    nil
                }
                let (downloadedAvatarImage, downloadedPreviewImage) = try await (avatarImage, previewImage)
                guard cell.itemIdentifier as? ItemIdentifier == itemIdentifier else { return }
                configuration.headerConfiguration = PostHeaderStackView.ImageConfiguration(avatarImage: downloadedAvatarImage)
                configuration.videoPreviewViewConfiguration = VideoPreviewView.ContentConfiguration(previewImage: downloadedPreviewImage)
                configuration.spoilerConfiguration.imageAttachmentMosaicStackViewConfiguration = ImageAttachmentMosaicStackView.ContentConfiguration(images: [blurhashImage])
                cell.configuration = configuration
            }
        }
    }
    
    private func makeDataSource() -> UICollectionViewDiffableDataSource<Section, ItemIdentifier> {
        let textPostCellRegistration = makeTextPostCellRegistration()
        let imageAttachmentCellRegistration = makeImageAttachmentCellRegistration()
        let videoCellRegistration = makeVideoPreviewCellRegistration()
        return .init(collectionView: collectionView) { [unowned self] collectionView, indexPath, itemIdentifier in
            if let mediaAttachment = configuration.statuses[indexPath.item].mediaAttachments.first {
                switch mediaAttachment.type {
                case .image:
                    collectionView.dequeueConfiguredReusableCell(using: imageAttachmentCellRegistration, for: indexPath, item: itemIdentifier)
                case .video:
                    collectionView.dequeueConfiguredReusableCell(using: videoCellRegistration, for: indexPath, item: itemIdentifier)
                default:
                    collectionView.dequeueConfiguredReusableCell(using: textPostCellRegistration, for: indexPath, item: itemIdentifier)
                }
            } else {
                collectionView.dequeueConfiguredReusableCell(using: textPostCellRegistration, for: indexPath, item: itemIdentifier)
            }
        }
    }
}

extension FeedContentViewController {
    
    private typealias ItemIdentifier = String
    
    private enum Section { case main }
}

extension FeedContentViewController {
    
    struct Configuration {
        
        let statuses: [Status]
        
        let reloadData: Bool
    }
}

extension FeedContentViewController: ImageAttachmentPostCollectionViewCellDelegate {
    
    func imageAttachmentPostCollectionViewCell(_ cell: ImageAttachmentPostCollectionViewCell, didSelectImageView imageView: UIImageView) {
        let image = imageView.image!
        selectionItem = SelectionItem(view: imageView, image: image)
        delegate?.feedContentViewController(self, didSelectImage: image)
    }
    
    func imageAttachmentPostCollectionViewCell(_ cell: ImageAttachmentPostCollectionViewCell, didSelectURL url: URL) {
        delegate?.feedContentViewController(self, didSelectURL: url)
    }
}

extension FeedContentViewController: VideoPreviewPostCollectionViewCellDelegate {
    
    func videoPreviewPostCollectionViewCell(_ cell: VideoPreviewPostCollectionViewCell, didSelectImageView imageView: UIImageView) {
        if let status = configuration.statuses.first(where: { $0.id == cell.itemIdentifier as? ItemIdentifier }),
           let videoAttachment = status.mediaAttachments.first {
            let image = imageView.image!
            selectionItem = SelectionItem(view: cell.videoPreviewView, image: image)
            delegate?.feedContentViewController(self, didSelectVideoWithURL: videoAttachment.url, previewImage: image)
        }
    }
    
    func videoPreviewPostCollectionViewCell(_ cell: VideoPreviewPostCollectionViewCell, didSelectURL url: URL) {
        delegate?.feedContentViewController(self, didSelectURL: url)
    }
}

extension FeedContentViewController: TextPostCollectionViewCellDelegate {
    
    func textPostCollectionViewCell(_ cell: TextPostCollectionViewCell, didSelectURL url: URL) {
        delegate?.feedContentViewController(self, didSelectURL: url)
    }
}

extension FeedContentViewController {
    
    private struct SelectionItem {
        
        let view: UIView
        
        let image: UIImage
    }
}

extension FeedContentViewController: ImageAnimationTransitioningDelegate {
    
    func willTransitionItem() {
        guard let selectionItem else { return }
        selectionItem.view.alpha = 0.0
    }
    
    var item: TransitionItem? {
        if let selectionItem {
            TransitionItem(image: selectionItem.image, cornerRadius: selectionItem.view.layer.cornerRadius)
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

extension FeedContentViewController: LayoutInvalidationDelegate {
    
    func invalidateLayout(_ cell: UICollectionViewCell) {
        let context = UICollectionViewLayoutInvalidationContext()
        context.invalidateItems(at: [collectionView.indexPath(for: cell)!])
        collectionView.collectionViewLayout.invalidateLayout(with: context)
        let animator = UIViewPropertyAnimator(duration: 0.0, timingParameters: UISpringTimingParameters(dampingRatio: 0.825, frequencyResponse: 0.3))
        animator.addAnimations { [collectionView] in
            collectionView.layoutIfNeeded()
        }
        animator.startAnimation()
    }
}

extension FeedContentViewController: UICollectionViewDelegate {
}

extension FeedContentViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.frame.height - 100.0 else { return }
        delegate?.feedContentViewControllerDidPagination(self)
    }
}
