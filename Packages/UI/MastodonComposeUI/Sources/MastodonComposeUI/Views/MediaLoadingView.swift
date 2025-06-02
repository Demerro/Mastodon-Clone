//
//  MediaLoadingView.swift
//  MastodonComposeUI
//
//  Created by Nikita Prokhorchuk on 30.05.25.
//

import UIKit
import UIKitFoundation

final class MediaLoadingView: View {
    
    private static let cornerRadius: CGFloat = 10.0
    
    private let visualEffectView: UIVisualEffectView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.isUserInteractionEnabled = false
        $0.clipsToBounds = true
        $0.layer.cornerCurve = .continuous
        $0.layer.cornerRadius = MediaLoadingView.cornerRadius
        return $0
    }(UIVisualEffectView(effect: UIBlurEffect(style: .regular)))
    
    private let contentImageView: UIImageView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.isUserInteractionEnabled = false
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.layer.cornerCurve = .continuous
        $0.layer.cornerRadius = MediaLoadingView.cornerRadius
        return $0
    }(UIImageView(frame: .zero))
    
    private let activityIndicatorView: UIActivityIndicatorView = {
        $0.isUserInteractionEnabled = false
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.color = .white
        return $0
    }(UIActivityIndicatorView(style: .large))
    
    private let uploadingLabel: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.isUserInteractionEnabled = false
        $0.font = .preferredFont(forTextStyle: .headline)
        $0.textColor = .white
        $0.text = "Uploading..."
        return $0
    }(UILabel(frame: .zero))
    
    private var resizingTask: Task<Void, Never>?
    
    var configuration: any Configuration = PreparationConfiguration() {
        didSet {
            switch configuration {
            case let preparationConfiguration as PreparationConfiguration:
                apply(preparationConfiguration: preparationConfiguration)
            case let loadedConfiguration as LoadedConfiguration:
                apply(loadedConfiguration: loadedConfiguration)
            default:
                break
            }
        }
    }
    
    override func setupCommon() {
        super.setupCommon()
        
        addSubview(contentImageView)
        addSubview(visualEffectView)
        addSubview(activityIndicatorView)
        addSubview(uploadingLabel)
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        NSLayoutConstraint.activate([
            contentImageView.topAnchor.constraint(equalTo: topAnchor),
            contentImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: contentImageView.trailingAnchor),
            bottomAnchor.constraint(equalTo: contentImageView.bottomAnchor),
            
            visualEffectView.topAnchor.constraint(equalTo: topAnchor),
            visualEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
            bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor),
            
            activityIndicatorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            activityIndicatorView.bottomAnchor.constraint(equalTo: centerYAnchor),
            
            uploadingLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            uploadingLabel.topAnchor.constraint(equalTo: centerYAnchor, constant: 4.0),
        ])
    }
    
    deinit {
        resizingTask?.cancel()
    }
}

extension MediaLoadingView {
    
    private func apply(preparationConfiguration: PreparationConfiguration) {
        visualEffectView.alpha = 1.0
        visualEffectView.isHidden = false
        activityIndicatorView.alpha = 1.0
        activityIndicatorView.isHidden = false
        uploadingLabel.alpha = 1.0
        uploadingLabel.isHidden = false
        
        activityIndicatorView.startAnimating()
        
        if let cgImage = preparationConfiguration.image?.cgImage {
            resizingTask = Task {
                let image = UIImage(cgImage: cgImage, scale: traitCollection.displayScale, orientation: .up)
                let thumbnailImage = await image.byPreparingThumbnail(ofSize: contentImageView.bounds.size)
                let resultImage = await thumbnailImage?.byPreparingForDisplay()
                UIView.transition(with: contentImageView, duration: CATransaction.animationDuration(), options: .transitionCrossDissolve) { [self] in
                    contentImageView.image = resultImage
                }
            }
        } else {
            contentImageView.image = nil
        }
    }
    
    private func apply(loadedConfiguration: LoadedConfiguration) {
        activityIndicatorView.stopAnimating()
        UIViewPropertyAnimator.runningPropertyAnimator(withDuration: CATransaction.animationDuration(), delay: 0.0) { [self] in
            visualEffectView.alpha = 0.0
            activityIndicatorView.alpha = 0.0
            uploadingLabel.alpha = 0.0
        } completion: { [weak self] _ in
            guard let self else { return }
            visualEffectView.isHidden = true
            activityIndicatorView.isHidden = true
            uploadingLabel.isHidden = true
        }
    }
}

extension MediaLoadingView {
    
    protocol Configuration: Hashable {
    }
    
    struct PreparationConfiguration: Configuration {
        
        var image: UIImage?
        
        init() {
        }
    }
    
    struct LoadedConfiguration: Configuration {
    }
}
