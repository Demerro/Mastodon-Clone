//
//  TextPostContentView.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 23.05.25.
//

import UIKit
import UIKitFoundation

final class TextPostContentView: View {
    
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
    
    let previewCardView: PreviewCardView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(PreviewCardView(frame: .zero))
    
    let buttonsStackView: PostButtonsStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(PostButtonsStackView(frame: .zero))
    
    let spoilerView: SpoilerView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(SpoilerView(frame: .zero))
    
    private var layoutManager: TextPostContentViewLayoutManager!
    
    private var currentAnimator: UIViewPropertyAnimator?
    
    private var needsApplyConfiguration = false
    
    var configuration = Configuration() {
        didSet { setNeedsApplyConfiguration() }
    }
    
    weak var delegate: (any Delegate)?
    
    override func setupCommon() {
        super.setupCommon()
        layoutManager = TextPostContentViewLayoutManager(contentView: self)
        contentTextView.delegate = self
        headerStackView.delegate = self
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer)))
    }
    
    override func updateConstraints() {
        applyConfigurationIfNeeded()
        super.updateConstraints()
    }
}

extension TextPostContentView {
    
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
        buttonsStackView.configuration = configuration.buttonsConfiguration
        previewCardView.configuration = configuration.previewCardConfiguration
        spoilerView.configuration = configuration.spoilerConfiguration
        
        let hasSpoiler = configuration.spoilerConfiguration.text != nil
        spoilerView.alpha = hasSpoiler ? 1.0 : 0.0
        contentTextView.alpha = hasSpoiler ? 0.0 : 1.0
        previewCardView.alpha = hasSpoiler ? 0.0 : 1.0
        
        layoutManager.isSpoilerVisible = hasSpoiler
        layoutManager.layout()
    }
}

extension TextPostContentView {
    
    @objc
    private func handleTapGestureRecognizer(_ gestureRecognizer: UITapGestureRecognizer) {
        let location = gestureRecognizer.location(in: self)
        if !spoilerView.isHidden, spoilerView.frame.contains(location) {
            headerStackView.toggleEye()
            layoutManager.isSpoilerVisible.toggle()
            layoutManager.layout()
            layoutManager.isSpoilerVisible ? animateSpoilerAppearance() : animateContentAppearance()
            delegate?.textPostContentViewNeedsInvalidateLayout(self)
        } else if previewCardView.frame.contains(location), let url = configuration.previewURL {
            delegate?.textPostContentView(self, didSelectURL: url)
        }
    }
}

extension TextPostContentView {
    
    private func animateContentAppearance() {
        currentAnimator?.stopAnimation(true)
        currentAnimator = UIViewPropertyAnimator(duration: 0.0, timingParameters: UISpringTimingParameters(dampingRatio: 0.825, frequencyResponse: 0.3))
        currentAnimator!.addAnimations { [unowned self] in
            spoilerView.alpha = 0.0
            contentTextView.alpha = 1.0
            previewCardView.alpha = 1.0
        }
        currentAnimator!.startAnimation()
    }
    
    private func animateSpoilerAppearance() {
        currentAnimator?.stopAnimation(true)
        currentAnimator = UIViewPropertyAnimator(duration: 0.0, timingParameters: UISpringTimingParameters(dampingRatio: 0.825, frequencyResponse: 0.3))
        currentAnimator!.addAnimations { [unowned self] in
            spoilerView.alpha = 1.0
            contentTextView.alpha = 0.0
            previewCardView.alpha = 0.0
        }
        currentAnimator!.startAnimation()
    }
}

extension TextPostContentView {

    struct Configuration {
        
        var headerConfiguration: PostHeaderStackView.Configuration = PostHeaderStackView.EmptyConfiguration()
        
        var content: String?
        
        var previewURL: URL?
        
        var previewCardConfiguration: PreviewCardView.Configuration = PreviewCardView.EmptyConfiguration()
        
        var spoilerConfiguration = SpoilerView.Configuration()
        
        var buttonsConfiguration = PostButtonsStackView.Configuration()
    }
}

extension TextPostContentView: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        delegate?.textPostContentView(self, didSelectURL: URL)
        return false
    }
}

extension TextPostContentView: PostHeaderStackViewDelegate {
    
    func postHeaderStackViewDidTapEyeButton(_ stackView: PostHeaderStackView) {
        layoutManager.isSpoilerVisible.toggle()
        layoutManager.layout()
        layoutManager.isSpoilerVisible ? animateSpoilerAppearance() : animateContentAppearance()
        delegate?.textPostContentViewNeedsInvalidateLayout(self)
    }
}

extension TextPostContentView {
    
    @MainActor
    protocol Delegate: AnyObject {
        func textPostContentView(_ contentView: TextPostContentView, didSelectURL url: URL)
        func textPostContentViewNeedsInvalidateLayout(_ contentView: TextPostContentView)
    }
}
