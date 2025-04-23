//
//  TextPostCollectionViewCellLayoutManager.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 4.04.25.
//

import UIKit
import UIKitUtilities

final class TextPostCollectionViewCellLayoutManager {
    
    private var constraint: NSLayoutConstraint?
    
    var isSpoilerVisible = false
    
    unowned var cell: TextPostCollectionViewCell
    
    init(cell: TextPostCollectionViewCell) {
        self.cell = cell
        
        cell.contentView.addSubview(cell.headerStackView)
        cell.contentView.addSubview(cell.contentTextView)
        cell.contentView.addSubview(cell.previewCardView)
        cell.contentView.addSubview(cell.buttonsStackView)
        cell.contentView.addSubview(cell.spoilerView)
        
        NSLayoutConstraint.activate([
            cell.headerStackView.topAnchor.constraint(equalToSystemSpacingBelow: cell.contentView.topAnchor, multiplier: 2.0),
            cell.headerStackView.leadingAnchor.constraint(equalToSystemSpacingAfter: cell.contentView.leadingAnchor, multiplier: 2.0),
            cell.contentView.trailingAnchor.constraint(equalToSystemSpacingAfter: cell.headerStackView.trailingAnchor, multiplier: 2.0),
            cell.contentTextView.topAnchor.constraint(equalToSystemSpacingBelow: cell.headerStackView.bottomAnchor, multiplier: 1.0),
            
            cell.contentTextView.leadingAnchor.constraint(equalToSystemSpacingAfter: cell.contentView.leadingAnchor, multiplier: 2.0),
            cell.contentView.trailingAnchor.constraint(equalToSystemSpacingAfter: cell.contentTextView.trailingAnchor, multiplier: 2.0),
            
            cell.previewCardView.topAnchor.constraint(equalToSystemSpacingBelow: cell.contentTextView.bottomAnchor, multiplier: 1.0),
            cell.previewCardView.leadingAnchor.constraint(equalToSystemSpacingAfter: cell.contentView.leadingAnchor, multiplier: 2.0),
            cell.contentView.trailingAnchor.constraint(equalToSystemSpacingAfter: cell.previewCardView.trailingAnchor, multiplier: 2.0),
            
            cell.buttonsStackView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            cell.contentView.trailingAnchor.constraint(equalTo: cell.buttonsStackView.trailingAnchor),
            cell.contentView.bottomAnchor.constraint(equalToSystemSpacingBelow: cell.buttonsStackView.bottomAnchor, multiplier: 2.0).priority(.defaultLow),
            
            cell.spoilerView.topAnchor.constraint(equalToSystemSpacingBelow: cell.headerStackView.bottomAnchor, multiplier: 1.0),
            cell.spoilerView.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            cell.contentView.trailingAnchor.constraint(equalTo: cell.spoilerView.trailingAnchor),
        ])
    }
}

extension TextPostCollectionViewCellLayoutManager {
    
    func layout() {
        isSpoilerVisible ? layoutSpoiler() : layoutContent()
    }
    
    private func layoutSpoiler() {
        cell.spoilerView.isHidden = false
        cell.contentTextView.isHidden = true
        cell.previewCardView.isHidden = true
        
        if let constraint { NSLayoutConstraint.deactivate([constraint]) }
        constraint = cell.buttonsStackView.topAnchor.constraint(equalToSystemSpacingBelow: cell.spoilerView.bottomAnchor, multiplier: 1.0)
        NSLayoutConstraint.activate([constraint!])
    }
    
    private func layoutContent() {
        cell.spoilerView.isHidden = true
        cell.contentTextView.isHidden = false
        cell.previewCardView.isHidden = cell.configuration.previewCardConfiguration is PreviewCardView.EmptyConfiguration
        
        if let constraint { NSLayoutConstraint.deactivate([constraint]) }
        constraint = if cell.previewCardView.isHidden {
            cell.buttonsStackView.topAnchor.constraint(equalToSystemSpacingBelow: cell.contentTextView.bottomAnchor, multiplier: 1.0)
        } else {
            cell.buttonsStackView.topAnchor.constraint(equalToSystemSpacingBelow: cell.previewCardView.bottomAnchor, multiplier: 1.0)
        }
        NSLayoutConstraint.activate([constraint!])
    }
}
