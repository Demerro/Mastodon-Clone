//
//  VideoDetailsViewController.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 30.03.25.
//

import UIKit
import AVKit
import UIKitFoundation

@MainActor
public protocol VideoDetailsViewControllerDelegate: AnyObject {
    
    func videoDetailsViewControllerDidFinish(_ viewController: VideoDetailsViewController)
}

public final class VideoDetailsViewController: ViewController {
    
    private let thumbnailImageView: UIImageView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.clipsToBounds = true
        $0.contentMode = .scaleAspectFit
        return $0
    }(UIImageView(frame: .zero))
    
    private let playerViewController: AVPlayerViewController = {
        $0.view.translatesAutoresizingMaskIntoConstraints = false
        $0.videoGravity = .resizeAspect
        $0.allowsPictureInPicturePlayback = false
        return $0
    }(AVPlayerViewController())
    
    private var animationFinished = false
    
    public weak var interactiveAnimationController: ImageInteractiveAnimationController?
    
    private(set) public var isInteractivelyDismissing = false
    
    public weak var delegate: (any VideoDetailsViewControllerDelegate)?
    
    private var playerStateObservation: NSKeyValueObservation?
    
    private(set) public var thumbnailImage: UIImage {
        didSet { thumbnailImageView.image = thumbnailImage }
    }
    
    public let videoURL: URL
    
    public init(thumbnailImage: UIImage, videoURL: URL) {
        self.thumbnailImage = thumbnailImage
        self.videoURL = videoURL
        super.init()
        thumbnailImageView.image = thumbnailImage
        let playerItem = AVPlayerItem(url: videoURL)
        playerItem.preferredForwardBufferDuration = 0.0
        let player = AVPlayer(playerItem: playerItem)
        player.allowsExternalPlayback = false
        playerViewController.player = player
        playerStateObservation = playerViewController.observe(\.isReadyForDisplay, options: [.new, .initial]) { [unowned self] _, value in
            if value.newValue ?? false {
                thumbnailImageView.isHidden = true
                player.play()
            }
        }
    }
    
    deinit {
        playerStateObservation?.invalidate()
        playerStateObservation = nil
    }
    
    public override func setupCommon() {
        super.setupCommon()
        view.backgroundColor = .black
        addChild(playerViewController)
        view.addSubview(playerViewController.view)
        view.addSubview(thumbnailImageView)
        view.addGestureRecognizer(UIPanGestureRecognizer(target: self, action: #selector(handlePanGestureRecognizer)))
    }
    
    public override func setupViewConstraints() {
        super.setupViewConstraints()
        NSLayoutConstraint.activate([
            thumbnailImageView.widthAnchor.constraint(equalTo: view.widthAnchor),
            thumbnailImageView.heightAnchor.constraint(equalTo: view.widthAnchor, multiplier: thumbnailImage.size.height / thumbnailImage.size.width),
            thumbnailImageView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            playerViewController.view.topAnchor.constraint(equalTo: view.topAnchor),
            playerViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: playerViewController.view.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: playerViewController.view.bottomAnchor),
        ])
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        playerViewController.didMove(toParent: self)
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        playerViewController.player?.pause()
    }
}

extension VideoDetailsViewController {
    
    @objc
    private func handlePanGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        let percentageComplete = gestureRecognizer.translation(in: view).y / view.frame.height
        animationFinished = percentageComplete > 0.2
        switch gestureRecognizer.state {
        case .began:
            if let currentFrame { thumbnailImage = currentFrame }
            isInteractivelyDismissing = true
            dismiss(animated: true) { [unowned self] in
                delegate?.videoDetailsViewControllerDidFinish(self)
            }
        case .changed:
            interactiveAnimationController?.update(with: percentageComplete, translation: gestureRecognizer.translation(in: view))
        case .ended:
            isInteractivelyDismissing = false
            interactiveAnimationController?.completeTransition(withoutFinishing: !animationFinished, with: gestureRecognizer.velocity(in: view))
        default:
            break
        }
    }
}

extension VideoDetailsViewController {
    
    private var currentFrame: UIImage? {
        guard let player = playerViewController.player, let currentItem = player.currentItem else { return nil }
        
        let asset = currentItem.asset
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.requestedTimeToleranceBefore = .zero
        imageGenerator.requestedTimeToleranceAfter = .zero
        
        let currentTime = player.currentTime()
        return if let cgImage = try? imageGenerator.copyCGImage(at: currentTime, actualTime: nil) {
            UIImage(cgImage: cgImage)
        } else {
            nil
        }
    }
}

extension VideoDetailsViewController: ImageAnimationTransitioningDelegate {
    
    public func willTransitionItem() {
        playerViewController.view.isHidden = true
        thumbnailImageView.isHidden = true
    }
    
    public var item: TransitionItem? {
        TransitionItem(image: thumbnailImage, cornerRadius: 0.0)
    }
    
    public func itemFrame(in view: UIView) -> CGRect {
        thumbnailImageView.frame
    }
    
    public func didTransitionItem() {
        playerViewController.view.isHidden = false
        thumbnailImageView.isHidden = false
    }
}
