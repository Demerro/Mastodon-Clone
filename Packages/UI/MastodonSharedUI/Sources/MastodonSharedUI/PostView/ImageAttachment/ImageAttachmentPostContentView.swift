//
//  ImageAttachmentPostContentView.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 23.05.25.
//

import UIKit
import UIKitFoundation

final class ImageAttachmentPostContentView: View {
    
    let headerStackView: PostHeaderStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(PostHeaderStackView(frame: .zero))
    
    let contentTextView: UITextView = {
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
    
    let imageAttachmentMosaicStackView: ImageAttachmentMosaicStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(ImageAttachmentMosaicStackView(frame: .zero))
    
    let buttonsStackView: PostButtonsStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(PostButtonsStackView(frame: .zero))
    
    let spoilerView: SpoilerView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(SpoilerView(frame: .zero))
    
    private var layoutManager: ImageAttachmentPostContentViewLayoutManager!
    
    private var currentAnimator: UIViewPropertyAnimator?
    
    private var needsApplyConfiguration = false
    
    var configuration = Configuration() {
        didSet { setNeedsApplyConfiguration() }
    }
    
    weak var delegate: (any Delegate)?
    
    weak var layoutInvalidationDelegate: (any LayoutInvalidationDelegate)?
    
    override func setupCommon() {
        super.setupCommon()
        layoutManager = ImageAttachmentPostContentViewLayoutManager(contentView: self)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer)))
        contentTextView.delegate = self
        headerStackView.delegate = self
    }
    
    override func updateConstraints() {
        applyConfigurationIfNeeded()
        super.updateConstraints()
    }
}

extension ImageAttachmentPostContentView {
    
    private func setNeedsApplyConfiguration() {
        guard !needsApplyConfiguration else { return }
        needsApplyConfiguration = true
        setNeedsUpdateConstraints()
    }
    
    func applyConfigurationIfNeeded() {
        guard needsApplyConfiguration else { return }
        needsApplyConfiguration = false
        applyConfiguration()
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

extension ImageAttachmentPostContentView {
    
    @objc
    private func handleTapGestureRecognizer(_ gestureRecognizer: UITapGestureRecognizer) {
        let location = gestureRecognizer.location(in: self)
        if !spoilerView.isHidden, spoilerView.frame.contains(location) {
            headerStackView.toggleEye()
            layoutManager.isSpoilerVisible.toggle()
            layoutManager.layout()
            layoutManager.isSpoilerVisible ? animateSpoilerAppearance() : animateContentAppearance()
            layoutInvalidationDelegate?.invalidateLayout(self)
        } else if let imageView = imageAttachmentMosaicStackView.imageViews.first(where: { $0.superview!.convert($0.frame, to: self).contains(location) }) {
            delegate?.imageAttachmentPostContentView(self, didSelectImageView: imageView)
        }
    }
}

extension ImageAttachmentPostContentView {
    
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

extension ImageAttachmentPostContentView: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        delegate?.imageAttachmentPostContentView(self, didSelectURL: URL)
        return false
    }
}

extension ImageAttachmentPostContentView: PostHeaderStackViewDelegate {
    
    func postHeaderStackViewDidTapEyeButton(_ stackView: PostHeaderStackView) {
        layoutManager.isSpoilerVisible.toggle()
        layoutManager.layout()
        layoutManager.isSpoilerVisible ? animateSpoilerAppearance() : animateContentAppearance()
        layoutInvalidationDelegate?.invalidateLayout(self)
    }
}

extension ImageAttachmentPostContentView {
    
    struct Configuration {
        
        var headerConfiguration: PostHeaderStackView.Configuration = PostHeaderStackView.EmptyConfiguration()
        
        var content: String?
        
        var imageAttachmentMosaicStackViewConfiguration: ImageAttachmentMosaicStackView.Configuration = ImageAttachmentMosaicStackView.EmptyConfiguration()
        
        var spoilerConfiguration = SpoilerView.Configuration()
        
        var buttonsConfiguration = PostButtonsStackView.Configuration()
    }
}

extension ImageAttachmentPostContentView {
    
    @MainActor
    protocol Delegate: AnyObject {
        func imageAttachmentPostContentView(_ contentView: ImageAttachmentPostContentView, didSelectImageView imageView: UIImageView)
        func imageAttachmentPostContentView(_ contentView: ImageAttachmentPostContentView, didSelectURL url: URL)
    }
}
