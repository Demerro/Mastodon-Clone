//
//  HeaderView.swift
//  MastodonProfileUI
//
//  Created by Nikita Prokhorchuk on 14.01.25.
//

import UIKit
import UIKitFoundation

final class HeaderView: View {
    
    private let headerImageView: UIImageView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.clipsToBounds = true
        $0.contentMode = .scaleAspectFill
        $0.backgroundColor = .systemGray
        return $0
    }(UIImageView(frame: .zero))
    
    private let avatarImageView: UIImageView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.clipsToBounds = true
        $0.contentMode = .scaleAspectFill
        $0.backgroundColor = .systemGray6
        $0.layer.borderColor = UIColor.white.cgColor
        $0.layer.borderWidth = 2.5
        $0.layer.cornerCurve = .continuous
        $0.layer.cornerRadius = 25.0
        return $0
    }(UIImageView(frame: .zero))
    
    private let informationStackView: InformationStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(InformationStackView(frame: .zero))
    
    private let displayNameLabel: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.font = .preferredFont(forTextStyle: .title2, compatibleWith: UITraitCollection(legibilityWeight: .bold))
        return $0
    }(UILabel(frame: .zero))
    
    private let usernameLabel: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.textColor = .secondaryLabel
        return $0
    }(UILabel(frame: .zero))
    
    private let noteLabel: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.numberOfLines = 0
        return $0
    }(UILabel(frame: .zero))
    
    private let button: UIButton = {
        var configuration = UIButton.Configuration.borderedProminent()
        configuration.title = "Edit Info"
        configuration.cornerStyle = .large
        configuration.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = .preferredFont(forTextStyle: .body, compatibleWith: UITraitCollection(legibilityWeight: .bold))
            return outgoing
        }
        
        let button = UIButton(configuration: configuration)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    var configuration: Configuration? {
        didSet {
            guard let configuration, configuration != oldValue else { return }
            apply(configuration: configuration)
        }
    }
    
    override func setupCommon() {
        super.setupCommon()
        addSubview(headerImageView)
        addSubview(avatarImageView)
        addSubview(informationStackView)
        addSubview(button)
        addSubview(displayNameLabel)
        addSubview(usernameLabel)
        addSubview(noteLabel)
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        button.setContentCompressionResistancePriority(.required, for: .horizontal)
        NSLayoutConstraint.activate([
            headerImageView.topAnchor.constraint(equalTo: topAnchor),
            headerImageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: headerImageView.trailingAnchor),
            headerImageView.heightAnchor.constraint(equalToConstant: 250.0),
            
            avatarImageView.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            avatarImageView.centerYAnchor.constraint(equalTo: headerImageView.bottomAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 100.0),
            avatarImageView.heightAnchor.constraint(equalTo: avatarImageView.widthAnchor),
            
            informationStackView.topAnchor.constraint(equalToSystemSpacingBelow: headerImageView.bottomAnchor, multiplier: 1.0),
            informationStackView.leadingAnchor.constraint(greaterThanOrEqualTo: avatarImageView.trailingAnchor),
            layoutMarginsGuide.trailingAnchor.constraint(equalTo: informationStackView.trailingAnchor),
            
            button.centerYAnchor.constraint(equalTo: displayNameLabel.centerYAnchor),
            layoutMarginsGuide.trailingAnchor.constraint(equalTo: button.trailingAnchor),
            
            displayNameLabel.topAnchor.constraint(greaterThanOrEqualToSystemSpacingBelow: avatarImageView.bottomAnchor, multiplier: 2.0),
            displayNameLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            displayNameLabel.trailingAnchor.constraint(lessThanOrEqualTo: button.leadingAnchor),
            
            usernameLabel.topAnchor.constraint(equalToSystemSpacingBelow: displayNameLabel.bottomAnchor, multiplier: 2.0),
            usernameLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            usernameLabel.trailingAnchor.constraint(lessThanOrEqualTo: button.leadingAnchor),
            
            noteLabel.topAnchor.constraint(equalToSystemSpacingBelow: usernameLabel.bottomAnchor, multiplier: 2.0),
            noteLabel.leadingAnchor.constraint(equalTo: layoutMarginsGuide.leadingAnchor),
            layoutMarginsGuide.trailingAnchor.constraint(greaterThanOrEqualTo: noteLabel.trailingAnchor),
        ])
    }
}

extension HeaderView {
    
    private func apply(configuration: Configuration) {
        displayNameLabel.text = configuration.displayName
        usernameLabel.text = configuration.username
        noteLabel.attributedText = configuration.note?.htmlAttributedString(with: [.font: UIFont.preferredFont(forTextStyle: .body)])
        informationStackView.configuration = InformationStackView.Configuration(
            posts: configuration.postsCount,
            following: configuration.followingCount,
            followers: configuration.followersCount
        )
        setImage(configuration.avatarImage, to: avatarImageView)
        setImage(configuration.headerImage, to: headerImageView)
    }
}

extension HeaderView {
    
    private func setImage(_ image: UIImage?, to imageView: UIImageView) {
        if let image {
            Task {
                let thumbnailImage = await image.byPreparingThumbnail(ofSize: imageView.bounds.size, with: traitCollection.displayScale)
                UIView.transition(with: imageView, duration: CATransaction.animationDuration(), options: .transitionCrossDissolve) {
                    imageView.image = thumbnailImage
                }
            }
        } else {
            imageView.image = nil
        }
    }
}

extension HeaderView {
    
    struct Configuration: Hashable {
        
        var headerImage: UIImage?
        
        var avatarImage: UIImage?
        
        var displayName: String?
        
        var username: String?
        
        var note: String?
        
        var postsCount: Int?
        
        var followingCount: Int?
        
        var followersCount: Int?
    }
}
