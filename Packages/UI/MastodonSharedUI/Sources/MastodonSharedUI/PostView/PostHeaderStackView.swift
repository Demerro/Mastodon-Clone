//
//  PostHeaderStackView.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 25.01.25.
//

import UIKit
import UIKitFoundation

@MainActor
public protocol PostHeaderStackViewDelegate: AnyObject {
    
    func postHeaderStackViewDidTapEyeButton(_ stackView: PostHeaderStackView)
}

public final class PostHeaderStackView: StackView {
    
    private let avatarImageView: UIImageView = {
        $0.contentMode = .scaleAspectFill
        $0.clipsToBounds = true
        $0.backgroundColor = .systemGray6
        $0.layer.cornerCurve = .continuous
        return $0
    }(UIImageView(frame: .zero))
    
    private let topStackView = UIStackView(frame: .zero)
    
    private let verticalStackView: UIStackView = {
        $0.axis = .vertical
        $0.distribution = .fillEqually
        return $0
    }(UIStackView(frame: .zero))
    
    private let displayNameLabel: UILabel = {
        $0.numberOfLines = 1
        $0.font = .preferredFont(forTextStyle: .headline)
        return $0
    }(UILabel(frame: .zero))
    
    private let informationLabel: UILabel = {
        $0.numberOfLines = 1
        $0.font = .preferredFont(forTextStyle: .subheadline)
        $0.textColor = .secondaryLabel
        return $0
    }(UILabel(frame: .zero))
    
    private let eyeButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "eye.fill")
        configuration.baseForegroundColor = .secondaryLabel
        
        let button = UIButton(configuration: configuration)
        button.isHidden = true
        return button
    }()
    
    private let moreButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "ellipsis")
        configuration.baseForegroundColor = .secondaryLabel
        
        let button = UIButton(configuration: configuration)
        return button
    }()
    
    private var needsApplyConfiguration = false
    
    public var configuration: Configuration = EmptyConfiguration() {
        didSet { setNeedsApplyConfiguration() }
    }
    
    public weak var delegate: (any PostHeaderStackViewDelegate)?
    
    private(set) var eyeButtonToggled = false
    
    public override func setupCommon() {
        super.setupCommon()
        
        spacing = 16.0
        
        topStackView.addArrangedSubview(displayNameLabel)
        topStackView.addArrangedSubview(LayerView<CATransformLayer>())
        topStackView.addArrangedSubview(eyeButton)
        topStackView.addArrangedSubview(moreButton)
        verticalStackView.addArrangedSubview(topStackView)
        verticalStackView.addArrangedSubview(informationLabel)
        addArrangedSubview(avatarImageView)
        addArrangedSubview(verticalStackView)
        
        eyeButton.addAction(UIAction { [unowned self] _ in
            toggleEye()
            delegate?.postHeaderStackViewDidTapEyeButton(self)
        }, for: .touchUpInside)
        
        RunLoop.current.add(Timer(timeInterval: 0.0, repeats: false) { [self] _ in
            MainActor.assumeIsolated { avatarImageView.layer.cornerRadius = avatarImageView.frame.width / 4.0 }
        }, forMode: .common)
    }
    
    public override func setupConstraints() {
        super.setupConstraints()
        NSLayoutConstraint.activate([
            avatarImageView.widthAnchor.constraint(equalToConstant: 50.0),
            avatarImageView.heightAnchor.constraint(equalTo: avatarImageView.widthAnchor),
        ])
    }
    
    public override func updateConstraints() {
        applyConfigurationIfNeeded()
        super.updateConstraints()
    }
}

extension PostHeaderStackView {
    
    public func toggleEye() {
        eyeButton.configuration?.image = eyeButtonToggled ? UIImage(systemName: "eye.fill") : UIImage(systemName: "eye.slash.fill")
        eyeButtonToggled.toggle()
    }
}

extension PostHeaderStackView {
    
    private func setNeedsApplyConfiguration() {
        guard !needsApplyConfiguration else { return }
        needsApplyConfiguration = true
        setNeedsUpdateConstraints()
    }
    
    private func applyConfigurationIfNeeded() {
        guard needsApplyConfiguration else { return }
        needsApplyConfiguration = false
       
        switch configuration {
        case let contentConfiguration as ContentConfiguration:
            apply(contentConfiguration: contentConfiguration)
        case let imageConfiguration as ImageConfiguration:
            apply(imageConfiguration: imageConfiguration)
        case is EmptyConfiguration:
            applyEmptyConfiguration()
        default:
            assertionFailure()
        }
    }
    
    private func apply(contentConfiguration: ContentConfiguration) {
        displayNameLabel.text = contentConfiguration.displayName
        eyeButton.isHidden = contentConfiguration.eyeHidden
        informationLabel.text = "\(contentConfiguration.time) • \(contentConfiguration.username)"
    }
    
    private func apply(imageConfiguration: ImageConfiguration) {
        if let avatarImage = imageConfiguration.avatarImage {
            UIView.transition(with: avatarImageView, duration: CATransaction.animationDuration() + 1) { [self] in
                avatarImageView.image = avatarImage
            }
        } else {
            avatarImageView.image = nil
        }
    }
    
    private func applyEmptyConfiguration() {
        displayNameLabel.text = nil
        eyeButton.isHidden = true
        informationLabel.text = nil
        avatarImageView.image = nil
    }
}

extension PostHeaderStackView {

    public protocol Configuration {
    }
    
    public struct ImageConfiguration: Configuration, Sendable, Hashable {
        
        public let avatarImage: UIImage?
        
        public init(avatarImage: UIImage?) {
            self.avatarImage = avatarImage
        }
    }
    
    public struct ContentConfiguration: Configuration, Sendable, Hashable {
        
        public let displayName: String
        
        public let time: String
        
        public let username: String
        
        public let eyeHidden: Bool
        
        public init(displayName: String, time: String, username: String, eyeHidden: Bool) {
            self.displayName = displayName
            self.time = time
            self.username = username
            self.eyeHidden = eyeHidden
        }
    }
    
    public struct EmptyConfiguration: Configuration, Sendable, Hashable {
        
        public init() {
        }
    }
}
