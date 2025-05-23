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
        $0.backgroundColor = .clear
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
    
    weak var textViewDelegate: (any UITextViewDelegate)? {
        didSet { valueTextView.delegate = textViewDelegate }
    }
    
    init(configuration: Configuration) {
        super.init(frame: .zero)
        apply(configuration: configuration)
    }
    
    override func setupCommon() {
        super.setupCommon()
        
        let verticalSpacing = 11.0
        let horizontalSpacing = 16.0
        layoutMargins = UIEdgeInsets(top: verticalSpacing, left: horizontalSpacing, bottom: verticalSpacing, right: horizontalSpacing)
        axis = .vertical
        preservesSuperviewLayoutMargins = true
        isLayoutMarginsRelativeArrangement = true
        
        addArrangedSubview(titleLabel)
        addArrangedSubview(valueTextView)
    }
}

extension FieldView {
    
    private func apply(configuration: Configuration) {
        appliedConfiguration = configuration
        titleLabel.text = configuration.title
        valueTextView.attributedText = configuration.value?.parseHTML(withAttributes: [
            .font: UIFont.preferredFont(forTextStyle: .body),
            .foregroundColor: UIColor.label
        ])
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
