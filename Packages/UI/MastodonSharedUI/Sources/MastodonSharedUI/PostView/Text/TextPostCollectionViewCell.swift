//
//  TextPostCollectionViewCell.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 29.01.25.
//

import UIKit
import UIKitFoundation

final class TextPostCollectionViewCell: CollectionViewCell {
    
    let textPostContentView = TextPostContentView(frame: .zero)
    
//    var itemIdentifier: AnyHashable {
//        didSet { tex }
//    }
    
    override func prepareForReuse() {
        textPostContentView.configuration = TextPostContentView.Configuration()
        textPostContentView.applyConfigurationIfNeeded()
        super.prepareForReuse()
    }
    
    override func systemLayoutSizeFitting(_ targetSize: CGSize, withHorizontalFittingPriority horizontalFittingPriority: UILayoutPriority, verticalFittingPriority: UILayoutPriority) -> CGSize {
        textPostContentView.applyConfigurationIfNeeded()
        return textPostContentView.systemLayoutSizeFitting(targetSize, withHorizontalFittingPriority: horizontalFittingPriority, verticalFittingPriority: verticalFittingPriority)
    }
    
    override func setupCommon() {
        super.setupCommon()
        textPostContentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(textPostContentView)
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        NSLayoutConstraint.activate([
            textPostContentView.topAnchor.constraint(equalTo: contentView.topAnchor),
            textPostContentView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: textPostContentView.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: textPostContentView.bottomAnchor),
        ])
    }
}
