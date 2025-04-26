//
//  ImageAttachmentPostCollectionViewCell.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 4.02.25.
//

import UIKit
import UIKitFoundation
import UIKitUtilities

@MainActor
public protocol ImageAttachmentPostCollectionViewCellDelegate: AnyObject {
    
    func imageAttachmentPostCollectionViewCell(_ cell: ImageAttachmentPostCollectionViewCell, didSelectImageView imageView: UIImageView)
    
    func imageAttachmentPostCollectionViewCell(_ cell: ImageAttachmentPostCollectionViewCell, didSelectURL url: URL)
}

public final class ImageAttachmentPostCollectionViewCell: CollectionViewCell {
    
    public var itemIdentifier: AnyHashable? {
        didSet { buttonsStackView.itemIdentifier = itemIdentifier }
    }
    
    internal let headerStackView: PostHeaderStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(PostHeaderStackView(frame: .zero))
    
    internal let contentTextView: UITextView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.textContainerInset = .zero
        $0.isScrollEnabled = false
        $0.isEditable = false
        $0.dataDetectorTypes = .link
        $0.font = .preferredFont(forTextStyle: .body)
        $0.showsHorizontalScrollIndicator = false
        $0.showsVerticalScrollIndicator = false
        $0.textContainer.lineFragmentPadding = .zero
        return $0
    }(UITextView(frame: .zero))
    
    internal let imageAttachmentMosaicStackView: ImageAttachmentMosaicStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(ImageAttachmentMosaicStackView(frame: .zero))
    
    public let buttonsStackView: PostButtonsStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(PostButtonsStackView(frame: .zero))
    
    internal let spoilerView: SpoilerView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(SpoilerView(frame: .zero))
    
    private var layoutManager: ImageAttachmentPostCollectionViewCellLayoutManager!
    
    private var currentAnimator: UIViewPropertyAnimator?
    
    private var needsApplyConfiguration = false
    
    public var configuration = Configuration() {
        didSet { setNeedsApplyConfiguration() }
    }
    
    public weak var delegate: (any ImageAttachmentPostCollectionViewCellDelegate)?
    
    public weak var layoutInvalidationDelegate: (any LayoutInvalidationDelegate)?
    
    public override func setupCommon() {
        super.setupCommon()
        layoutManager = ImageAttachmentPostCollectionViewCellLayoutManager(cell: self)
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer)))
        contentTextView.delegate = self
        headerStackView.delegate = self
    }
    
    public override func updateConstraints() {
        applyConfigurationIfNeeded()
        super.updateConstraints()
    }
    
    public override func prepareForReuse() {
        itemIdentifier = nil
        buttonsStackView.itemIdentifier = nil
        configuration = Configuration()
        applyConfigurationIfNeeded()
        super.prepareForReuse()
    }
}

extension ImageAttachmentPostCollectionViewCell {
    
    private func setNeedsApplyConfiguration() {
        guard !needsApplyConfiguration else { return }
        needsApplyConfiguration = true
        setNeedsUpdateConstraints()
    }
    
    private func applyConfigurationIfNeeded() {
        guard needsApplyConfiguration else { return }
        needsApplyConfiguration = false
        applyConfiguration()
        layoutIfNeeded()
    }
    
    private func applyConfiguration() {
        headerStackView.configuration = configuration.headerConfiguration
        contentTextView.text = configuration.content
        imageAttachmentMosaicStackView.configuration = configuration.imageAttachmentMosaicStackViewConfiguration
        buttonsStackView.configuration = configuration.buttonsConfiguration
        spoilerView.configuration = configuration.spoilerConfiguration
        
        let hasSpoiler = configuration.spoilerConfiguration.text != nil
        spoilerView.alpha = hasSpoiler ? 1.0 : 0.0
        contentTextView.alpha = hasSpoiler ? 0.0 : 1.0
        imageAttachmentMosaicStackView.alpha = hasSpoiler ? 0.0 : 1.0
        
        layoutManager.isSpoilerVisible = hasSpoiler
        layoutManager.layout()
    }
}

extension ImageAttachmentPostCollectionViewCell {
    
    @objc
    private func handleTapGestureRecognizer(_ gestureRecognizer: UITapGestureRecognizer) {
        let location = gestureRecognizer.location(in: contentView)
        if !spoilerView.isHidden, spoilerView.frame.contains(location) {
            headerStackView.toggleEye()
            layoutManager.isSpoilerVisible.toggle()
            layoutManager.layout()
            layoutManager.isSpoilerVisible ? animateSpoilerAppearance() : animateContentAppearance()
            layoutInvalidationDelegate?.invalidateLayout(self)
        } else if let imageView = imageAttachmentMosaicStackView.imageViews.first(where: { $0.superview!.convert($0.frame, to: contentView).contains(location) }) {
            delegate?.imageAttachmentPostCollectionViewCell(self, didSelectImageView: imageView)
        }
    }
}

extension ImageAttachmentPostCollectionViewCell {
    
    private func animateContentAppearance() {
        currentAnimator?.stopAnimation(true)
        currentAnimator = UIViewPropertyAnimator(duration: 0.0, timingParameters: UISpringTimingParameters(dampingRatio: 0.825, frequencyResponse: 0.3))
        currentAnimator!.addAnimations { [unowned self] in
            spoilerView.alpha = 0.0
            contentTextView.alpha = 1.0
            imageAttachmentMosaicStackView.alpha = 1.0
        }
        currentAnimator!.startAnimation()
    }
    
    private func animateSpoilerAppearance() {
        currentAnimator?.stopAnimation(true)
        currentAnimator = UIViewPropertyAnimator(duration: 0.0, timingParameters: UISpringTimingParameters(dampingRatio: 0.825, frequencyResponse: 0.3))
        currentAnimator!.addAnimations { [unowned self] in
            spoilerView.alpha = 1.0
            contentTextView.alpha = 0.0
            imageAttachmentMosaicStackView.alpha = 0.0
        }
        currentAnimator!.startAnimation()
    }
}

extension ImageAttachmentPostCollectionViewCell: UITextViewDelegate {
    
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        delegate?.imageAttachmentPostCollectionViewCell(self, didSelectURL: URL)
        return false
    }
}

extension ImageAttachmentPostCollectionViewCell: PostHeaderStackViewDelegate {
    
    public func postHeaderStackViewDidTapEyeButton(_ stackView: PostHeaderStackView) {
        layoutManager.isSpoilerVisible.toggle()
        layoutManager.layout()
        layoutManager.isSpoilerVisible ? animateSpoilerAppearance() : animateContentAppearance()
        layoutInvalidationDelegate?.invalidateLayout(self)
    }
}

extension ImageAttachmentPostCollectionViewCell {
    
    public struct Configuration {
        
        public var headerConfiguration: PostHeaderStackView.Configuration = PostHeaderStackView.EmptyConfiguration()
        
        public var content: String?
        
        public var imageAttachmentMosaicStackViewConfiguration: ImageAttachmentMosaicStackView.Configuration = ImageAttachmentMosaicStackView.EmptyConfiguration()
        
        public var spoilerConfiguration = SpoilerView.Configuration()
        
        public var buttonsConfiguration = PostButtonsStackView.Configuration()
        
        public init() {
        }
    }
}
