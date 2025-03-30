//
//  TextPostCollectionViewCell.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 29.01.25.
//

import UIKit
import UIKitFoundation
import MastodonCoreUI

public protocol TextPostCollectionViewCellDelegate: AnyObject {
    
    func textPostCollectionViewCell(_ cell: TextPostCollectionViewCell, didSelectURL url: URL)
}

public final class TextPostCollectionViewCell: CollectionViewCell {
    
    public var itemIdentifier: AnyHashable?
    
    private let headerStackView: PostHeaderStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(PostHeaderStackView(frame: .zero))
    
    private let contentTextView: UITextView = {
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
    
    private let previewCardView: PreviewCardView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(PreviewCardView(frame: .zero))
    
    private let buttonsStackView: PostButtonsStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(PostButtonsStackView(frame: .zero))
    
    private var needsApplyConfiguration = false
    
    private var oldConstraints = [NSLayoutConstraint]()
    
    public var configuration: Configuration? {
        didSet { setNeedsApplyConfiguration() }
    }
    
    public weak var delegate: (any TextPostCollectionViewCellDelegate)?
    
    public override func setupCommon() {
        super.setupCommon()
        contentView.addSubview(headerStackView)
        contentView.addSubview(contentTextView)
        contentView.addSubview(previewCardView)
        contentView.addSubview(buttonsStackView)
        previewCardView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer)))
        contentTextView.delegate = self
    }
    
    public override func setupConstraints() {
        super.setupConstraints()
        NSLayoutConstraint.activate([
            headerStackView.topAnchor.constraint(equalToSystemSpacingBelow: contentView.topAnchor, multiplier: 2.0),
            headerStackView.leadingAnchor.constraint(equalToSystemSpacingAfter: contentView.leadingAnchor, multiplier: 2.0),
            contentView.trailingAnchor.constraint(equalToSystemSpacingAfter: headerStackView.trailingAnchor, multiplier: 2.0),
            contentTextView.topAnchor.constraint(equalToSystemSpacingBelow: headerStackView.bottomAnchor, multiplier: 1.0),
            
            contentTextView.leadingAnchor.constraint(equalToSystemSpacingAfter: contentView.leadingAnchor, multiplier: 2.0),
            contentView.trailingAnchor.constraint(equalToSystemSpacingAfter: contentTextView.trailingAnchor, multiplier: 2.0),
            
            buttonsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: buttonsStackView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalToSystemSpacingBelow: buttonsStackView.bottomAnchor, multiplier: 2.0).priority(.defaultLow),
        ])
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
        var constraints = [NSLayoutConstraint]()
        
        headerStackView.configuration = configuration?.headerConfiguration
        
        contentTextView.text = configuration?.content
        
        previewCardView.configuration = configuration?.previewCardConfiguration
        previewCardView.isHidden = configuration?.previewCardConfiguration == nil
        if configuration?.previewCardConfiguration == nil {
            constraints += [
                buttonsStackView.topAnchor.constraint(equalToSystemSpacingBelow: contentTextView.bottomAnchor, multiplier: 1.0),
            ]
        } else {
            constraints += [
                previewCardView.topAnchor.constraint(equalToSystemSpacingBelow: contentTextView.bottomAnchor, multiplier: 1.0),
                previewCardView.leadingAnchor.constraint(equalToSystemSpacingAfter: contentView.leadingAnchor, multiplier: 2.0),
                contentView.trailingAnchor.constraint(equalToSystemSpacingAfter: previewCardView.trailingAnchor, multiplier: 2.0),
                buttonsStackView.topAnchor.constraint(equalToSystemSpacingBelow: previewCardView.bottomAnchor, multiplier: 1.0),
            ]
        }
    
        buttonsStackView.configuration = configuration?.buttonsConfiguration
        
        NSLayoutConstraint.deactivate(oldConstraints)
        NSLayoutConstraint.activate(constraints)
        oldConstraints = constraints
    }
}

extension TextPostCollectionViewCell {
    
    @objc
    private func handleTapGestureRecognizer(_ gestureRecognizer: UITapGestureRecognizer) {
        guard let url = configuration?.previewURL else { return }
        delegate?.textPostCollectionViewCell(self, didSelectURL: url)
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
        
        public let buttonsConfiguration: PostButtonsStackView.Configuration
        
        public init(headerConfiguration: PostHeaderStackView.Configuration, content: String, previewURL: URL?, previewCardConfiguration: PreviewCardView.Configuration? = nil, buttonsConfiguration: PostButtonsStackView.Configuration) {
            self.headerConfiguration = headerConfiguration
            self.content = content
            self.previewURL = previewURL
            self.previewCardConfiguration = previewCardConfiguration
            self.buttonsConfiguration = buttonsConfiguration
        }
    }
}
