//
//  Toolbar.swift
//  MastodonComposeUI
//
//  Created by Nikita Prokhorchuk on 25.05.25.
//

import UIKit
import UIKitFoundation

final class Toolbar: StackView {
    
    private let visualEffectView: UIVisualEffectView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(UIVisualEffectView(effect: UIBlurEffect(style: .systemChromeMaterial)))
    
    private let symbolCounterLabel: UILabel = {
        $0.textColor = .secondaryLabel
        $0.text = String(Constants.maxPostSymbolsCount)
        return $0
    }(UILabel(frame: .zero))
    
    private let addPhotoButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "photo.badge.plus")!
        return UIButton(configuration: configuration)
    }()
    
    private let addSpoilerButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "exclamationmark.bubble")!
        return UIButton(configuration: configuration)
    }()
    
    private let changeVisibilityButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "globe.europe.africa")!
        let button = UIButton(configuration: configuration)
        button.showsMenuAsPrimaryAction = true
        return button
    }()
    
    private(set) var visibilityButtonState = VisibilityState.public {
        didSet {
            changeVisibilityButton.menu = visibilityButtonMenu
        }
    }
    
    var addPhotoButtonIsEnabled: Bool = true {
        didSet { addPhotoButton.isEnabled = addPhotoButtonIsEnabled }
    }
    
    var symbolCount: Int = Constants.maxPostSymbolsCount {
        didSet { symbolCounterLabel.text = String(symbolCount) }
    }
    
    weak var delegate: (any Delegate)?
    
    override func setupCommon() {
        super.setupCommon()
        
        axis = .horizontal
        addSubview(visualEffectView)
        preservesSuperviewLayoutMargins = true
        isLayoutMarginsRelativeArrangement = true
        clipsToBounds = true
        
        layer.cornerCurve = .continuous
        layer.cornerRadius = 10.0
        
        addArrangedSubview(addPhotoButton)
        addArrangedSubview(addSpoilerButton)
        addArrangedSubview(changeVisibilityButton)
        addArrangedSubview(LayerView<CATransformLayer>(frame: .zero))
        addArrangedSubview(symbolCounterLabel)
        
        changeVisibilityButton.menu = visibilityButtonMenu
        
        addPhotoButton.addAction(UIAction { [unowned self] _ in
            delegate?.toolbarDidSelectPhotoButton(self)
        }, for: .touchUpInside)
        
        addSpoilerButton.addAction(UIAction { [unowned self] _ in
            delegate?.toolbarDidSelectExclamationmarkButton(self)
        }, for: .touchUpInside)
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        NSLayoutConstraint.activate([
            visualEffectView.topAnchor.constraint(equalTo: topAnchor),
            visualEffectView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
            bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor),
        ])
    }
    
    override func layoutMarginsDidChange() {
        super.layoutMarginsDidChange()
        layoutMargins = UIEdgeInsets(top: 0.0, left: 0.0, bottom: 0.0, right: layoutMargins.right)
    }
}

extension Toolbar {
    
    enum VisibilityState {
        case `public`
        case unlisted
        case followersOnly
    }
    
    private var visibilityButtonMenu: UIMenu {
        UIMenu(children: [
            UIAction(title: "Followers only", image: UIImage(systemName: "lock"), state: visibilityButtonState == .followersOnly ? .on : .off) { [unowned self] _ in
                visibilityButtonState = .followersOnly
            },
            UIAction(title: "Unlisted", image: UIImage(systemName: "moon"), state: visibilityButtonState == .unlisted ? .on : .off) { [unowned self] _ in
                visibilityButtonState = .unlisted
            },
            UIAction(title: "Public", image: UIImage(systemName: "globe.europe.africa"), state: visibilityButtonState == .public ? .on : .off) { [unowned self] _ in
                visibilityButtonState = .public
            },
        ])
    }
}

extension Toolbar {
    
    @MainActor
    protocol Delegate: AnyObject {
        
        func toolbarDidSelectPhotoButton(_ toolbar: Toolbar)
        
        func toolbarDidSelectExclamationmarkButton(_ toolbar: Toolbar)
    }
}
