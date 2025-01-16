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
    
    func profileContentViewController(_ viewController: ProfileContentViewController, didSelectAvatarImage image: UIImage)
}

final class ProfileContentViewController: ViewController {
    
    private let profileView = ProfileView(frame: .zero)
    
    private var runningTask: Task<Void, Never>?
    
    weak var delegate: (any ProfileContentViewControllerDelegate)?
    
    var configuration: Configuration {
        didSet {
            guard configuration != oldValue else { return }
            apply(configuration: configuration)
        }
    }
    
    init(configuration: Configuration) {
        self.configuration = configuration
        super.init()
        apply(configuration: configuration)
    }
    
    override func loadView() {
        view = profileView
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        runningTask?.cancel()
    }
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
