//
//  ImageAttachmentPostCollectionViewCell.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 4.02.25.
//

import UIKit
import UIKitFoundation
import UIKitUtilities

final class ImageAttachmentPostCollectionViewCell: CollectionViewCell {
    
    let imageAttachmentPostContentView = ImageAttachmentPostContentView(frame: .zero)
    
    override func prepareForReuse() {
        imageAttachmentPostContentView.configuration = ImageAttachmentPostContentView.Configuration()
        imageAttachmentPostContentView.applyConfigurationIfNeeded()
        super.prepareForReuse()
    }
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        imageAttachmentPostContentView.applyConfigurationIfNeeded()
        return imageAttachmentPostContentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
    }
    
    override func setupCommon() {
        super.setupCommon()
        imageAttachmentPostContentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageAttachmentPostContentView)
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        NSLayoutConstraint.activate([
            imageAttachmentPostContentView.topAnchor.constraint(equalTo: contentView.topAnchor),
            imageAttachmentPostContentView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: imageAttachmentPostContentView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: imageAttachmentPostContentView.bottomAnchor),
        ])
    }
}

extension ImageAttachmentPostCollectionViewCell: LayoutInvalidationDelegate {
    
    func invalidateLayout(_ view: UIView) {
        
    }
}
