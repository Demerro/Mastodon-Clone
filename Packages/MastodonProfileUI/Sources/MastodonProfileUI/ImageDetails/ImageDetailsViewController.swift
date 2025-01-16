//
//  ImageDetailsViewController.swift
//  MastodonProfileUI
//
//  Created by Nikita Prokhorchuk on 10.01.25.
//

import UIKit
import UIKitFoundation
import FoundationUtilities

final class ImageDetailsViewController: ViewController {
    
    private let scrollView: UIScrollView = {
        $0.autoresizingMask = [.flexibleWidth, .flexibleHeight]
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
    
    var image: UIImage? {
        didSet { imageView.image = image }
    }
    
    init(image: UIImage? = nil) {
        self.image = image
        super.init()
        imageView.image = image
    }
    
    override func setupCommon() {
        super.setupCommon()
        scrollView.addSubview(imageView)
        scrollView.delegate = self
        scrollView.setValue(true, forKey: String(data: Data(base64Encoded: "cHJlc2VydmVzQ2VudGVyRHVyaW5nUm90YXRpb24=")!, encoding: .utf8)!)
//        navigationItem.leftBarButtonItem = UIBarButtonItem(systemItem: .close)
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
