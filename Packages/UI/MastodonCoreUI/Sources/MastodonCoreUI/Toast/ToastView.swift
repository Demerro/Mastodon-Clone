//
//  ToastView.swift
//  MastodonCoreUI
//
//  Created by Nikita Prokhorchuk on 15.08.25.
//

import UIKit

final class ToastView: UIView {
    
    static var defaultContentColor = UIColor { trait in
        switch trait.userInterfaceStyle {
        case .dark:
            UIColor(red: 127.0 / 255.0, green: 127.0 / 255.0, blue: 129.0 / 255.0, alpha: 1.0)
        default:
            UIColor(red: 88.0 / 255.0, green: 87.0 / 255.0, blue: 88.0 / 255.0, alpha: 1.0)
        }
    }
    
    private let visualEffectView: UIVisualEffectView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial)))
    
    private let imageView: UIImageView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.tintColor = ToastView.defaultContentColor
        $0.contentMode = .center
        return $0
    }(UIImageView(frame: .zero))
    
    private let label: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.font = .preferredFont(forTextStyle: .headline)
        $0.textColor = ToastView.defaultContentColor
        return $0
    }(UILabel())
    
    private let activityIndicatorView: UIActivityIndicatorView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.color = ToastView.defaultContentColor
        $0.style = .medium
        return $0
    }(UIActivityIndicatorView())
    
    private var oldConstraints = [NSLayoutConstraint]()
    
    private var needsApplyConfiguration = false
    
    var configuration: Configuration = EmptyConfiguration() {
        didSet { setNeedsApplyConfiguration() }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCommon()
        setupConstraints()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = bounds.height / 4.0
    }
    
    override func updateConstraints() {
        applyConfigurationIfNeeded()
        super.updateConstraints()
    }
}

extension ToastView {
    
    private func setupCommon() {
        isUserInteractionEnabled = false
        clipsToBounds = true
        addSubview(visualEffectView)
        addSubview(imageView)
        addSubview(label)
        addSubview(activityIndicatorView)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            visualEffectView.topAnchor.constraint(equalTo: topAnchor),
            visualEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
            bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor),
            
            imageView.topAnchor.constraint(equalToSystemSpacingBelow: topAnchor, multiplier: 1.0),
            bottomAnchor.constraint(equalToSystemSpacingBelow: imageView.bottomAnchor, multiplier: 1.0),
            
            label.topAnchor.constraint(equalToSystemSpacingBelow: topAnchor, multiplier: 1.0),
            bottomAnchor.constraint(equalToSystemSpacingBelow: label.bottomAnchor, multiplier: 1.0),
            
            activityIndicatorView.topAnchor.constraint(equalToSystemSpacingBelow: topAnchor, multiplier: 1.0),
            bottomAnchor.constraint(equalToSystemSpacingBelow: activityIndicatorView.bottomAnchor, multiplier: 1.0),
        ])
    }
}

extension ToastView {
    
    private func setNeedsApplyConfiguration() {
        guard !needsApplyConfiguration else { return }
        needsApplyConfiguration = true
        setNeedsUpdateConstraints()
    }
    
    private func applyConfigurationIfNeeded() {
        guard needsApplyConfiguration else { return }
        needsApplyConfiguration = false
        
        switch configuration {
        case is EmptyConfiguration:
            applyEmptyConfiguration()
        case let configuration as DefaultConfiguration:
            applyDefaultConfiguration(configuration)
        case let configuration as TextConfiguration:
            applyTextConfiguration(configuration)
        case let configuration as LoadingConfiguration:
            applyLoadingConfiguration(configuration)
        default:
            preconditionFailure("Unsupported configuration type: \(type(of: configuration))")
        }
    }
    
    private func applyEmptyConfiguration() {
        label.text = nil
        imageView.image = nil
        activityIndicatorView.stopAnimating()
    }
    
    private func applyDefaultConfiguration(_ configuration: DefaultConfiguration) {
        label.text = configuration.text
        imageView.image = configuration.image
        
        let constraints = [
            imageView.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 1.0),
            label.leadingAnchor.constraint(equalToSystemSpacingAfter: imageView.trailingAnchor, multiplier: 1.0),
            
            label.topAnchor.constraint(equalToSystemSpacingBelow: topAnchor, multiplier: 1.0),
            trailingAnchor.constraint(equalToSystemSpacingAfter: label.trailingAnchor, multiplier: 1.0),
        ]
        NSLayoutConstraint.deactivate(oldConstraints)
        NSLayoutConstraint.activate(constraints)
        oldConstraints = constraints
    }
    
    private func applyTextConfiguration(_ configuration: TextConfiguration) {
        label.text = configuration.text
        imageView.image = nil
        let constraints = [
            label.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 1.0),
            trailingAnchor.constraint(equalToSystemSpacingAfter: label.trailingAnchor, multiplier: 1.0),
        ]
        NSLayoutConstraint.deactivate(oldConstraints)
        NSLayoutConstraint.activate(constraints)
        oldConstraints = constraints
    }
    
    private func applyLoadingConfiguration(_ configuration: LoadingConfiguration) {
        label.text = configuration.text
        imageView.image = nil
        activityIndicatorView.startAnimating()
        
        let constraints = [
            activityIndicatorView.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 1.0),
            label.leadingAnchor.constraint(equalToSystemSpacingAfter: activityIndicatorView.trailingAnchor, multiplier: 1.0),
            trailingAnchor.constraint(equalToSystemSpacingAfter: label.trailingAnchor, multiplier: 1.0),
        ]
        NSLayoutConstraint.deactivate(oldConstraints)
        NSLayoutConstraint.activate(constraints)
        oldConstraints = constraints
    }
}

extension ToastView {
    
    protocol Configuration {
    }
    
    struct EmptyConfiguration: Configuration {
    }
    
    struct DefaultConfiguration: Configuration {
        var text: String
        var image: UIImage
    }
    
    struct TextConfiguration: Configuration {
        var text: String
    }
    
    struct LoadingConfiguration: Configuration {
        var text: String
    }
}
