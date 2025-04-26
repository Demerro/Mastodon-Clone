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
    
    func feedContentViewController(_ viewController: FeedContentViewController, didSelectTextURL textUrl: URL)
    
    func feedContentViewController(_ viewController: FeedContentViewController, didShareStatusURL statusUrl: URL)
    
    func feedContentViewControllerDidRefresh(_ viewController: FeedContentViewController)
    
    func feedContentViewControllerDidPagination(_ viewController: FeedContentViewController)
}

final class FeedContentViewController: ViewController {
    
    private let imageDownloader = ImageDownloader()
    
    private let favouritesStore = FavouritesStore()
    
    private var favouritesTask: Task<Void, Never>?
    
    private var favouritesTaskIsRunning = false
    
    private let reblogsStore = ReblogsStore()
    
    private var reblogsTask: Task<Void, Never>?
    
    private var reblogsTaskIsRunning = false
    
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
        collectionView.prefetchDataSource = self
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
    
    private func reconfigureItems(_ identifiers: [ItemIdentifier]) {
        var snapshot = dataSource.snapshot()
        snapshot.reconfigureItems(identifiers)
        dataSource.apply(snapshot)
    }
}

extension FeedContentViewController {
    
    private func makeTextPostCellRegistration() -> UICollectionView.CellRegistration<TextPostCollectionViewCell, ItemIdentifier> {
        .init { [unowned self] cell, indexPath, itemIdentifier in
            cell.itemIdentifier = itemIdentifier
            cell.delegate = self
            cell.layoutInvalidationDelegate = self
            cell.buttonsStackView.delegate = self
            
            let status = configuration.statuses[indexPath.item]
            let headerContentConfiguration = PostHeaderStackView.ContentConfiguration(
                displayName: status.account.displayName,
                time: relativeDateTimeFormatter.string(for: status.createdAt)!,
                username: status.account.username,
                eyeHidden: !status.sensitive
            )
            
            var buttonFlags = PostButtonsStackView.ButtonFlags()
            buttonFlags.reblogsButtonToggled = status.reblogged
            buttonFlags.favoritesButtonToggled = status.favourited
            var buttonsConfiguration = PostButtonsStackView.Configuration()
            buttonsConfiguration.repliesCount = status.repliesCount
            buttonsConfiguration.reblogsCount = status.reblogsCount
            buttonsConfiguration.favoritesCount = status.favouritesCount
            buttonsConfiguration.buttonFlags = buttonFlags
            
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
            cell.buttonsStackView.delegate = self

            let status = configuration.statuses[indexPath.item]
            
            let headerContentConfiguration = PostHeaderStackView.ContentConfiguration(
                displayName: status.account.displayName,
                time: relativeDateTimeFormatter.string(for: status.createdAt)!,
                username: status.account.username,
                eyeHidden: !status.sensitive
            )
            
            var buttonFlags = PostButtonsStackView.ButtonFlags()
            buttonFlags.reblogsButtonToggled = status.reblogged
            buttonFlags.favoritesButtonToggled = status.favourited
            var buttonsConfiguration = PostButtonsStackView.Configuration()
            buttonsConfiguration.repliesCount = status.repliesCount
            buttonsConfiguration.reblogsCount = status.reblogsCount
            buttonsConfiguration.favoritesCount = status.favouritesCount
            buttonsConfiguration.buttonFlags = buttonFlags
            
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
            cell.buttonsStackView.delegate = self
            
            let status = configuration.statuses[indexPath.item]
            
            let headerContentConfiguration = PostHeaderStackView.ContentConfiguration(
                displayName: status.account.displayName,
                time: relativeDateTimeFormatter.string(for: status.createdAt)!,
                username: status.account.username,
                eyeHidden: !status.sensitive
            )
            
            var buttonFlags = PostButtonsStackView.ButtonFlags()
            buttonFlags.reblogsButtonToggled = status.reblogged
            buttonFlags.favoritesButtonToggled = status.favourited
            var buttonsConfiguration = PostButtonsStackView.Configuration()
            buttonsConfiguration.repliesCount = status.repliesCount
            buttonsConfiguration.reblogsCount = status.reblogsCount
            buttonsConfiguration.favoritesCount = status.favouritesCount
            buttonsConfiguration.buttonFlags = buttonFlags
            
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
    
    struct Configuration {
        
        var statuses: [Status]
        
        let reloadData: Bool
    }
    
    private typealias ItemIdentifier = String
    
    private enum Section { case main }
}

extension FeedContentViewController: ImageAttachmentPostCollectionViewCellDelegate {
    
    func imageAttachmentPostCollectionViewCell(_ cell: ImageAttachmentPostCollectionViewCell, didSelectImageView imageView: UIImageView) {
        guard let image = imageView.image else { return }
        selectionItem = SelectionItem(view: imageView, image: image)
        delegate?.feedContentViewController(self, didSelectImage: image)
    }
    
    func imageAttachmentPostCollectionViewCell(_ cell: ImageAttachmentPostCollectionViewCell, didSelectURL url: URL) {
        delegate?.feedContentViewController(self, didSelectTextURL: url)
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
        delegate?.feedContentViewController(self, didSelectTextURL: url)
    }
}

extension FeedContentViewController: TextPostCollectionViewCellDelegate {
    
    func textPostCollectionViewCell(_ cell: TextPostCollectionViewCell, didSelectURL url: URL) {
        delegate?.feedContentViewController(self, didSelectTextURL: url)
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

extension FeedContentViewController: UICollectionViewDataSourcePrefetching {
    
    func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let status = configuration.statuses[indexPath.item]
            Task {
                async let avatarImage = imageDownloader.loadAnimatedImage(from: status.account.avatar)
                async let mediaAttachments = withTaskGroup(of: UIImage?.self, returning: [UIImage?].self) { [weak self] taskGroup in
                    guard let self else { return [] }
                    for url in status.mediaAttachments.map(\.url) {
                        taskGroup.addTask {
                            try? await self.imageDownloader.loadImage(from: url)
                        }
                    }
                    return await taskGroup.reduce(into: []) { $0.append($1) }
                }
                _ = try? await (avatarImage, mediaAttachments)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            let status = configuration.statuses[indexPath.item]
            imageDownloader.cancelDownloadingIfNeeded(for: status.account.avatar)
            status.mediaAttachments.lazy.map(\.url).forEach {
                imageDownloader.cancelDownloadingIfNeeded(for: $0)
            }
        }
    }
}

extension FeedContentViewController: PostButtonsStackViewDelegate {
    
    func postButtonsStackViewDidTapRepliesButton(_ stackView: PostButtonsStackView) {
    }
    
    func postButtonsStackViewDidTapReblogsButton(_ stackView: PostButtonsStackView, shouldReblog: Bool) {
        guard !reblogsTaskIsRunning else {
            reblogsTask?.cancel()
            return
        }
        guard let id = stackView.itemIdentifier as? ItemIdentifier else { return }
        reblogsTask = Task {
            reblogsTaskIsRunning = true; defer { reblogsTaskIsRunning = false }
            do {
                shouldReblog ? try await reblogsStore.reblogStatus(by: id) : try await reblogsStore.reblogStatus(by: id)
                var statuses = configuration.statuses
                guard let index = statuses.firstIndex(where: { $0.id == id }) else { return }
                var status = statuses[index]
                status.reblogged = shouldReblog
                status.reblogsCount += shouldReblog ? 1 : -1
                statuses[index] = status
                configuration = FeedContentViewController.Configuration(statuses: statuses, reloadData: false)
            } catch MastodonError.network(.clientOrTransportSpecific(URLError.cancelled)) {
                return
            } catch {
                reconfigureItems([id])
            }
        }
    }
    
    func postButtonsStackViewDidTapFavoritesButton(_ stackView: PostButtonsStackView, shouldFavourite: Bool) {
        guard !favouritesTaskIsRunning else {
            favouritesTask?.cancel()
            return
        }
        guard let id = stackView.itemIdentifier as? ItemIdentifier else { return }
        favouritesTask = Task {
            favouritesTaskIsRunning = true; defer { favouritesTaskIsRunning = false }
            do {
                shouldFavourite ? try await favouritesStore.favouriteStatus(by: id) : try await favouritesStore.unfavouriteStatus(by: id)
                var statuses = configuration.statuses
                guard let index = statuses.firstIndex(where: { $0.id == id }) else { return }
                var status = statuses[index]
                status.favourited = shouldFavourite
                status.favouritesCount += shouldFavourite ? 1 : -1
                statuses[index] = status
                configuration = FeedContentViewController.Configuration(statuses: statuses, reloadData: false)
            } catch MastodonError.network(.clientOrTransportSpecific(URLError.cancelled)) {
                return
            } catch {
                reconfigureItems([id])
            }
        }
    }
    
    func postButtonsStackViewDidTapShareButton(_ stackView: PostButtonsStackView) {
        guard let status = configuration.statuses.first(where: { $0.id == stackView.itemIdentifier as? ItemIdentifier }) else { return }
        delegate?.feedContentViewController(self, didShareStatusURL: status.url)
    }
}
