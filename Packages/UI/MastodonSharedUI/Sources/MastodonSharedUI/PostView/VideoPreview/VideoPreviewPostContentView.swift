//
//  VideoPreviewPostContentView.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 23.05.25.
//

import UIKit
import UIKitFoundation

final class VideoPreviewPostContentView: View {
    
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
    
    let videoPreviewView: VideoPreviewView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(VideoPreviewView(frame: .zero))
    
    let buttonsStackView: PostButtonsStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(PostButtonsStackView(frame: .zero))
    
    let spoilerView: SpoilerView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(SpoilerView(frame: .zero))
    
    private var layoutManager: VideoPreviewPostContentViewLayoutManager!
    
    private var currentAnimator: UIViewPropertyAnimator?
    
    private var needsApplyConfiguration = false
    
    var configuration = Configuration() {
        didSet { setNeedsApplyConfiguration() }
    }
    
    weak var delegate: (any Delegate)?
    
    weak var layoutInvalidationDelegate: (any LayoutInvalidationDelegate)?
    
    override func setupCommon() {
        super.setupCommon()
        layoutManager = VideoPreviewPostContentViewLayoutManager(contentView: self)
        contentTextView.delegate = self
        headerStackView.delegate = self
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer)))
    }
    
    override func updateConstraints() {
        applyConfigurationIfNeeded()
        super.updateConstraints()
    }
}

extension VideoPreviewPostContentView {
    
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

extension VideoPreviewPostContentView {
    
    @objc
    private func handleTapGestureRecognizer(_ gestureRecognizer: UITapGestureRecognizer) {
        let location = gestureRecognizer.location(in: self)
        if !spoilerView.isHidden, spoilerView.frame.contains(location) {
            headerStackView.toggleEye()
            layoutManager.isSpoilerVisible.toggle()
            layoutManager.layout()
            layoutManager.isSpoilerVisible ? animateSpoilerAppearance() : animateContentAppearance()
            layoutInvalidationDelegate?.invalidateLayout(self)
        } else if videoPreviewView.frame.contains(location) {
            delegate?.videoPreviewPostContentView(self, didSelectImageView: videoPreviewView.imageView)
        }
    }
}

extension VideoPreviewPostContentView {
    
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

extension VideoPreviewPostContentView: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        delegate?.videoPreviewPostContentView(self, didSelectURL: URL)
        return false
    }
}

extension VideoPreviewPostContentView: PostHeaderStackViewDelegate {
    
    public func postHeaderStackViewDidTapEyeButton(_ stackView: PostHeaderStackView) {
        layoutManager.isSpoilerVisible.toggle()
        layoutManager.layout()
        layoutManager.isSpoilerVisible ? animateSpoilerAppearance() : animateContentAppearance()
        layoutInvalidationDelegate?.invalidateLayout(self)
    }
}

extension VideoPreviewPostContentView {
    
    struct Configuration {
        
        var headerConfiguration: PostHeaderStackView.Configuration = PostHeaderStackView.EmptyConfiguration()
        
        var content: String?
        
        var videoPreviewViewConfiguration: VideoPreviewView.Configuration = VideoPreviewView.EmptyConfiguration()
        
        var spoilerConfiguration = SpoilerView.Configuration()
        
        var buttonsConfiguration = PostButtonsStackView.Configuration()
    }
}

extension VideoPreviewPostContentView {
    
    @MainActor
    protocol Delegate: AnyObject {
        func videoPreviewPostContentView(_ contentView: VideoPreviewPostContentView, didSelectImageView imageView: UIImageView)
        func videoPreviewPostContentView(_ contentView: VideoPreviewPostContentView, didSelectURL url: URL)
    }
}
