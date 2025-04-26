//
//  VideoPreviewPostCollectionViewCell.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 12.02.25.
//

import UIKit
import UIKitFoundation
import UIKitUtilities

@MainActor
public protocol VideoPreviewPostCollectionViewCellDelegate: AnyObject {
    
    func videoPreviewPostCollectionViewCell(_ cell: VideoPreviewPostCollectionViewCell, didSelectImageView imageView: UIImageView)
    
    func videoPreviewPostCollectionViewCell(_ cell: VideoPreviewPostCollectionViewCell, didSelectURL url: URL)
}

public final class VideoPreviewPostCollectionViewCell: CollectionViewCell {
    
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
    
    public let videoPreviewView: VideoPreviewView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(VideoPreviewView(frame: .zero))
    
    public let buttonsStackView: PostButtonsStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(PostButtonsStackView(frame: .zero))
    
    internal let spoilerView: SpoilerView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(SpoilerView(frame: .zero))
    
    private var layoutManager: VideoPreviewPostCollectionViewCellLayoutManager!
    
    private var currentAnimator: UIViewPropertyAnimator?
    
    public var needsApplyConfiguration = false
    
    public var configuration = Configuration() {
        didSet { setNeedsApplyConfiguration() }
    }
    
    public weak var delegate: (any VideoPreviewPostCollectionViewCellDelegate)?
    
    public weak var layoutInvalidationDelegate: (any LayoutInvalidationDelegate)?
    
    public override func setupCommon() {
        super.setupCommon()
        layoutManager = VideoPreviewPostCollectionViewCellLayoutManager(cell: self)
        contentTextView.delegate = self
        headerStackView.delegate = self
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer)))
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

extension VideoPreviewPostCollectionViewCell {
    
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
        videoPreviewView.configuration = configuration.videoPreviewViewConfiguration
        contentTextView.text = configuration.content
        buttonsStackView.configuration = configuration.buttonsConfiguration
        spoilerView.configuration = configuration.spoilerConfiguration
        
        let hasSpoiler = configuration.spoilerConfiguration.text != nil
        spoilerView.alpha = hasSpoiler ? 1.0 : 0.0
        contentTextView.alpha = hasSpoiler ? 0.0 : 1.0
        videoPreviewView.alpha = hasSpoiler ? 0.0 : 1.0
        
        layoutManager.isSpoilerVisible = hasSpoiler
        layoutManager.layout()
    }
}

extension VideoPreviewPostCollectionViewCell {
    
    @objc
    private func handleTapGestureRecognizer(_ gestureRecognizer: UITapGestureRecognizer) {
        let location = gestureRecognizer.location(in: contentView)
        if !spoilerView.isHidden, spoilerView.frame.contains(location) {
            headerStackView.toggleEye()
            layoutManager.isSpoilerVisible.toggle()
            layoutManager.layout()
            layoutManager.isSpoilerVisible ? animateSpoilerAppearance() : animateContentAppearance()
            layoutInvalidationDelegate?.invalidateLayout(self)
        } else if videoPreviewView.frame.contains(location) {
            delegate?.videoPreviewPostCollectionViewCell(self, didSelectImageView: videoPreviewView.imageView)
        }
    }
}

extension VideoPreviewPostCollectionViewCell {
    
    private func animateContentAppearance() {
        currentAnimator?.stopAnimation(true)
        currentAnimator = UIViewPropertyAnimator(duration: 0.0, timingParameters: UISpringTimingParameters(dampingRatio: 0.825, frequencyResponse: 0.3))
        currentAnimator!.addAnimations { [unowned self] in
            spoilerView.alpha = 0.0
            contentTextView.alpha = 1.0
            videoPreviewView.alpha = 1.0
        }
        currentAnimator!.startAnimation()
    }
    
    private func animateSpoilerAppearance() {
        currentAnimator?.stopAnimation(true)
        currentAnimator = UIViewPropertyAnimator(duration: 0.0, timingParameters: UISpringTimingParameters(dampingRatio: 0.825, frequencyResponse: 0.3))
        currentAnimator!.addAnimations { [unowned self] in
            spoilerView.alpha = 1.0
            contentTextView.alpha = 0.0
            videoPreviewView.alpha = 0.0
        }
        currentAnimator!.startAnimation()
    }
}

extension VideoPreviewPostCollectionViewCell: UITextViewDelegate {
    
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        delegate?.videoPreviewPostCollectionViewCell(self, didSelectURL: URL)
        return false
    }
}

extension VideoPreviewPostCollectionViewCell: PostHeaderStackViewDelegate {
    
    public func postHeaderStackViewDidTapEyeButton(_ stackView: PostHeaderStackView) {
        layoutManager.isSpoilerVisible.toggle()
        layoutManager.layout()
        layoutManager.isSpoilerVisible ? animateSpoilerAppearance() : animateContentAppearance()
        layoutInvalidationDelegate?.invalidateLayout(self)
    }
}

extension VideoPreviewPostCollectionViewCell {
    
    public struct Configuration {
        
        public var headerConfiguration: PostHeaderStackView.Configuration = PostHeaderStackView.EmptyConfiguration()
        
        public var content: String?
        
        public var videoPreviewViewConfiguration: VideoPreviewView.Configuration = VideoPreviewView.EmptyConfiguration()
        
        public var spoilerConfiguration = SpoilerView.Configuration()
        
        public var buttonsConfiguration = PostButtonsStackView.Configuration()
        
        public init() {
        }
    }
}
