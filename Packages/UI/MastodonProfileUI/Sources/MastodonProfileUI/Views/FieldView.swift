//
//  FieldView.swift
//  MastodonProfileUI
//
//  Created by Nikita Prokhorchuk on 6.01.25.
//

import UIKit
import UIKitFoundation
import UIKitUtilities

final class FieldView: StackView, UIContentView {
    
    private let titleLabel: UILabel = {
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 1
        $0.font = .preferredFont(forTextStyle: .footnote)
        return $0
    }(UILabel(frame: .zero))
    
    private let valueTextView: UITextView = {
        $0.textContainer.maximumNumberOfLines = 1
        $0.textContainer.lineFragmentPadding = .zero
        $0.textContainer.lineBreakMode = .byTruncatingTail
        $0.isScrollEnabled = false
        $0.isEditable = false
        $0.textContainerInset = .zero
        $0.showsHorizontalScrollIndicator = false
        $0.showsVerticalScrollIndicator = false
        return $0
    }(UITextView(frame: .zero))
    
    private var appliedConfiguration: Configuration!
    
    var configuration: any UIContentConfiguration {
        get {
            appliedConfiguration
        }
        set {
            guard let newConfiguration = newValue as? Configuration else { return }
            apply(configuration: newConfiguration)
        }
    }
    
    init(configuration: Configuration) {
        super.init(frame: .zero)
        apply(configuration: configuration)
    }
    
    override func setupCommon() {
        super.setupCommon()
        
        axis = .vertical
        preservesSuperviewLayoutMargins = true
        isLayoutMarginsRelativeArrangement = true
        
        addArrangedSubview(titleLabel)
        addArrangedSubview(valueTextView)
    }
    
    override func layoutMarginsDidChange() {
        super.layoutMarginsDidChange()
        let verticalSpacing = 11.0
        let horizontalSpacing = directionalLayoutMargins.leading
        layoutMargins = UIEdgeInsets(top: verticalSpacing, left: horizontalSpacing, bottom: verticalSpacing, right: horizontalSpacing)
    }
}

extension FieldView {
    
    private func apply(configuration: Configuration) {
        guard configuration != appliedConfiguration else { return }
        appliedConfiguration = configuration
        
        titleLabel.text = configuration.title
//        guard let htmlAttributedString = configuration.value?.htmlAttributedString(with: [.font: UIFont.preferredFont(forTextStyle: .body)]) else { return }
//        valueTextView.attributedText = htmlAttributedString
    }
}

extension FieldView {
    
    struct Configuration: Equatable, UIContentConfiguration {
        
        var title: String?
        
        var value: String?
        
        func makeContentView() -> any UIView & UIContentView {
            FieldView(configuration: self)
        }
        
        func updated(for state: any UIConfigurationState) -> FieldView.Configuration {
            self
        }
    }
}
