//
//  VideoPreviewPostCollectionViewCell.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 12.02.25.
//

import UIKit
import UIKitFoundation

public protocol VideoPreviewPostCollectionViewCellDelegate: AnyObject {
    
    func videoPreviewPostCollectionViewCell(_ cell: VideoPreviewPostCollectionViewCell, didSelectImageView imageView: UIImageView)
    
    func videoPreviewPostCollectionViewCell(_ cell: VideoPreviewPostCollectionViewCell, didSelectURL url: URL)
}

public final class VideoPreviewPostCollectionViewCell: CollectionViewCell {
    
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
    
    public let videoPreviewView: VideoPreviewView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(VideoPreviewView(frame: .zero))
    
    private let buttonsStackView: PostButtonsStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(PostButtonsStackView(frame: .zero))
    
    public var needsApplyConfiguration = false
    
    private var oldConstraints = [NSLayoutConstraint]()
    
    public var configuration: Configuration? {
        didSet { setNeedsApplyConfiguration() }
    }
    
    public weak var delegate: (any VideoPreviewPostCollectionViewCellDelegate)?
    
    public override func setupCommon() {
        super.setupCommon()
        contentView.addSubview(headerStackView)
        contentView.addSubview(contentTextView)
        contentView.addSubview(videoPreviewView)
        contentView.addSubview(buttonsStackView)
        contentTextView.delegate = self
        videoPreviewView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleTapGestureRecognizer)))
    }
    
    public override func setupConstraints() {
        super.setupConstraints()
        NSLayoutConstraint.activate([
            headerStackView.topAnchor.constraint(equalToSystemSpacingBelow: contentView.topAnchor, multiplier: 2.0),
            headerStackView.leadingAnchor.constraint(equalToSystemSpacingAfter: contentView.leadingAnchor, multiplier: 2.0),
            contentView.trailingAnchor.constraint(equalToSystemSpacingAfter: headerStackView.trailingAnchor, multiplier: 2.0),
            contentTextView.topAnchor.constraint(equalToSystemSpacingBelow: headerStackView.bottomAnchor, multiplier: 1.0),
            
            videoPreviewView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: videoPreviewView.trailingAnchor),
            buttonsStackView.topAnchor.constraint(equalToSystemSpacingBelow: videoPreviewView.bottomAnchor, multiplier: 2.0),
            
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
    }
    
    private func applyConfiguration() {
        var constraints = [NSLayoutConstraint]()
        
        headerStackView.configuration = configuration?.headerConfiguration
        
        contentTextView.text = configuration?.content
        let contentIsEmpty = configuration?.content.isEmpty ?? true
        contentTextView.isHidden = contentIsEmpty
        if contentIsEmpty {
            constraints += [
                videoPreviewView.topAnchor.constraint(equalToSystemSpacingBelow: headerStackView.bottomAnchor, multiplier: 1.0)
            ]
        } else {
            constraints += [
                contentTextView.leadingAnchor.constraint(equalToSystemSpacingAfter: contentView.leadingAnchor, multiplier: 2.0),
                contentView.trailingAnchor.constraint(equalToSystemSpacingAfter: contentTextView.trailingAnchor, multiplier: 2.0),
                videoPreviewView.topAnchor.constraint(equalToSystemSpacingBelow: contentTextView.bottomAnchor, multiplier: 1.0),
            ]
        }
        
        videoPreviewView.configuration = configuration?.videoPreviewViewConfiguration
        buttonsStackView.configuration = configuration?.buttonsConfiguration
        
        NSLayoutConstraint.deactivate(oldConstraints)
        NSLayoutConstraint.activate(constraints)
        oldConstraints = constraints
    }
}

extension VideoPreviewPostCollectionViewCell {
    
    @objc
    private func handleTapGestureRecognizer(_ tapGestureRecognizer: UITapGestureRecognizer) {
        delegate?.videoPreviewPostCollectionViewCell(self, didSelectImageView: videoPreviewView.imageView)
    }
}

extension VideoPreviewPostCollectionViewCell: UITextViewDelegate {
    
    public func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        delegate?.videoPreviewPostCollectionViewCell(self, didSelectURL: URL)
        return false
    }
}

extension VideoPreviewPostCollectionViewCell {
    
    public struct Configuration {
        
        public var headerConfiguration: PostHeaderStackView.Configuration
        
        public let content: String
        
        public var videoPreviewViewConfiguration: VideoPreviewView.Configuration?
        
        public let buttonsConfiguration: PostButtonsStackView.Configuration
        
        public init(headerConfiguration: PostHeaderStackView.Configuration, content: String, videoPreviewViewConfiguration: VideoPreviewView.Configuration? = nil, buttonsConfiguration: PostButtonsStackView.Configuration) {
            self.headerConfiguration = headerConfiguration
            self.content = content
            self.videoPreviewViewConfiguration = videoPreviewViewConfiguration
            self.buttonsConfiguration = buttonsConfiguration
        }
    }
}
