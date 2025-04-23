//
//  VideoPreviewView.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 31.01.25.
//

import UIKit
import UIKitFoundation

public final class VideoPreviewView: View {
    
    let imageView: UIImageView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.clipsToBounds = true
        $0.backgroundColor = .systemGray6
        $0.contentMode = .scaleAspectFill
        return $0
    }(UIImageView(frame: .zero))
    
    private let playImageView: UIImageView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.image = UIImage(systemName: "play.fill")!
        $0.tintColor = .white
        $0.preferredSymbolConfiguration = .init(pointSize: 32.0)
        return $0
    }(UIImageView(frame: .zero))
    
    private let playImageViewBackground: UIView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.isUserInteractionEnabled = false
        $0.backgroundColor = .black.withAlphaComponent(0.5)
        $0.layer.cornerCurve = .continuous
        return $0
    }(UIView(frame: .zero))
    
    private let durationLabel: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.font = .preferredFont(forTextStyle: .headline)
        $0.textColor = .white
        return $0
    }(UILabel(frame: .zero))
    
    private let durationLabelBackgroundView: UIView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.isUserInteractionEnabled = false
        $0.backgroundColor = .black.withAlphaComponent(0.5)
        $0.layer.cornerCurve = .continuous
        $0.layer.cornerRadius = 5.0
        return $0
    }(UIView(frame: .zero))
    
    private var resizingTask: Task<Void, Never>?
    
    private var needsApplyConfiguration = false
    
    private var previewImageViewHeightConstraint: NSLayoutConstraint?
    
    public var configuration: (any Configuration)? {
        didSet { setNeedsApplyConfiguration() }
    }
    
    public override func setupCommon() {
        super.setupCommon()
        
        addSubview(imageView)
        
        addSubview(playImageViewBackground)
        playImageViewBackground.addSubview(playImageView)
        
        addSubview(durationLabelBackgroundView)
        durationLabelBackgroundView.addSubview(durationLabel)
        
        RunLoop.current.add(Timer(timeInterval: 0.0, repeats: false) { [self] _ in
            MainActor.assumeIsolated { playImageViewBackground.layer.cornerRadius = playImageViewBackground.frame.width / 2.0 }
        }, forMode: .common)
    }
    
    public override func setupConstraints() {
        super.setupConstraints()
        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            bottomAnchor.constraint(equalTo: imageView.bottomAnchor),
            
            playImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            playImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            
            playImageViewBackground.widthAnchor.constraint(equalToConstant: 48.0),
            playImageViewBackground.heightAnchor.constraint(equalTo: playImageViewBackground.widthAnchor),
            playImageViewBackground.centerXAnchor.constraint(equalTo: playImageView.centerXAnchor),
            playImageViewBackground.centerYAnchor.constraint(equalTo: playImageView.centerYAnchor),
            
            durationLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 2.0),
            bottomAnchor.constraint(equalToSystemSpacingBelow: durationLabel.bottomAnchor, multiplier: 2.0),
            
            durationLabel.topAnchor.constraint(equalToSystemSpacingBelow: durationLabelBackgroundView.topAnchor, multiplier: 0.5),
            durationLabel.leadingAnchor.constraint(equalToSystemSpacingAfter: durationLabelBackgroundView.leadingAnchor, multiplier: 0.5),
            durationLabelBackgroundView.trailingAnchor.constraint(equalToSystemSpacingAfter: durationLabel.trailingAnchor, multiplier: 0.5),
            durationLabelBackgroundView.bottomAnchor.constraint(equalToSystemSpacingBelow: durationLabel.bottomAnchor, multiplier: 0.5),
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

extension VideoPreviewView {
    
    private func setNeedsApplyConfiguration() {
        guard !needsApplyConfiguration else { return }
        needsApplyConfiguration = true
        setNeedsUpdateConstraints()
    }
    
    private func applyConfigurationIfNeeded() {
        guard needsApplyConfiguration else { return }
        needsApplyConfiguration = false

        switch configuration {
        case let preparationConfiguration as PreparationConfiguration:
            apply(preparationConfiguration: preparationConfiguration)
        case let contentConfiguration as ContentConfiguration:
            apply(contentConfiguration: contentConfiguration)
        case is EmptyConfiguration:
            applyEmptyConfiguration()
        default:
            assertionFailure()
        }
    }
    
    private func apply(preparationConfiguration configuration: PreparationConfiguration) {
        durationLabel.text = format(duration: configuration.videoDuration)
        imageView.image = nil
        
        if let previewImageViewHeightConstraint { NSLayoutConstraint.deactivate([previewImageViewHeightConstraint]) }
        previewImageViewHeightConstraint = imageView.widthAnchor.constraint(equalTo: imageView.heightAnchor, multiplier: configuration.previewAspectRatio)
        NSLayoutConstraint.activate([previewImageViewHeightConstraint!])
    }
    
    private func apply(contentConfiguration configuration: ContentConfiguration) {
        resizingTask?.cancel()
        if let cgImage = configuration.previewImage?.cgImage {
            resizingTask = Task {
                guard !Task.isCancelled else { return }
                let image = UIImage(cgImage: cgImage, scale: traitCollection.displayScale, orientation: .up)
                let thumbnailImage = await image.byPreparingThumbnail(ofSize: imageView.bounds.size)
                guard !Task.isCancelled else { return }
                let resultImage = await thumbnailImage?.byPreparingForDisplay()
                guard !Task.isCancelled else { return }
                UIView.transition(with: imageView, duration: CATransaction.animationDuration(), options: .transitionCrossDissolve) {
                    self.imageView.image = resultImage
                }
            }
        } else {
            imageView.image = nil
        }
    }
    
    private func applyEmptyConfiguration() {
        resizingTask?.cancel()
        durationLabel.text = nil
        imageView.image = nil
    }
}

extension VideoPreviewView {
    
    private func format(duration: Double) -> String {
        let totalSeconds = Int(duration)

        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let seconds = totalSeconds % 60

        return hours > 0 ? String(format: "%2d:%02d:%02d", hours, minutes, seconds) : String(format: "%02d:%02d", minutes, seconds)
    }
}

extension VideoPreviewView {
    
    public protocol Configuration {
    }
    
    public struct PreparationConfiguration: Sendable, Hashable, Configuration {
        
        public let videoDuration: TimeInterval
        
        public let previewAspectRatio: CGFloat
        
        public init(videoDuration: TimeInterval, previewAspectRatio: CGFloat) {
            self.videoDuration = videoDuration
            self.previewAspectRatio = previewAspectRatio
        }
    }
    
    public struct ContentConfiguration: Sendable, Hashable, Configuration {
        
        public let previewImage: UIImage?
        
        public init(previewImage: UIImage?) {
            self.previewImage = previewImage
        }
    }
    
    public struct EmptyConfiguration: Sendable, Hashable, Configuration {

        public init() {
        }
    }
}
