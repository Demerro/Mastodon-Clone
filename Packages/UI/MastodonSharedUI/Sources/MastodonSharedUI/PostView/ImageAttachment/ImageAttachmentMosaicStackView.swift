//
//  ImageAttachmentMosaicStackView.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 30.01.25.
//

import UIKit
import UIKitFoundation

public final class ImageAttachmentMosaicStackView: StackView {
    
    private let leftStackView: UIStackView = {
        $0.axis = .vertical
        $0.distribution = .fillEqually
        $0.spacing = 2.0
        return $0
    }(UIStackView(frame: .zero))
    
    private let rightStackView: UIStackView = {
        $0.axis = .vertical
        $0.distribution = .fillEqually
        $0.spacing = 2.0
        return $0
    }(UIStackView(frame: .zero))
    
    private(set) public var imageViews = [UIImageView]()
    
    private var resizingTask: Task<Void, Never>?
    
    private var heightConstraint: NSLayoutConstraint?
    
    private var needsApplyConfiguration = false
    
    public var configuration: Configuration = EmptyConfiguration() {
        didSet { setNeedsApplyConfiguration() }
    }
    
    public override func setupCommon() {
        super.setupCommon()
        imageViews.reserveCapacity(4)
        axis = .horizontal
        distribution = .fillEqually
        spacing = 2.0
        addArrangedSubview(leftStackView)
        addArrangedSubview(rightStackView)
    }
    
    public override func updateConstraints() {
        applyConfigurationIfNeeded()
        super.updateConstraints()
    }
    
    deinit {
        resizingTask?.cancel()
    }
}

extension ImageAttachmentMosaicStackView {
    
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
        for subview in leftStackView.subviews + rightStackView.subviews {
            subview.removeFromSuperview()
        }
        
        imageViews = (0..<configuration.imagesCount).map { _ in makeImageView() }
        
        switch imageViews.count {
        case 1:
            rightStackView.isHidden = true
            leftStackView.addArrangedSubview(imageViews[0])
        case 2...3:
            rightStackView.isHidden = false
            leftStackView.addArrangedSubview(imageViews[0])
            for view in imageViews[1...] {
                rightStackView.addArrangedSubview(view)
            }
        case 4:
            rightStackView.isHidden = false
            for view in [imageViews[0], imageViews[2]] {
                leftStackView.addArrangedSubview(view)
            }
            for view in [imageViews[1], imageViews[3]] {
                rightStackView.addArrangedSubview(view)
            }
        default:
            preconditionFailure("Unexpected number of collage subviews")
        }
        
        if let heightConstraint { NSLayoutConstraint.deactivate([heightConstraint]) }
        heightConstraint = if configuration.imagesCount == 1 {
            widthAnchor.constraint(equalTo: heightAnchor, multiplier: configuration.singleImageAspectRatio)
        } else {
            heightAnchor.constraint(equalToConstant: 300.0)
        }
        NSLayoutConstraint.activate([heightConstraint!])
    }
    
    private func apply(contentConfiguration configuration: ContentConfiguration) {
        resizingTask?.cancel()
        resizingTask = Task {
            guard configuration.images.count == imageViews.count else {
                assertionFailure("Mismatch amount")
                return
            }
            let images = await withTaskGroup(of: (Int, UIImage?).self) { [weak self] taskGroup in
                guard let self else { return [Int: UIImage?]() }
                for (index, imageView) in imageViews.enumerated() {
                    taskGroup.addTask {
                        guard let cgImage = configuration.images[index]?.cgImage,
                              !Task.isCancelled
                        else {
                            return (index, nil)
                        }
                        let image = await UIImage(cgImage: cgImage, scale: self.traitCollection.displayScale, orientation: .up)
                        guard !Task.isCancelled else { return (index, nil) }
                        let thumbnailImage = await image.byPreparingThumbnail(ofSize: imageView.frame.size)
                        guard !Task.isCancelled else { return (index, nil) }
                        return (index, await thumbnailImage?.byPreparingForDisplay())
                    }
                }
                return await taskGroup.reduce(into: [Int: UIImage?]()) { result, element in
                    result[element.0] = element.1
                }
            }
            
            for (index, imageView) in imageViews.enumerated() {
                UIView.transition(with: imageView, duration: CATransaction.animationDuration(), options: .transitionCrossDissolve) {
                    imageView.image = images[index] ?? nil
                }
            }
        }
    }
    
    private func applyEmptyConfiguration() {
        resizingTask?.cancel()
        imageViews.removeAll()
        for subview in leftStackView.subviews + rightStackView.subviews {
            subview.removeFromSuperview()
        }
    }
}

extension ImageAttachmentMosaicStackView {
    
    private func makeImageView() -> UIImageView {
        let imageView = UIImageView(frame: .zero)
        imageView.backgroundColor = .systemGray6
        imageView.clipsToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }
}

extension ImageAttachmentMosaicStackView {
    
    public protocol Configuration {
    }
    
    public struct PreparationConfiguration: Configuration, Sendable, Hashable {
        
        public let singleImageAspectRatio: CGFloat
        
        public let imagesCount: Int
        
        public init(singleImageAspectRatio: CGFloat, imagesCount: Int) {
            self.singleImageAspectRatio = singleImageAspectRatio
            self.imagesCount = imagesCount
        }
    }
    
    public struct ContentConfiguration: Configuration, Sendable, Hashable {
        
        public let images: [UIImage?]
        
        public init(images: [UIImage?]) {
            self.images = images
        }
    }
    
    public struct EmptyConfiguration: Configuration, Sendable, Hashable {
        
        public init() {
        }
    }
}
