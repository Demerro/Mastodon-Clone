//
//  FeedContentViewController.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 25.01.25.
//

import UIKit
import UIKitFoundation
import MastodonUtilities
import MastodonKit

@MainActor
public protocol FeedContentViewControllerDelegate: AnyObject {
    
    func feedContentViewController(_ viewController: FeedContentViewController, didSelectImageView imageView: UIImageView)
    
    func feedContentViewController(_ viewController: FeedContentViewController, didSelectVideoWithURL url: URL, selectionItem: SelectionItem)
    
    func feedContentViewController(_ viewController: FeedContentViewController, didSelectTextURL textUrl: URL)
    
    func feedContentViewController(_ viewController: FeedContentViewController, didShareStatusURL statusUrl: URL)
    
    func feedContentViewControllerDidPagination(_ viewController: FeedContentViewController)
}

public final class FeedContentViewController: ViewController {
    
    private let favouritesStore = FavouritesStore()
    
    private var favouritesTask: Task<Void, Never>?
    
    private var favouritesTaskIsRunning = false
    
    private let reblogsStore = ReblogsStore()
    
    private var reblogsTask: Task<Void, Never>?
    
    private var reblogsTaskIsRunning = false
    
    public let collectionView: FeedCollectionView = {
        let listLayout = UICollectionViewCompositionalLayout.list(using: .init(appearance: .plain))
        let collectionView = FeedCollectionView(frame: .zero, collectionViewLayout: listLayout)
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
    
    public var configuration: Configuration = Configuration(statuses: [], reloadData: true) {
        didSet { applyConfiguration() }
    }
    
    public weak var delegate: (any FeedContentViewControllerDelegate)?
    
    public override func setupCommon() {
        collectionView.delegate = self
        collectionView.prefetchDataSource = self
    }
    
    public override func loadView() {
        view = collectionView
    }
}

extension FeedContentViewController {
    
