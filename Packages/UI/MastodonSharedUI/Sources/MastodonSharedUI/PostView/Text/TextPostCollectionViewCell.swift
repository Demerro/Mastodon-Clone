//
//  TextPostCollectionViewCell.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 29.01.25.
//

import UIKit
import UIKitFoundation
import UIKitUtilities

@MainActor
public protocol TextPostCollectionViewCellDelegate: AnyObject {
    
    func textPostCollectionViewCell(_ cell: TextPostCollectionViewCell, didSelectURL url: URL)
}

public final class TextPostCollectionViewCell: CollectionViewCell {
    
    public var itemIdentifier: AnyHashable?
    
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
    
    internal let previewCardView: PreviewCardView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(PreviewCardView(frame: .zero))
    
    internal let buttonsStackView: PostButtonsStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(PostButtonsStackView(frame: .zero))
    
    internal let spoilerView: SpoilerView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(SpoilerView(frame: .zero))
    
    private var layoutManager: TextPostCollectionViewCellLayoutManager!
    
    private var currentAnimator: UIViewPropertyAnimator?
    
    private var needsApplyConfiguration = false
    
    public var configuration: Configuration? {
        didSet { setNeedsApplyConfiguration() }
    }
    
    public weak var delegate: (any TextPostCollectionViewCellDelegate)?
    
    public weak var layoutInvalidationDelegate: (any LayoutInvalidationDelegate)?
    
    public override func setupCommon() {
        super.setupCommon()
        layoutManager = TextPostCollectionViewCellLayoutManager(cell: self)
        contentTextView.delegate = self
        headerStackView.delegate = self
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer)))
    }
    
    public override func updateConstraints() {
        applyConfigurationIfNeeded()
        super.updateConstraints()
    }
}

extension TextPostCollectionViewCell {
    
    private func setNeedsApplyConfiguration() {
        guard !needsApplyConfiguration else { return }
        needsApplyConfiguration = true
        setNeedsUpdateConstraints()
    }
    
    private func applyConfigurationIfNeeded() {
        guard needsApplyConfiguration else { return }
        needsApplyConfiguration = false
        applyConfiguration()
    }
    
    private func applyConfiguration() {
        headerStackView.configuration = configuration?.headerConfiguration
        contentTextView.text = configuration?.content
        buttonsStackView.configuration = configuration?.buttonsConfiguration
        previewCardView.configuration = configuration?.previewCardConfiguration
        spoilerView.configuration = configuration?.spoilerConfiguration
        
        let hasSpoiler = configuration?.spoilerConfiguration != nil
        spoilerView.alpha = hasSpoiler ? 1.0 : 0.0
        contentTextView.alpha = hasSpoiler ? 0.0 : 1.0
        previewCardView.alpha = hasSpoiler ? 0.0 : 1.0
        
        layoutManager.isSpoilerVisible = hasSpoiler
        layoutManager.layout()
    }
}

extension TextPostCollectionViewCell {
    
    @objc
    private func handleTapGestureRecognizer(_ gestureRecognizer: UITapGestureRecognizer) {
        let location = gestureRecognizer.location(in: contentView)
        if !spoilerView.isHidden, spoilerView.frame.contains(location) {
            headerStackView.toggleEye()
            layoutManager.isSpoilerVisible.toggle()
            layoutManager.layout()
            layoutManager.isSpoilerVisible ? animateSpoilerAppearance() : animateContentAppearance()
            layoutInvalidationDelegate?.invalidateLayout(self)
        } else if previewCardView.frame.contains(location), let url = configuration?.previewURL {
            delegate?.textPostCollectionViewCell(self, didSelectURL: url)
        }
    }
}

extension TextPostCollectionViewCell {
    
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

extension TextPostCollectionViewCell: UITextViewDelegate {
    
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        delegate?.textPostCollectionViewCell(self, didSelectURL: URL)
        return false
    }
}

extension TextPostCollectionViewCell {

    public struct Configuration {
        
        public var headerConfiguration: PostHeaderStackView.Configuration
        
        public let content: String
        
        public let previewURL: URL?
        
        public var previewCardConfiguration: PreviewCardView.Configuration?
        
        public let spoilerConfiguration: SpoilerView.Configuration?
        
        public let buttonsConfiguration: PostButtonsStackView.Configuration
        
        public init(
            headerConfiguration: PostHeaderStackView.Configuration,
            content: String,
            previewURL: URL?,
            previewCardConfiguration: PreviewCardView.Configuration? = nil,
            spoilerConfiguration: SpoilerView.Configuration?,
            buttonsConfiguration: PostButtonsStackView.Configuration
        ) {
            self.headerConfiguration = headerConfiguration
            self.content = content
            self.previewURL = previewURL
            self.previewCardConfiguration = previewCardConfiguration
            self.spoilerConfiguration = spoilerConfiguration
            self.buttonsConfiguration = buttonsConfiguration
        }
    }
}

extension TextPostCollectionViewCell: PostHeaderStackViewDelegate {
    
    public func postHeaderStackViewDidTapEyeButton(_ stackView: PostHeaderStackView) {
        layoutManager.isSpoilerVisible.toggle()
        layoutManager.layout()
        layoutManager.isSpoilerVisible ? animateSpoilerAppearance() : animateContentAppearance()
        layoutInvalidationDelegate?.invalidateLayout(self)
    }
}
