//
//  ComposeView.swift
//  MastodonComposeUI
//
//  Created by Nikita Prokhorchuk on 25.05.25.
//

import UIKit
import UIKitFoundation

final class ComposeView: View {
    
    let scrollView: UIScrollView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.preservesSuperviewLayoutMargins = true
        $0.showsHorizontalScrollIndicator = false
        $0.alwaysBounceVertical = true
        return $0
    }(UIScrollView(frame: .zero))
    
    let stackView: UIStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.axis = .vertical
        $0.preservesSuperviewLayoutMargins = true
        $0.isLayoutMarginsRelativeArrangement = true
        return $0
    }(UIStackView(frame: .zero))
    
    let textView: ComposeTextView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.clipsToBounds = true
        $0.keyboardType = .twitter
        $0.textContainer.lineFragmentPadding = 0.0
        $0.placeholderLabel.text = "Type or paste what's on your mind"
        return $0
    }(ComposeTextView(frame: .zero))
    
    lazy var spoilerTextField: SpoilerTextField = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.isHidden = true
        $0.alpha = 0.0
        return $0
    }(SpoilerTextField(frame: .zero))
    
    let toolbar: Toolbar = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.preservesSuperviewLayoutMargins = true
        return $0
    }(Toolbar(frame: .zero))
    
    override func setupCommon() {
        super.setupCommon()
        
        backgroundColor = .systemBackground
        
        addSubview(scrollView)
        addSubview(toolbar)
        scrollView.addSubview(stackView)
        stackView.addArrangedSubview(textView)
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        NSLayoutConstraint.activate([
            toolbar.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            layoutMarginsGuide.trailingAnchor.constraint(equalTo: toolbar.trailingAnchor),
            keyboardLayoutGuide.topAnchor.constraint(equalToSystemSpacingBelow: toolbar.bottomAnchor, multiplier: 1.0),
            
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            keyboardLayoutGuide.topAnchor.constraint(equalTo: scrollView.bottomAnchor),
            
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: stackView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: stackView.bottomAnchor),
        ])
    }
    
    override func setupAfterLayoutSubviews() {
        super.setupAfterLayoutSubviews()
        RunLoop.current.perform { [self] in
            MainActor.assumeIsolated {
                scrollView.contentInset.bottom = toolbar.frame.height + stackView.spacing
            }
        }
    }
    
    override func layoutMarginsDidChange() {
        super.layoutMarginsDidChange()
        let spacing = directionalLayoutMargins.leading
        stackView.layoutMargins = UIEdgeInsets(top: 0.0, left: spacing, bottom: 0.0, right: spacing)
        stackView.spacing = spacing
    }
}
