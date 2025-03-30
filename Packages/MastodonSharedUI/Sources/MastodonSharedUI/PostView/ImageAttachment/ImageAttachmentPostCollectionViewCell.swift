//
//  ImageAttachmentPostCollectionViewCell.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 4.02.25.
//

import UIKit
import UIKitFoundation

public protocol ImageAttachmentPostCollectionViewCellDelegate: AnyObject {
    
    func imageAttachmentPostCollectionViewCell(_ cell: ImageAttachmentPostCollectionViewCell, didSelectImageView imageView: UIImageView)
    
    func imageAttachmentPostCollectionViewCell(_ cell: ImageAttachmentPostCollectionViewCell, didSelectURL url: URL)
}

public final class ImageAttachmentPostCollectionViewCell: CollectionViewCell {
    
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
    
    private let imageAttachmentMosaicStackView: ImageAttachmentMosaicStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(ImageAttachmentMosaicStackView(frame: .zero))
    
    private let buttonsStackView: PostButtonsStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(PostButtonsStackView(frame: .zero))
    
    private var needsApplyConfiguration = false
    
    private var oldConstraints = [NSLayoutConstraint]()
    
    public var configuration: Configuration? {
        didSet { setNeedsApplyConfiguration() }
    }
    
    public weak var delegate: (any ImageAttachmentPostCollectionViewCellDelegate)?
    
    public override func setupCommon() {
        super.setupCommon()
        contentView.addSubview(headerStackView)
        contentView.addSubview(contentTextView)
        contentView.addSubview(imageAttachmentMosaicStackView)
        contentView.addSubview(buttonsStackView)
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer)))
        contentTextView.delegate = self
    }
    
    public override func setupConstraints() {
        super.setupConstraints()
        NSLayoutConstraint.activate([
            headerStackView.topAnchor.constraint(equalToSystemSpacingBelow: contentView.topAnchor, multiplier: 2.0),
            headerStackView.leadingAnchor.constraint(equalToSystemSpacingAfter: contentView.leadingAnchor, multiplier: 2.0),
            contentView.trailingAnchor.constraint(equalToSystemSpacingAfter: headerStackView.trailingAnchor, multiplier: 2.0),
            contentTextView.topAnchor.constraint(equalToSystemSpacingBelow: headerStackView.bottomAnchor, multiplier: 1.0),
            
            imageAttachmentMosaicStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: imageAttachmentMosaicStackView.trailingAnchor),
            buttonsStackView.topAnchor.constraint(equalToSystemSpacingBelow: imageAttachmentMosaicStackView.bottomAnchor, multiplier: 2.0),
            
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
    }
    
    private func applyConfiguration() {
        var constraints = [NSLayoutConstraint]()
        
        headerStackView.configuration = configuration?.headerConfiguration
        
        contentTextView.text = configuration?.content
        let contentIsEmpty = configuration?.content.isEmpty ?? true
        contentTextView.isHidden = contentIsEmpty
        if contentIsEmpty {
            constraints += [
                imageAttachmentMosaicStackView.topAnchor.constraint(equalToSystemSpacingBelow: headerStackView.bottomAnchor, multiplier: 1.0)
            ]
        } else {
            constraints += [
                contentTextView.leadingAnchor.constraint(equalToSystemSpacingAfter: contentView.leadingAnchor, multiplier: 2.0),
                contentView.trailingAnchor.constraint(equalToSystemSpacingAfter: contentTextView.trailingAnchor, multiplier: 2.0),
                imageAttachmentMosaicStackView.topAnchor.constraint(equalToSystemSpacingBelow: contentTextView.bottomAnchor, multiplier: 1.0),
            ]
        }
        
        imageAttachmentMosaicStackView.configuration = configuration?.imageAttachmentMosaicStackViewConfiguration
        buttonsStackView.configuration = configuration?.buttonsConfiguration
        
        NSLayoutConstraint.deactivate(oldConstraints)
        NSLayoutConstraint.activate(constraints)
        oldConstraints = constraints
    }
}

extension ImageAttachmentPostCollectionViewCell {
    
    @objc
    private func handleTapGestureRecognizer(_ gestureRecognizer: UITapGestureRecognizer) {
        let point = gestureRecognizer.location(in: contentView)
        if headerStackView.frame.contains(point) {
            return
        }
        if let imageView = imageAttachmentMosaicStackView.imageViews.first(where: { $0.superview!.convert($0.frame, to: contentView).contains(point) }) {
            delegate?.imageAttachmentPostCollectionViewCell(self, didSelectImageView: imageView)
        }
    }
}

extension ImageAttachmentPostCollectionViewCell: UITextViewDelegate {
    
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        delegate?.imageAttachmentPostCollectionViewCell(self, didSelectURL: URL)
        return false
    }
}

extension ImageAttachmentPostCollectionViewCell {
    
    public struct Configuration {
        
        public var headerConfiguration: PostHeaderStackView.Configuration
        
        public let content: String
        
        public var imageAttachmentMosaicStackViewConfiguration: ImageAttachmentMosaicStackView.Configuration
        
        public let buttonsConfiguration: PostButtonsStackView.Configuration
        
        public init(
            headerConfiguration: PostHeaderStackView.Configuration,
            content: String,
            imageAttachmentMosaicStackViewConfiguration: ImageAttachmentMosaicStackView.Configuration,
            buttonsConfiguration: PostButtonsStackView.Configuration
        ) {
            self.headerConfiguration = headerConfiguration
            self.content = content
            self.imageAttachmentMosaicStackViewConfiguration = imageAttachmentMosaicStackViewConfiguration
            self.buttonsConfiguration = buttonsConfiguration
        }
    }
}
