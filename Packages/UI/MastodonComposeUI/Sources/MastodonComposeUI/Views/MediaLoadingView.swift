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
    
    private let circularProgressView: CircularProgressView = {
        $0.isUserInteractionEnabled = false
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(CircularProgressView(frame: .zero))
    
    private let serverProcessingLabel: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.isUserInteractionEnabled = false
        $0.textColor = .white
        $0.text = "Server processing..."
        return $0
    }(UILabel(frame: .zero))
    
    private var resizingTask: Task<Void, Never>?
    
    var configuration: any Configuration = LoadingConfiguration() {
        didSet {
            switch configuration {
            case let loadingConfiguration as LoadingConfiguration:
                apply(loadingConfiguration: loadingConfiguration)
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
        addSubview(circularProgressView)
        addSubview(serverProcessingLabel)
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
            
            circularProgressView.widthAnchor.constraint(equalToConstant: 50.0),
            circularProgressView.heightAnchor.constraint(equalTo: circularProgressView.widthAnchor),
            circularProgressView.centerXAnchor.constraint(equalTo: centerXAnchor),
            circularProgressView.bottomAnchor.constraint(equalTo: centerYAnchor),
            
            serverProcessingLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            serverProcessingLabel.topAnchor.constraint(equalTo: centerYAnchor, constant: 8.0),
        ])
    }
    
    deinit {
        resizingTask?.cancel()
    }
}

extension MediaLoadingView {
    
    private func apply(loadingConfiguration: LoadingConfiguration) {
        if visualEffectView.isHidden { visualEffectView.isHidden = false }
        if circularProgressView.isHidden { circularProgressView.isHidden = false }
        if serverProcessingLabel.isHidden { serverProcessingLabel.isHidden = false }
        if let cgImage = loadingConfiguration.image?.cgImage {
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
        if !visualEffectView.isHidden { visualEffectView.isHidden = true }
        if !circularProgressView.isHidden { circularProgressView.isHidden = true }
        if !serverProcessingLabel.isHidden { serverProcessingLabel.isHidden = true }
    }
}

extension MediaLoadingView {
    
    protocol Configuration: Hashable {
    }
    
    struct LoadingConfiguration: Configuration {
        
        var image: UIImage?
        
        var progress: CGFloat?
        
        init() {
        }
    }
    
    struct LoadedConfiguration: Configuration {
    }
}
