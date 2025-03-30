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
import MastodonFeedDomain

protocol FeedContentViewControllerDelegate: AnyObject {
    
    func feedContentViewController(_ viewController: FeedContentViewController, didSelectImage image: UIImage)
    
    func feedContentViewController(_ viewController: FeedContentViewController, didSelectVideoWithURL url: URL, previewImage image: UIImage)
    
    func feedContentViewController(_ viewController: FeedContentViewController, didSelectURL url: URL)
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
    
    var configuration: Configuration = Configuration(statuses: []) {
        didSet { applyConfiguration() }
    }
    
    weak var delegate: (any FeedContentViewControllerDelegate)?
    
    private var selectionItem: SelectionItem?
    
    override func loadView() {
        view = collectionView
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        imageDownloader.clearCache()
    }
}

extension FeedContentViewController {
    
    private func applyConfiguration() {
        var snapshot = NSDiffableDataSourceSnapshot<Section, ItemIdentifier>()
        snapshot.appendSections([.main])
        snapshot.appendItems(configuration.statuses.map(\.id))
        dataSource.applySnapshotUsingReloadData(snapshot)
    }
}

extension FeedContentViewController {
    
    private func makeTextPostCellRegistration() -> UICollectionView.CellRegistration<TextPostCollectionViewCell, ItemIdentifier> {
        .init { [unowned self] cell, indexPath, itemIdentifier in
            cell.itemIdentifier = itemIdentifier
            cell.delegate = self
            
            let status = configuration.statuses[indexPath.item]
            let headerContentConfiguration = PostHeaderStackView.ContentConfiguration(
                displayName: status.account.displayName,
                time: relativeDateTimeFormatter.string(for: status.createdAt)!,
                username: status.account.username,
                eyeHidden: true
            )
            var previewCardConfiguration: PreviewCardView.Configuration?
            if let previewCard = status.previewCard {
                previewCardConfiguration = PreviewCardView.ContentConfiguration(
                    imageSize: CGSize(width: previewCard.width, height: previewCard.height),
                    title: previewCard.title,
                    description: previewCard.description,
                    providerHost: previewCard.url.host!
                )
            }
            
            let buttonsConfiguration = PostButtonsStackView.Configuration(
                repliesCount: status.repliesCount,
                reblogsCount: status.reblogsCount,
                favoritesCount: status.favouritesCount,
                buttonFlags: .init(reblogsButtonToggled: status.reblogged, favoritesButtonToggled: status.favourited)
            )
            var configuration = TextPostCollectionViewCell.Configuration(
                headerConfiguration: headerContentConfiguration,
                content: status.content,
                previewURL: status.previewCard?.url,
                previewCardConfiguration: previewCardConfiguration,
                buttonsConfiguration: buttonsConfiguration
            )
            
            cell.configuration = configuration
            
            Task {
                let image = try await imageDownloader.loadAnimatedImage(from: status.account.avatar)
                guard cell.itemIdentifier as? ItemIdentifier == itemIdentifier else { return }
                configuration.headerConfiguration = PostHeaderStackView.ImageConfiguration(avatarImage: image)
                cell.configuration = configuration
            }
            
            if let previewImageURL = status.previewCard?.imageURL {
                Task {
                    let image = try await imageDownloader.loadImage(from: previewImageURL)
                    guard cell.itemIdentifier as? ItemIdentifier == itemIdentifier else { return }
                    configuration.previewCardConfiguration = PreviewCardView.ImageConfiguration(image: image)
                    cell.configuration = configuration
                }
            }
        }
    }
    
