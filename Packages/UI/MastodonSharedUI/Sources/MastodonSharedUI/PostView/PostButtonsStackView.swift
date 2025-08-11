//
//  PostButtonsStackView.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 25.01.25.
//

import UIKit
import UIKitFoundation
import SwiftUtilities

@MainActor
public protocol PostButtonsStackViewDelegate: AnyObject {
    
    func postButtonsStackViewDidTapRepliesButton(_ stackView: PostButtonsStackView)
    
    func postButtonsStackViewDidTapReblogsButton(_ stackView: PostButtonsStackView, shouldReblog: Bool)
    
    func postButtonsStackViewDidTapFavoritesButton(_ stackView: PostButtonsStackView, shouldFavourite: Bool)
    
    func postButtonsStackViewDidTapShareButton(_ stackView: PostButtonsStackView)
}

public final class PostButtonsStackView: StackView {
    
    private let repliesButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "arrowshape.turn.up.left")
        configuration.baseForegroundColor = .secondaryLabel
        configuration.buttonSize = .mini
        
        let button = UIButton(configuration: configuration)
        if #available(iOS 17.0, *) { button.isSymbolAnimationEnabled = true }
        return button
    }()
    
    private let reblogsButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "arrow.2.squarepath")
        configuration.baseForegroundColor = .secondaryLabel
        configuration.buttonSize = .mini
        
        let button = UIButton(configuration: configuration)
        if #available(iOS 17.0, *) { button.isSymbolAnimationEnabled = true }
        return button
    }()
    
    private let favoritesButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "star")
        configuration.baseForegroundColor = .secondaryLabel
        configuration.buttonSize = .mini
        
        let button = UIButton(configuration: configuration)
        if #available(iOS 17.0, *) { button.isSymbolAnimationEnabled = true }
        return button
    }()
    
    private let shareButton: UIButton = {
        var configuration = UIButton.Configuration.plain()
        configuration.image = UIImage(systemName: "square.and.arrow.up")
        configuration.baseForegroundColor = .secondaryLabel
        configuration.buttonSize = .mini
        
        let button = UIButton(configuration: configuration)
        if #available(iOS 17.0, *) { button.isSymbolAnimationEnabled = true }
        return button
    }()
    
    public var itemIdentifier: AnyHashable?
    
    private var needsApplyConfiguration = false
    
    public var configuration = Configuration() {
        didSet { applyConfiguration() }
    }
    
    public weak var delegate: (any PostButtonsStackViewDelegate)?
    
    public override func setupCommon() {
        super.setupCommon()
        
        distribution = .fillEqually
        addArrangedSubview(repliesButton)
        addArrangedSubview(reblogsButton)
        addArrangedSubview(favoritesButton)
        addArrangedSubview(shareButton)
        
        setupButtonsActions()
    }
    
    public override func updateConstraints() {
        applyConfigurationIfNeeded()
        super.updateConstraints()
    }
}

extension PostButtonsStackView {
    
    private func setNeedsApplyConfiguration() {
        guard !needsApplyConfiguration else { return }
        needsApplyConfiguration = true
        setNeedsUpdateConstraints()
    }
    
    private func applyConfigurationIfNeeded() {
        guard needsApplyConfiguration else { return }
        needsApplyConfiguration = false
        applyConfiguration()
    }
    
    private func applyConfiguration() {
        repliesButton.configuration!.title = makeTitleIfNotZero(configuration.repliesCount)
        reblogsButton.configuration!.title = makeTitleIfNotZero(configuration.reblogsCount)
        favoritesButton.configuration!.title = makeTitleIfNotZero(configuration.favoritesCount)
        
        reblogsButton.configuration!.baseForegroundColor = configuration.buttonFlags.reblogsButtonToggled ? .systemGreen : .secondaryLabel
        favoritesButton.configuration!.baseForegroundColor = configuration.buttonFlags.favoritesButtonToggled ? .systemYellow : .secondaryLabel
        favoritesButton.configuration!.image = configuration.buttonFlags.favoritesButtonToggled ? UIImage(systemName: "star.fill") : UIImage(systemName: "star")
        
        func makeTitleIfNotZero(_ value: Int) -> String? {
            value == 0 ? nil : value.roundedWithAbbreviations
        }
    }
}

extension PostButtonsStackView {
    
    private func setupButtonsActions() {
        repliesButton.addAction(UIAction { [unowned self] _ in
            delegate?.postButtonsStackViewDidTapRepliesButton(self)
        }, for: .touchUpInside)
        
        reblogsButton.addAction(UIAction { [unowned self] _ in
            configuration.buttonFlags.reblogsButtonToggled.toggle()
            delegate?.postButtonsStackViewDidTapReblogsButton(self, shouldReblog: configuration.buttonFlags.reblogsButtonToggled)
            configuration.reblogsCount += configuration.buttonFlags.reblogsButtonToggled ? 1 : -1
            guard var reblogsConfiguration = reblogsButton.configuration else { return }
            reblogsConfiguration.baseForegroundColor = configuration.buttonFlags.reblogsButtonToggled ? .systemGreen : .secondaryLabel
            reblogsConfiguration.title = configuration.reblogsCount == 0 ? nil : configuration.reblogsCount.roundedWithAbbreviations
            reblogsButton.configuration = reblogsConfiguration
        }, for: .touchUpInside)
        
        favoritesButton.addAction(UIAction { [unowned self] _ in
            configuration.buttonFlags.favoritesButtonToggled.toggle()
            delegate?.postButtonsStackViewDidTapFavoritesButton(self, shouldFavourite: configuration.buttonFlags.favoritesButtonToggled)
            configuration.favoritesCount += configuration.buttonFlags.favoritesButtonToggled ? 1 : -1
            guard var favoritesConfiguration = favoritesButton.configuration else { return }
            favoritesConfiguration.baseForegroundColor = configuration.buttonFlags.favoritesButtonToggled ? .systemYellow : .secondaryLabel
            favoritesConfiguration.image = configuration.buttonFlags.favoritesButtonToggled ? UIImage(systemName: "star.fill") : UIImage(systemName: "star")
            favoritesConfiguration.title = configuration.favoritesCount == 0 ? nil : configuration.favoritesCount.roundedWithAbbreviations
            favoritesButton.configuration = favoritesConfiguration
        }, for: .touchUpInside)
        
        shareButton.addAction(UIAction { [unowned self] _ in
            delegate?.postButtonsStackViewDidTapShareButton(self)
        }, for: .touchUpInside)
    }
}

extension PostButtonsStackView {
    
    public struct Configuration: Hashable {
        
        public var repliesCount: Int = 0
        
        public var reblogsCount: Int = 0
        
        public var favoritesCount: Int = 0
        
        public var buttonFlags = ButtonFlags()
        
        public init() {
        }
    }
}

extension PostButtonsStackView {
    
    public struct ButtonFlags: Hashable {
        
        public var reblogsButtonToggled = false
        
        public var favoritesButtonToggled = false
        
        public init() {
        }
    }
}