    private func applyConfiguration() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, ItemIdentifier>()
        snapshot.appendSections([.main])
        snapshot.appendItems(configuration.statuses.map(\.id))
        if configuration.reloadData {
            dataSource.applySnapshotUsingReloadData(snapshot) { [unowned self] in
                collectionView.flashScrollIndicators()
                if !configuration.statuses.isEmpty {
                    collectionView.scrollToItem(at: [0, 0], at: .top, animated: false)
                }
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
            
            Task.detached {
                async let avatarImage = ImageDownloader.shared.loadAnimatedImage(from: status.account.avatar)
                if let previewImageURL = status.previewCard?.imageURL {
                    async let previewImage = ImageDownloader.shared.loadImage(from: previewImageURL)
                    let (downloadedAvatarImage, downloadedPreviewImage) = try await (avatarImage, previewImage)
                    guard await cell.itemIdentifier as? ItemIdentifier == itemIdentifier else { return }
                    configuration.headerConfiguration = PostHeaderStackView.ImageConfiguration(avatarImage: downloadedAvatarImage)
                    configuration.previewCardConfiguration = PreviewCardView.ImageConfiguration(image: downloadedPreviewImage)
                } else {
                    let downloadedAvatarImage = try await avatarImage
                    guard await cell.itemIdentifier as? ItemIdentifier == itemIdentifier else { return }
                    configuration.headerConfiguration = PostHeaderStackView.ImageConfiguration(avatarImage: downloadedAvatarImage)
                }
                await MainActor.run {
                    cell.configuration = configuration
                }
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
            
            Task.detached {
                async let avatarImage = ImageDownloader.shared.loadAnimatedImage(from: status.account.avatar)
                async let images = loadImages(from: status.mediaAttachments.map(\.previewURL))
                async let spoilerBlurhashes: [UIImage?] = if status.sensitive {
                    loadBlurHashImages(from: status.mediaAttachments)
                } else {
                    []
                }
                let (loadedSpoilerBlurhashes, downloadedAvatarImage, downloadedImages) = try await (spoilerBlurhashes, avatarImage, images)
                guard await cell.itemIdentifier as? String == itemIdentifier else { return }
                configuration.headerConfiguration = PostHeaderStackView.ImageConfiguration(avatarImage: downloadedAvatarImage)
                configuration.imageAttachmentMosaicStackViewConfiguration = ImageAttachmentMosaicStackView.ContentConfiguration(images: downloadedImages)
                configuration.spoilerConfiguration.imageAttachmentMosaicStackViewConfiguration = ImageAttachmentMosaicStackView.ContentConfiguration(images: loadedSpoilerBlurhashes)
                await MainActor.run {
                    cell.configuration = configuration
                }
            }
        }
        
        @Sendable func loadImages(from urls: [URL]) async -> [UIImage?] {
            await withTaskGroup(of: (Int, UIImage?).self) { taskGroup in
                for (index, url) in urls.enumerated() {
                    taskGroup.addTask {
                        (index, try? await ImageDownloader.shared.loadImage(from: url))
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
            
            Task.detached {
                async let avatarImage = ImageDownloader.shared.loadAnimatedImage(from: status.account.avatar)
                async let previewImage = ImageDownloader.shared.loadImage(from: video.previewURL)
                if status.sensitive, let blurHash = video.blurHash, let meta = video.meta, let blurhashImage = UIImage(blurHash: blurHash, size: CGSize(width: meta.small.width, height: meta.small.height)) {
                    configuration.spoilerConfiguration.imageAttachmentMosaicStackViewConfiguration = ImageAttachmentMosaicStackView.ContentConfiguration(images: [blurhashImage])
                }
                let (downloadedAvatarImage, downloadedPreviewImage) = try await (avatarImage, previewImage)
                guard await cell.itemIdentifier as? ItemIdentifier == itemIdentifier else { return }
                configuration.headerConfiguration = PostHeaderStackView.ImageConfiguration(avatarImage: downloadedAvatarImage)
                configuration.videoPreviewViewConfiguration = VideoPreviewView.ContentConfiguration(previewImage: downloadedPreviewImage)
                await MainActor.run {
                    cell.configuration = configuration
                }
            }
        }
    }
}

extension FeedContentViewController {
    
    public struct Configuration {
        
        public var statuses: [Status]
        
        public let reloadData: Bool
        
        public init(statuses: [Status], reloadData: Bool) {
            self.statuses = statuses
            self.reloadData = reloadData
        }
    }
    
    private typealias ItemIdentifier = String
    
    private enum Section { case main }
}

extension FeedContentViewController: ImageAttachmentPostCollectionViewCellDelegate {
    
    public func imageAttachmentPostCollectionViewCell(_ cell: ImageAttachmentPostCollectionViewCell, didSelectImageView imageView: UIImageView) {
        delegate?.feedContentViewController(self, didSelectImageView: imageView)
    }
    
    public func imageAttachmentPostCollectionViewCell(_ cell: ImageAttachmentPostCollectionViewCell, didSelectURL url: URL) {
        delegate?.feedContentViewController(self, didSelectTextURL: url)
    }
}

extension FeedContentViewController: VideoPreviewPostCollectionViewCellDelegate {
    
    public func videoPreviewPostCollectionViewCell(_ cell: VideoPreviewPostCollectionViewCell, didSelectImageView imageView: UIImageView) {
        if let status = configuration.statuses.first(where: { $0.id == cell.itemIdentifier as? ItemIdentifier }),
           let videoAttachmentURL = status.mediaAttachments.first?.url {
            let selectionItem = SelectionItem(view: cell.videoPreviewView, image: imageView.image!)
            delegate?.feedContentViewController(self, didSelectVideoWithURL: videoAttachmentURL, selectionItem: selectionItem)
        }
    }
    
    public func videoPreviewPostCollectionViewCell(_ cell: VideoPreviewPostCollectionViewCell, didSelectURL url: URL) {
        delegate?.feedContentViewController(self, didSelectTextURL: url)
    }
}

extension FeedContentViewController: TextPostCollectionViewCellDelegate {
    
    public func textPostCollectionViewCell(_ cell: TextPostCollectionViewCell, didSelectURL url: URL) {
        delegate?.feedContentViewController(self, didSelectTextURL: url)
    }
}

extension FeedContentViewController: LayoutInvalidationDelegate {
    
    public func invalidateLayout(_ cell: UICollectionViewCell) {
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
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.contentOffset.y > scrollView.contentSize.height - scrollView.frame.height - 100.0 else { return }
        delegate?.feedContentViewControllerDidPagination(self)
    }
}

extension FeedContentViewController: UICollectionViewDataSourcePrefetching {
    
    public func collectionView(_ collectionView: UICollectionView, prefetchItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            guard indexPath.item < configuration.statuses.count else { continue }
            let status = configuration.statuses[indexPath.item]
            Task {
                async let avatarImage = ImageDownloader.shared.loadAnimatedImage(from: status.account.avatar)
                async let mediaAttachments = withTaskGroup(of: UIImage?.self, returning: [UIImage?].self) { taskGroup in
                    for url in status.mediaAttachments.compactMap(\.url) {
                        taskGroup.addTask {
                            try? await ImageDownloader.shared.loadImage(from: url)
                        }
                    }
                    return await taskGroup.reduce(into: []) { $0.append($1) }
                }
                _ = try? await (avatarImage, mediaAttachments)
            }
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
        for indexPath in indexPaths {
            guard indexPath.item < configuration.statuses.count else { continue }
            let status = configuration.statuses[indexPath.item]
            ImageDownloader.shared.cancelDownloadingIfNeeded(for: status.account.avatar)
            for url in status.mediaAttachments.compactMap(\.url) {
                ImageDownloader.shared.cancelDownloadingIfNeeded(for: url)
            }
        }
    }
}

extension FeedContentViewController: PostButtonsStackViewDelegate {
    
    public func postButtonsStackViewDidTapRepliesButton(_ stackView: PostButtonsStackView) {
    }
    
    public func postButtonsStackViewDidTapReblogsButton(_ stackView: PostButtonsStackView, shouldReblog: Bool) {
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
    
    public func postButtonsStackViewDidTapFavoritesButton(_ stackView: PostButtonsStackView, shouldFavourite: Bool) {
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
    
    public func postButtonsStackViewDidTapShareButton(_ stackView: PostButtonsStackView) {
        guard let status = configuration.statuses.first(where: { $0.id == stackView.itemIdentifier as? ItemIdentifier }) else { return }
        delegate?.feedContentViewController(self, didShareStatusURL: status.url)
    }
}
