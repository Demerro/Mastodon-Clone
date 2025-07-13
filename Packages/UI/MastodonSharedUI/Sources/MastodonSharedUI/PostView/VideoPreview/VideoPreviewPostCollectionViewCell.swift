//
//  VideoPreviewPostCollectionViewCell.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 12.02.25.
//

import UIKit
import UIKitFoundation

final class VideoPreviewPostCollectionViewCell: CollectionViewCell {
    
    let videoPreviewContentView = VideoPreviewPostContentView(frame: .zero)
    
    override func prepareForReuse() {
        videoPreviewContentView.configuration = VideoPreviewPostContentView.Configuration()
        videoPreviewContentView.applyConfigurationIfNeeded()
        super.prepareForReuse()
    }
    
    override func setupCommon() {
        super.setupCommon()
        videoPreviewContentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(videoPreviewContentView)
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        NSLayoutConstraint.activate([
            videoPreviewContentView.topAnchor.constraint(equalTo: contentView.topAnchor),
            videoPreviewContentView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: videoPreviewContentView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: videoPreviewContentView.bottomAnchor),
        ])
    }
}
