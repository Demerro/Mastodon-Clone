//
//  TextPostContentViewLayoutManager.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 4.04.25.
//

import UIKit
import UIKitUtilities

final class TextPostContentViewLayoutManager {
    
    private var constraint: NSLayoutConstraint?
    
    var isSpoilerVisible = false
    
    unowned var contentView: TextPostContentView
    
    init(contentView: TextPostContentView) {
        self.contentView = contentView
        
        contentView.addSubview(contentView.headerStackView)
        contentView.addSubview(contentView.contentTextView)
        contentView.addSubview(contentView.previewCardView)
        contentView.addSubview(contentView.buttonsStackView)
        contentView.addSubview(contentView.spoilerView)
        
        NSLayoutConstraint.activate([
            contentView.headerStackView.topAnchor.constraint(equalToSystemSpacingBelow: contentView.topAnchor, multiplier: 2.0),
            contentView.headerStackView.leadingAnchor.constraint(equalToSystemSpacingAfter: contentView.leadingAnchor, multiplier: 2.0),
            contentView.trailingAnchor.constraint(equalToSystemSpacingAfter: contentView.headerStackView.trailingAnchor, multiplier: 2.0),
            contentView.contentTextView.topAnchor.constraint(equalToSystemSpacingBelow: contentView.headerStackView.bottomAnchor, multiplier: 1.0),
            
            contentView.contentTextView.leadingAnchor.constraint(equalToSystemSpacingAfter: contentView.leadingAnchor, multiplier: 2.0),
            contentView.trailingAnchor.constraint(equalToSystemSpacingAfter: contentView.contentTextView.trailingAnchor, multiplier: 2.0),
            
            contentView.previewCardView.topAnchor.constraint(equalToSystemSpacingBelow: contentView.contentTextView.bottomAnchor, multiplier: 1.0),
            contentView.previewCardView.leadingAnchor.constraint(equalToSystemSpacingAfter: contentView.leadingAnchor, multiplier: 2.0),
            contentView.trailingAnchor.constraint(equalToSystemSpacingAfter: contentView.previewCardView.trailingAnchor, multiplier: 2.0),
            
            contentView.buttonsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: contentView.buttonsStackView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalToSystemSpacingBelow: contentView.buttonsStackView.bottomAnchor, multiplier: 2.0).priority(.defaultLow),
            
            contentView.spoilerView.topAnchor.constraint(equalToSystemSpacingBelow: contentView.headerStackView.bottomAnchor, multiplier: 1.0),
            contentView.spoilerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: contentView.spoilerView.trailingAnchor),
        ])
    }
}

extension TextPostContentViewLayoutManager {
    
    func layout() {
        isSpoilerVisible ? layoutSpoiler() : layoutContent()
    }
    
    private func layoutSpoiler() {
        contentView.spoilerView.isHidden = false
        contentView.contentTextView.isHidden = true
        contentView.previewCardView.isHidden = true
        
        if let constraint { NSLayoutConstraint.deactivate([constraint]) }
        constraint = contentView.buttonsStackView.topAnchor.constraint(equalToSystemSpacingBelow: contentView.spoilerView.bottomAnchor, multiplier: 1.0)
        NSLayoutConstraint.activate([constraint!])
    }
    
    private func layoutContent() {
        contentView.spoilerView.isHidden = true
        contentView.contentTextView.isHidden = false
        contentView.previewCardView.isHidden = contentView.configuration.previewCardConfiguration is PreviewCardView.EmptyConfiguration
        
        if let constraint { NSLayoutConstraint.deactivate([constraint]) }
        constraint = if contentView.previewCardView.isHidden {
            contentView.buttonsStackView.topAnchor.constraint(equalToSystemSpacingBelow: contentView.contentTextView.bottomAnchor, multiplier: 1.0)
        } else {
            contentView.buttonsStackView.topAnchor.constraint(equalToSystemSpacingBelow: contentView.previewCardView.bottomAnchor, multiplier: 1.0)
        }
        NSLayoutConstraint.activate([constraint!])
    }
}
