//
//  ImageDetailsViewController.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 10.01.25.
//

import UIKit
import UIKitFoundation
import FoundationUtilities

@MainActor
public protocol ImageDetailsViewControllerDelegate: AnyObject {
    
    func imageDetailsViewControllerDidFinish(_ viewController: ImageDetailsViewController)
}

public final class ImageDetailsViewController: ViewController {
    
    private let scrollView: UIScrollView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundColor = .black
        $0.contentInsetAdjustmentBehavior = .never
        $0.showsHorizontalScrollIndicator = false
        $0.showsVerticalScrollIndicator = false
        $0.alwaysBounceHorizontal = true
        $0.alwaysBounceVertical = true
        $0.maximumZoomScale = 2.0
        return $0
    }(UIScrollView(frame: .zero))
    
    private let imageView: UIImageView = {
        $0.clipsToBounds = true
        $0.contentMode = .scaleAspectFit
        return $0
    }(UIImageView(frame: .zero))
    
    private let closeButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "xmark")!
        configuration.baseForegroundColor = .white
        
        $0.configuration = configuration
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIButton())
    
    private var animationFinished = false
    
    public weak var interactiveAnimationController: ImageInteractiveAnimationController?
    
    private(set) public var isInteractivelyDismissing = false
    
    public weak var delegate: (any ImageDetailsViewControllerDelegate)?
    
    public var image: UIImage {
        didSet { imageView.image = image }
    }
    
    public init(image: UIImage) {
        self.image = image
        super.init()
        imageView.image = image
    }
    
    public override func setupCommon() {
        super.setupCommon()
        view.addSubview(scrollView)
        view.addSubview(closeButton)
        scrollView.addSubview(imageView)
        scrollView.delegate = self
        scrollView.setValue(true, forKey: valueKey(from: "cHJlc2VydmVzQ2VudGVyRHVyaW5nUm90YXRpb24=")) // preservesCenterDuringRotation
        scrollView.panGestureRecognizer.addTarget(self, action: #selector(handlePanGestureRecognizer))
        closeButton.addAction(UIAction { [unowned self] _ in
            dismiss(animated: true)
            delegate?.imageDetailsViewControllerDidFinish(self)
        }, for: .touchUpInside)
    }
    
    public override func setupViewConstraints() {
        super.setupViewConstraints()
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            
            closeButton.topAnchor.constraint(equalTo: view.layoutMarginsGuide.topAnchor),
            closeButton.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
        ])
    }
    
    public override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        imageView.frame.size = CGSize(width: view.frame.width, height: view.frame.width * image.size.height / image.size.width)
        imageView.center = view.center
    }
}

extension ImageDetailsViewController: UIScrollViewDelegate {
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
}

extension ImageDetailsViewController {
    
    @objc
    private func handlePanGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard scrollView.zoomScale <= 1.0 else { return }
        let percentageComplete = gestureRecognizer.translation(in: scrollView).y / view.frame.height
        animationFinished = percentageComplete > 0.2
        switch gestureRecognizer.state {
        case .began:
            isInteractivelyDismissing = true
            dismiss(animated: true) { [unowned self] in
                if animationFinished {
                    delegate?.imageDetailsViewControllerDidFinish(self)
                }
            }
        case .changed:
            interactiveAnimationController?.update(with: percentageComplete, translation: gestureRecognizer.translation(in: scrollView))
        case .ended:
            isInteractivelyDismissing = false
            interactiveAnimationController?.completeTransition(withoutFinishing: !animationFinished, with: gestureRecognizer.velocity(in: scrollView))
        default:
            break
        }
    }
}

extension ImageDetailsViewController: ImageAnimationTransitioningDelegate {
    
    public func willTransitionItem() {
        imageView.isHidden = true
    }
    
    public var item: TransitionItem? {
        TransitionItem(image: image, cornerRadius: 0.0)
    }
    
    public func itemFrame(in view: UIView) -> CGRect {
        imageView.frame
    }
    
    public func didTransitionItem() {
        imageView.isHidden = false
    }
}