    private func makeImageAttachmentCellRegistration() -> UICollectionView.CellRegistration<ImageAttachmentPostCollectionViewCell, ItemIdentifier> {
        .init { [unowned self] cell, indexPath, itemIdentifier in
            cell.itemIdentifier = itemIdentifier
            cell.delegate = self

            let status = configuration.statuses[indexPath.item]
            
            let headerContentConfiguration = PostHeaderStackView.ContentConfiguration(
                displayName: status.account.displayName,
                time: relativeDateTimeFormatter.string(for: status.createdAt)!,
                username: status.account.username,
                eyeHidden: true
            )
            
            let buttonsConfiguration = PostButtonsStackView.Configuration(
                repliesCount: status.repliesCount,
                reblogsCount: status.reblogsCount,
                favoritesCount: status.favouritesCount,
                buttonFlags: .init(reblogsButtonToggled: status.reblogged, favoritesButtonToggled: status.favourited)
            )
            
            let mediaAttachment = status.mediaAttachments.first!
            let singleImageAspectRatio = mediaAttachment.meta.original.width / mediaAttachment.meta.original.height
            var configuration = ImageAttachmentPostCollectionViewCell.Configuration(
                headerConfiguration: headerContentConfiguration,
                content: status.content,
                imageAttachmentMosaicStackViewConfiguration: ImageAttachmentMosaicStackView.PreparationConfiguration(singleImageAspectRatio: singleImageAspectRatio, imagesCount: status.mediaAttachments.count),
                buttonsConfiguration: buttonsConfiguration
            )
            cell.configuration = configuration
            
            Task {
                let image = try await imageDownloader.loadAnimatedImage(from: status.account.avatar)
                guard cell.itemIdentifier as? ItemIdentifier == itemIdentifier else { return }
                configuration.headerConfiguration = PostHeaderStackView.ImageConfiguration(avatarImage: image)
                cell.configuration = configuration
            }
            
            Task {
                let indexedImages = await withTaskGroup(of: (Int, UIImage?).self) { [weak imageDownloader] taskGroup in
                    guard let imageDownloader else { return [Int: UIImage?]() }
                    for (index, previewURL) in status.mediaAttachments.map(\.previewURL).enumerated() {
                        taskGroup.addTask { return (index, try? await imageDownloader.loadImage(from: previewURL)) }
                    }
                    return await taskGroup.reduce(into: [Int: UIImage?]()) { result, element in
                        result[element.0] = element.1
                    }
                }
                guard cell.itemIdentifier as? String == itemIdentifier else { return }
                let images = indexedImages
                    .sorted { $0.key < $1.key }
                    .map { $0.value }
                configuration.imageAttachmentMosaicStackViewConfiguration = ImageAttachmentMosaicStackView.ContentConfiguration(images: images)
                cell.configuration = configuration
            }
        }
    }
    
    private func makeVideoPreviewCellRegistration() -> UICollectionView.CellRegistration<VideoPreviewPostCollectionViewCell, ItemIdentifier> {
        .init { [unowned self] cell, indexPath, itemIdentifier in
            cell.itemIdentifier = itemIdentifier
            cell.delegate = self
            
            let status = configuration.statuses[indexPath.item]
            let headerContentConfiguration = PostHeaderStackView.ContentConfiguration(
                displayName: status.account.displayName,
                time: relativeDateTimeFormatter.string(for: status.createdAt)!,
                username: status.account.username,
                eyeHidden: true
            )
            let buttonsConfiguration = PostButtonsStackView.Configuration(
                repliesCount: status.repliesCount,
                reblogsCount: status.reblogsCount,
                favoritesCount: status.favouritesCount,
                buttonFlags: .init(reblogsButtonToggled: status.reblogged, favoritesButtonToggled: status.favourited)
            )
            
            let video = status.mediaAttachments.first!
            let videoPreviewViewConfiguration = VideoPreviewView.PreparationConfiguration(
                videoDuration: video.meta.original.duration!, 
                previewAspectRatio: video.meta.original.width / video.meta.original.height
            )
            
            var configuration = VideoPreviewPostCollectionViewCell.Configuration(
                headerConfiguration: headerContentConfiguration,
                content: status.content,
                videoPreviewViewConfiguration: videoPreviewViewConfiguration,
                buttonsConfiguration: buttonsConfiguration
            )
            cell.configuration = configuration
            
            Task {
                let image = try await imageDownloader.loadAnimatedImage(from: status.account.avatar)
                guard cell.itemIdentifier as? ItemIdentifier == itemIdentifier else { return }
                configuration.headerConfiguration = PostHeaderStackView.ImageConfiguration(avatarImage: image)
                cell.configuration = configuration
            }
            
            Task {
                let image = try? await imageDownloader.loadImage(from: video.previewURL)
                guard cell.itemIdentifier as? ItemIdentifier == itemIdentifier else { return }
                configuration.videoPreviewViewConfiguration = VideoPreviewView.ContentConfiguration(previewImage: image)
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
