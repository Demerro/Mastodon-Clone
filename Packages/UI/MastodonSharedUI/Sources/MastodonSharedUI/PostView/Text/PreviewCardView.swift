//
//  PreviewCardView.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 29.01.25.
//

import UIKit
import UIKitFoundation

public final class PreviewCardView: View {
    
    private let imageView: UIImageView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.clipsToBounds = true
        $0.contentMode = .scaleAspectFill
        $0.backgroundColor = .systemGray6
        $0.layer.cornerRadius = 10.0
        $0.layer.cornerCurve = .continuous
        $0.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return $0
    }(UIImageView(frame: .zero))
    
    private let titleLabel: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.font = .preferredFont(forTextStyle: .headline)
        $0.numberOfLines = 0
        return $0
    }(UILabel(frame: .zero))
    
    private let descriptionLabel: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.font = .preferredFont(forTextStyle: .footnote)
        $0.textColor = .secondaryLabel
        $0.numberOfLines = 3
        return $0
    }(UILabel(frame: .zero))
    
    private let providerLabel: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.font = .preferredFont(forTextStyle: .footnote)
        $0.textColor = .tintColor
        return $0
    }(UILabel(frame: .zero))
    
    private var resizingTask: Task<Void, Never>?
   
    private var needsApplyConfiguration = false
    
    private var oldConstraints = [NSLayoutConstraint]()
    
    public var configuration: (any Configuration)? {
        didSet { setNeedsApplyConfiguration() }
    }
    
    public override func setupCommon() {
        super.setupCommon()
        backgroundColor = .systemGray6
        layer.cornerRadius = 10.0
        layer.cornerCurve = .continuous
        
        addSubview(imageView)
        addSubview(titleLabel)
        addSubview(descriptionLabel)
        addSubview(providerLabel)
    }
    
    public override func setupConstraints() {
        super.setupConstraints()
        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 1.0),
            trailingAnchor.constraint(equalToSystemSpacingAfter: titleLabel.trailingAnchor, multiplier: 1.0),
            
            providerLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 1.0),
            trailingAnchor.constraint(equalToSystemSpacingAfter: providerLabel.trailingAnchor, multiplier: 1.0),
            bottomAnchor.constraint(equalToSystemSpacingBelow: providerLabel.bottomAnchor, multiplier: 1.0),
        ])
    }
    
    public override func updateConstraints() {
        applyConfigurationIfNeeded()
        super.updateConstraints()
    }
    
    deinit {
        resizingTask?.cancel()
    }
}

extension PreviewCardView {
    
    private func setNeedsApplyConfiguration() {
        guard !needsApplyConfiguration else { return }
        needsApplyConfiguration = true
        setNeedsUpdateConstraints()
    }
    
    private func applyConfigurationIfNeeded() {
        guard needsApplyConfiguration else { return }
        needsApplyConfiguration = false
        
        switch configuration {
        case let contentConfiguration as ContentConfiguration:
            apply(contentConfiguration: contentConfiguration)
        case let imageConfiguration as ImageConfiguration:
            apply(imageConfiguration: imageConfiguration)
        case is EmptyConfiguration:
            applyEmptyConfiguration()
        default:
            assertionFailure()
        }
    }
    
    private func apply(contentConfiguration: ContentConfiguration) {
        var constraints = [NSLayoutConstraint]()
        
        imageView.isHidden = contentConfiguration.imageSize == .zero
        imageView.image = nil
        if imageView.isHidden {
            constraints += [
                titleLabel.topAnchor.constraint(equalToSystemSpacingBelow: topAnchor, multiplier: 1.0),
            ]
        } else {
            constraints += [
                imageView.topAnchor.constraint(equalTo: topAnchor),
                imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
                trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
                imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: contentConfiguration.imageSize.width / contentConfiguration.imageSize.height),
                titleLabel.topAnchor.constraint(equalToSystemSpacingBelow: imageView.bottomAnchor, multiplier: 1.0),
            ]
        }
        
        titleLabel.text = contentConfiguration.title
        
        descriptionLabel.text = contentConfiguration.description
        descriptionLabel.isHidden = contentConfiguration.description.isEmpty
        if descriptionLabel.isHidden {
            constraints += [
                providerLabel.topAnchor.constraint(equalToSystemSpacingBelow: titleLabel.bottomAnchor, multiplier: 1.0)
            ]
        } else {
            constraints += [
                descriptionLabel.topAnchor.constraint(equalToSystemSpacingBelow: titleLabel.bottomAnchor, multiplier: 1.0),
                descriptionLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 1.0),
                trailingAnchor.constraint(equalToSystemSpacingAfter: descriptionLabel.trailingAnchor, multiplier: 1.0),
                providerLabel.topAnchor.constraint(equalToSystemSpacingBelow: descriptionLabel.bottomAnchor, multiplier: 1.0),
            ]
        }
        
        providerLabel.text = contentConfiguration.providerHost
        
        NSLayoutConstraint.deactivate(oldConstraints)
        NSLayoutConstraint.activate(constraints)
        oldConstraints = constraints
    }
    
    private func apply(imageConfiguration: ImageConfiguration) {
        resizingTask?.cancel()
        guard let cgImage = imageConfiguration.image?.cgImage else {
            imageView.image = nil
            return
        }
        resizingTask = Task {
            guard !Task.isCancelled else { return }
            let image = UIImage(cgImage: cgImage, scale: traitCollection.displayScale, orientation: .up)
            let thumbnailImage = await image.byPreparingThumbnail(ofSize: imageView.bounds.size)
            guard !Task.isCancelled else { return }
            guard let resultImage = await thumbnailImage?.byPreparingForDisplay() else { return }
            guard !Task.isCancelled else { return }
            UIView.transition(with: imageView, duration: CATransaction.animationDuration(), options: .transitionCrossDissolve) {
                self.imageView.image = resultImage
            }
        }
    }
    
    private func applyEmptyConfiguration() {
        imageView.image = nil
        titleLabel.text = nil
        descriptionLabel.text = nil
        providerLabel.text = nil
    }
}

extension PreviewCardView {
    
    public protocol Configuration: Sendable {
    }
    
    public struct ContentConfiguration: Configuration {
        
        public let imageSize: CGSize
        
        public let title: String
        
        public let description: String
        
        public let providerHost: String
        
        public init(imageSize: CGSize, title: String, description: String, providerHost: String) {
            self.imageSize = imageSize
            self.title = title
            self.description = description
            self.providerHost = providerHost
        }
    }
    
    public struct ImageConfiguration: Configuration {
        
        public let image: UIImage?
        
        public init(image: UIImage?) {
            self.image = image
        }
    }
    
    public struct EmptyConfiguration: Configuration {
        
        public init() {
        }
    }
}
