//
//  ImageDetailsViewController.swift
//  MastodonProfileUI
//
//  Created by Nikita Prokhorchuk on 10.01.25.
//

import UIKit
import UIKitFoundation
import FoundationUtilities

@MainActor
protocol ImageDetailsViewControllerDelegate: AnyObject {
    
    func imageDetailsViewControllerDidFinish(_ viewController: ImageDetailsViewController)
}

final class ImageDetailsViewController: ViewController {
    
    private let scrollView: UIScrollView = {
        $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        $0.backgroundColor = .systemBackground
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
    
    var isInteractivelyDismissing = false
    
    weak var transitionController: ImageDetailsInteractivePopTransition? = nil
    
    weak var delegate: (any ImageDetailsViewControllerDelegate)?
    
    var image: UIImage {
        didSet { imageView.image = image }
    }
    
    init(image: UIImage) {
        self.image = image
        super.init()
        imageView.image = image
    }
    
    override func setupCommon() {
        super.setupCommon()
        scrollView.addSubview(imageView)
        scrollView.delegate = self
        scrollView.setValue(true, forKey: valueKey(from: "cHJlc2VydmVzQ2VudGVyRHVyaW5nUm90YXRpb24="))
        scrollView.panGestureRecognizer.addTarget(self, action: #selector(handlePan))
        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close, primaryAction: UIAction { [unowned self] _ in
            delegate?.imageDetailsViewControllerDidFinish(self)
        })
    }
    
    override func viewIsAppearing(_ animated: Bool) {
        super.viewIsAppearing(animated)
        imageView.frame.size = CGSize(width: view.frame.width, height: view.frame.width)
        imageView.center = view.center
    }
    
    override func loadView() {
        view = scrollView
    }
}

extension ImageDetailsViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        imageView
    }
}

extension ImageDetailsViewController {
    
    @objc
    private func handlePan(_ gestureRecognizer: UIPanGestureRecognizer) {
        guard scrollView.zoomScale <= 1.0 else { return }
        
        switch gestureRecognizer.state {
        case .began:
            isInteractivelyDismissing = true
            delegate?.imageDetailsViewControllerDidFinish(self)
        case .cancelled, .ended, .failed:
            isInteractivelyDismissing = false
        default:
            break
        }
        
        transitionController?.updateInteractiveTransition(with: gestureRecognizer)
    }
}

extension ImageDetailsViewController: ImageDetailsTransitioningDelegate {
    
    func willTransitionItemWith(context: any UIViewControllerContextTransitioning, coordinator: (any UIViewControllerTransitionCoordinator)?) {
        imageView.isHidden = true
    }
    
    func item(forTransitionWith context: any UIViewControllerContextTransitioning) -> ImageDetailsItem {
        ImageDetailsItem(image: image, cornerRadius: .zero, borderWidth: .zero, borderColor: nil)
    }
    
    func itemFrame(in view: UIView, forTransitionWith context: any UIViewControllerContextTransitioning) -> CGRect {
        imageView.frame
    }
    
    func didTransitionItemWith(context: any UIViewControllerContextTransitioning) {
        imageView.isHidden = false
    }
}
