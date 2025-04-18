//
//  InstanceContentView.swift
//  MastodonAuthorizationUI
//
//  Created by Nikita Prokhorchuk on 5.12.24.
//

import UIKit
import UIKitFoundation
import UIKitUtilities
import SwiftUtilities

final class InstanceContentView: View, UIContentView {
    
    private var descriptionLabelBottomConstraint: NSLayoutConstraint!
    
    private var nameLabelBottomConstraint: NSLayoutConstraint!
    
    private var resizingTask: Task<Void, Never>?
    
    private let imageView: UIImageView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.backgroundColor = .tintColor.withAlphaComponent(0.15)
        $0.layer.cornerRadius = 13.0
        $0.layer.cornerCurve = .continuous
        $0.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return $0
    }(UIImageView(frame: .zero))
    
    private let nameLabel: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.font = .preferredFont(forTextStyle: .headline)
        $0.numberOfLines = 0
        return $0
    }(UILabel(frame: .zero))
    
    private let descriptionLabel: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.font = .preferredFont(forTextStyle: .subheadline)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 0
        return $0
    }(UILabel(frame: .zero))
    
    private let informationLabel: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.font = .preferredFont(forTextStyle: .subheadline)
        $0.textColor = .tintColor
        $0.numberOfLines = 1
        return $0
    }(UILabel(frame: .zero))
    
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
    
    deinit {
        resizingTask?.cancel()
    }
    
    override func setupCommon() {
        super.setupCommon()
        addSubview(imageView)
        addSubview(nameLabel)
        addSubview(informationLabel)
        addSubview(descriptionLabel)
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        nameLabelBottomConstraint = bottomAnchor.constraint(equalToSystemSpacingBelow: nameLabel.bottomAnchor, multiplier: 1.0)
        descriptionLabelBottomConstraint = bottomAnchor.constraint(equalToSystemSpacingBelow: descriptionLabel.bottomAnchor, multiplier: 1.0)
        
        nameLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        nameLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        informationLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        informationLabel.setContentHuggingPriority(.required, for: .horizontal)
        
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: imageView.trailingAnchor).priority(.defaultHigh),
            imageView.heightAnchor.constraint(equalToConstant: 200.0),
            
            nameLabel.topAnchor.constraint(equalToSystemSpacingBelow: imageView.bottomAnchor, multiplier: 1.0),
            nameLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 1.0),
            nameLabelBottomConstraint.priority(.defaultHigh),
            
            informationLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: nameLabel.trailingAnchor, multiplier: 1.0),
            trailingAnchor.constraint(equalToSystemSpacingAfter: informationLabel.trailingAnchor, multiplier: 1.0).priority(.defaultHigh),
            informationLabel.firstBaselineAnchor.constraint(equalTo: nameLabel.firstBaselineAnchor),
            
            descriptionLabel.topAnchor.constraint(equalToSystemSpacingBelow: nameLabel.bottomAnchor, multiplier: 1.0).priority(.defaultLow),
            descriptionLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 1.0),
            trailingAnchor.constraint(equalToSystemSpacingAfter: descriptionLabel.trailingAnchor, multiplier: 1.0),
            descriptionLabelBottomConstraint.priority(.defaultHigh),
        ])
    }
}

extension InstanceContentView {
    
    private func apply(configuration: Configuration) {
        guard configuration != appliedConfiguration else { return }
        appliedConfiguration = configuration
        
        resizingTask?.cancel()
        
        if let cgImage = configuration.image?.cgImage {
            resizingTask = Task {
                guard !Task.isCancelled else { return }
                let image = UIImage(cgImage: cgImage, scale: traitCollection.displayScale, orientation: .up)
                let thumbnailImage = await image.byPreparingThumbnail(ofSize: imageView.bounds.size)
                guard !Task.isCancelled else { return }
                let resultImage = await thumbnailImage?.byPreparingForDisplay()
                guard !Task.isCancelled else { return }
                UIView.transition(with: imageView, duration: CATransaction.animationDuration(), options: .transitionCrossDissolve) { [self] in
                    imageView.image = resultImage
                }
            }
        } else {
            imageView.image = nil
        }
        
        nameLabel.text = configuration.name
        
        descriptionLabel.text = configuration.description
        
        descriptionLabelBottomConstraint.isActive = configuration.description != nil
        nameLabelBottomConstraint.isActive = configuration.description == nil
        
        if let usersCount = configuration.usersCount,
           let statusesCount = configuration.statusesCount {
            informationLabel.text = "\(usersCount.roundedWithAbbreviations) users • \(statusesCount.roundedWithAbbreviations) posts"
        }
    }
}

extension InstanceContentView {
    
    struct Configuration: UIContentConfiguration, Hashable {
        
        var image: UIImage?
        
        var name: String?
        
        var description: String?
        
        var usersCount: Int?
        
        var statusesCount: Int?
        
        func makeContentView() -> any UIView & UIContentView {
            InstanceContentView(configuration: self)
        }
        
        func updated(for state: any UIConfigurationState) -> InstanceContentView.Configuration {
            self
        }
    }
}

extension InstanceContentView {
    
    struct BackgroundConfiguration {
        
        private init() {
        }
        
        static func configuration(for state: UICellConfigurationState) -> UIBackgroundConfiguration {
            var background = UIBackgroundConfiguration.clear()
            background.cornerRadius = 13.0
            background.backgroundColor = .secondarySystemGroupedBackground
            return background
        }
    }
}
