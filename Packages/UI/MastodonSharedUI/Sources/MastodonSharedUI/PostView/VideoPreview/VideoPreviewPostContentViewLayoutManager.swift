//
//  VideoPreviewPostContentViewLayoutManager.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 5.04.25.
//

import UIKit
import UIKitUtilities

final class VideoPreviewPostContentViewLayoutManager {
    
    private var oldConstraints = [NSLayoutConstraint]()
    
    var isSpoilerVisible = false
    
    unowned var contentView: VideoPreviewPostContentView
    
    init(contentView: VideoPreviewPostContentView) {
        self.contentView = contentView
        
        contentView.addSubview(contentView.headerStackView)
        contentView.addSubview(contentView.contentTextView)
        contentView.addSubview(contentView.videoPreviewView)
        contentView.addSubview(contentView.buttonsStackView)
        contentView.addSubview(contentView.spoilerView)
        
        NSLayoutConstraint.activate([
            contentView.headerStackView.topAnchor.constraint(equalToSystemSpacingBelow: contentView.topAnchor, multiplier: 2.0),
            contentView.headerStackView.leadingAnchor.constraint(equalToSystemSpacingAfter: contentView.leadingAnchor, multiplier: 2.0),
            contentView.trailingAnchor.constraint(equalToSystemSpacingAfter: contentView.headerStackView.trailingAnchor, multiplier: 2.0),
            
            contentView.contentTextView.topAnchor.constraint(equalToSystemSpacingBelow: contentView.headerStackView.bottomAnchor, multiplier: 1.0),
            contentView.contentTextView.leadingAnchor.constraint(equalToSystemSpacingAfter: contentView.leadingAnchor, multiplier: 2.0),
            contentView.trailingAnchor.constraint(equalToSystemSpacingAfter: contentView.contentTextView.trailingAnchor, multiplier: 2.0),
            
            contentView.videoPreviewView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: contentView.videoPreviewView.trailingAnchor),
            
            contentView.buttonsStackView.topAnchor.constraint(equalToSystemSpacingBelow: contentView.videoPreviewView.bottomAnchor, multiplier: 1.0),
            contentView.buttonsStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: contentView.buttonsStackView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalToSystemSpacingBelow: contentView.buttonsStackView.bottomAnchor, multiplier: 2.0).priority(.defaultLow),
            
            contentView.spoilerView.topAnchor.constraint(equalToSystemSpacingBelow: contentView.headerStackView.bottomAnchor, multiplier: 1.0),
            contentView.spoilerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: contentView.spoilerView.trailingAnchor),
        ])
    }
}

extension VideoPreviewPostContentViewLayoutManager {
    
    func layout() {
        isSpoilerVisible ? layoutSpoiler() : layoutContent()
    }
    
    private func layoutSpoiler() {
        contentView.spoilerView.isHidden = false
        contentView.contentTextView.isHidden = true
        contentView.videoPreviewView.isHidden = true
        
        
        let constraints = [contentView.buttonsStackView.topAnchor.constraint(equalToSystemSpacingBelow: contentView.spoilerView.bottomAnchor, multiplier: 1.0)]
        NSLayoutConstraint.deactivate(oldConstraints)
        NSLayoutConstraint.activate(constraints)
        oldConstraints = constraints
    }
    
    private func layoutContent() {
        contentView.spoilerView.isHidden = true
        contentView.contentTextView.isHidden = contentView.configuration.content?.isEmpty ?? true
        contentView.videoPreviewView.isHidden = false
        
        let constraints = if contentView.contentTextView.isHidden {
            [contentView.videoPreviewView.topAnchor.constraint(equalToSystemSpacingBelow: contentView.headerStackView.bottomAnchor, multiplier: 1.0)]
        } else {
            [contentView.contentTextView.topAnchor.constraint(equalToSystemSpacingBelow: contentView.headerStackView.bottomAnchor, multiplier: 1.0),
             contentView.videoPreviewView.topAnchor.constraint(equalToSystemSpacingBelow: contentView.contentTextView.bottomAnchor, multiplier: 1.0)]
        }
        NSLayoutConstraint.deactivate(oldConstraints)
        NSLayoutConstraint.activate(constraints)
        oldConstraints = constraints
    }
}
