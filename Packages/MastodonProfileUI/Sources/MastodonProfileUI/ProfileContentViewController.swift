//
//  ProfileContentViewController.swift
//  MastodonProfileUI
//
//  Created by Nikita Prokhorchuk on 26.12.24.
//

import UIKit
import UIKitFoundation
import NetworkFoundation
import MastodonAccountsDomain

@MainActor
protocol ProfileContentViewControllerDelegate: AnyObject {
    
    func profileContentViewController(_ viewController: ProfileContentViewController, didSelectImage image: UIImage)
}

final class ProfileContentViewController: ViewController {
    
    let profileView = ProfileView(frame: .zero)
    
    private var runningTask: Task<Void, Never>?
    
    var lastSelectedImageView: UIImageView?
    
    weak var delegate: (any ProfileContentViewControllerDelegate)?
    
    var configuration: Configuration? {
        didSet {
            guard let configuration, configuration != oldValue else { return }
            apply(configuration: configuration)
        }
    }
    
    override func setupCommon() {
        super.setupCommon()
        profileView.headerView.avatarImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleImageViewTapGesture)))
        profileView.headerView.headerImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleImageViewTapGesture)))
    }
    
    override func loadView() {
        view = profileView
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        runningTask?.cancel()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
}

extension ProfileContentViewController {
    
    private func apply(configuration: Configuration) {
        var headerConfiguration = HeaderView.Configuration()
        headerConfiguration.displayName = configuration.displayName
        headerConfiguration.username = configuration.username
        headerConfiguration.note = configuration.note
        headerConfiguration.postsCount = configuration.postsCount
        headerConfiguration.followersCount = configuration.followersCount
        headerConfiguration.followingCount = configuration.followingCount
        profileView.headerView.configuration = headerConfiguration
        runningTask = Task {
            guard var imagesConfiguration = profileView.headerView.configuration else { return }
            async let headerImage = UIImage.animatedImage(withGIFData: NetworkService.imageDownload.data(for: URLRequest(url: configuration.headerURL)))
            async let avatarImage = UIImage.animatedImage(withGIFData: NetworkService.imageDownload.data(for: URLRequest(url: configuration.avatarURL)))
            imagesConfiguration.headerImage = try? await headerImage
            imagesConfiguration.avatarImage = try? await avatarImage
            profileView.headerView.configuration = imagesConfiguration
        }
    }
}

extension ProfileContentViewController {
    
    @objc
    private func handleImageViewTapGesture(_ gestureRecognizer: UITapGestureRecognizer) {
        guard let imageView = gestureRecognizer.view as? UIImageView,
              let image = imageView.image
        else {
            return
        }
        lastSelectedImageView = imageView
        delegate?.profileContentViewController(self, didSelectImage: image)
    }
}

extension ProfileContentViewController {
    
    struct Configuration: Hashable {
        
        let headerURL: URL
        
        let avatarURL: URL
        
        let displayName: String
        
        let username: String
        
        let note: String
        
        let postsCount: Int
        
        let followersCount: Int
        
        let followingCount: Int
        
        let creationFormattedDate: String
        
        let fields: [Field]
    }
}
