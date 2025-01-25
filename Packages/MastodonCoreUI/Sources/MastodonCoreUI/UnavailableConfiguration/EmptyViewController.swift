//
//  EmptyViewController.swift
//  MastodonCoreUI
//
//  Created by Nikita Prokhorchuk on 11.01.25.
//

import UIKit
import UIKitFoundation

@MainActor
public protocol EmptyViewControllerDelegate: AnyObject {
    
    func emptyViewControllerDidTapRetryButton(_ viewController: EmptyViewController)
}

public final class EmptyViewController: ViewController {
    
    private let emptyView = _EmptyView(frame: .zero)
    
    public var delegate: (any EmptyViewControllerDelegate)?
    
    public var contentConfiguration: UnavailableConfiguration {
        didSet {
            guard contentConfiguration != oldValue else { return }
            apply(configuration: contentConfiguration)
        }
    }
    
    public init(contentConfiguration: UnavailableConfiguration) {
        self.contentConfiguration = contentConfiguration
        super.init()
        apply(configuration: contentConfiguration)
    }
    
    public override func setupCommon() {
        super.setupCommon()
        emptyView.retryButton.addAction(UIAction { [unowned self] _ in
            delegate?.emptyViewControllerDidTapRetryButton(self)
        }, for: .touchUpInside)
    }
    
    public override func loadView() {
        view = emptyView
    }
    
    private func apply(configuration: UnavailableConfiguration) {
        emptyView.imageView.image = configuration.image
        emptyView.textLabel.text = configuration.text
        emptyView.secondaryTextLabel.text = configuration.secondaryText
    }
}

fileprivate final class _EmptyView: View {
    
    private let stackView: UIStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.axis = .vertical
        $0.alignment = .center
        $0.spacing = 2.0
        return $0
    }(UIStackView(frame: .zero))
    
    let imageView: UIImageView = {
        $0.tintColor = .secondaryLabel
        $0.contentMode = .center
        $0.clipsToBounds = true
        $0.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 48.0)
        return $0
    }(UIImageView(frame: .zero))
    
    let textLabel: UILabel = {
        $0.font = .preferredFont(forTextStyle: .title2, compatibleWith: UITraitCollection(legibilityWeight: .bold))
        $0.numberOfLines = 0
        $0.textAlignment = .center
        return $0
    }(UILabel(frame: .zero))
    
    let secondaryTextLabel: UILabel = {
        $0.font = .preferredFont(forTextStyle: .subheadline)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 0
        $0.textAlignment = .center
        return $0
    }(UILabel(frame: .zero))
    
    let retryButton: UIButton = {
        var configuration = UIButton.Configuration.borderless()
        configuration.image = UIImage(systemName: "arrow.clockwise.circle.fill")
        return UIButton(configuration: configuration)
    }()
    
    override func setupCommon() {
        super.setupCommon()
        
        addSubview(stackView)
        stackView.addArrangedSubview(imageView)
        stackView.addArrangedSubview(textLabel)
        stackView.addArrangedSubview(secondaryTextLabel)
        stackView.addArrangedSubview(retryButton)
        
        stackView.setCustomSpacing(8.0, after: imageView)
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            trailingAnchor.constraint(greaterThanOrEqualTo: stackView.trailingAnchor),
            stackView.centerYAnchor.constraint(equalTo: centerYAnchor),
            stackView.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }
}
