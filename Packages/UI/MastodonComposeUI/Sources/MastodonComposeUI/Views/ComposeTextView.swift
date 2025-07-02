//
//  ComposeTextView.swift
//  MastodonComposeUI
//
//  Created by Nikita Prokhorchuk on 26.05.25.
//

import UIKit
import UIKitFoundation

final class ComposeTextView: UITextView {
    
    let placeholderLabel: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.textColor = .secondaryLabel
        return $0
    }(UILabel(frame: .zero))
    
    override init(frame: CGRect, textContainer: NSTextContainer?) {
        super.init(frame: frame, textContainer: textContainer)
        
        isScrollEnabled = false
        font = .preferredFont(forTextStyle: .body)
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        
        addSubview(placeholderLabel)
        NSLayoutConstraint.activate([
            placeholderLabel.topAnchor.constraint(equalTo: topAnchor, constant: textContainerInset.top),
            placeholderLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(greaterThanOrEqualTo: placeholderLabel.trailingAnchor),
            bottomAnchor.constraint(greaterThanOrEqualTo: placeholderLabel.bottomAnchor),
        ])
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
}
