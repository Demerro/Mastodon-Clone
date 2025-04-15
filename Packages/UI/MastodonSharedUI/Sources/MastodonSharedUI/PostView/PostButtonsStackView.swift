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
    
    func postButtonsStackViewDidTapReblogsButton(_ stackView: PostButtonsStackView)
    
    func postButtonsStackViewDidTapFavoritesButton(_ stackView: PostButtonsStackView)
    
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
    
    private var needsApplyConfiguration = false
    
    private(set) var buttonFlags = ButtonFlags()
    
    public var configuration: Configuration? {
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
        guard let configuration else { return }
        
        repliesButton.configuration!.title = makeTitleIfNotZero(configuration.repliesCount)
        reblogsButton.configuration!.title = makeTitleIfNotZero(configuration.reblogsCount)
        favoritesButton.configuration!.title = makeTitleIfNotZero(configuration.favoritesCount)
        
        buttonFlags = configuration.buttonFlags
        reblogsButton.configuration!.baseForegroundColor = buttonFlags.reblogsButtonToggled ? .systemGreen : .secondaryLabel
        favoritesButton.configuration!.baseForegroundColor = buttonFlags.favoritesButtonToggled ? .systemYellow : .secondaryLabel
        favoritesButton.configuration!.image = buttonFlags.favoritesButtonToggled ? UIImage(systemName: "star.fill") : UIImage(systemName: "star")
        
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
            reblogsButton.configuration!.baseForegroundColor = buttonFlags.reblogsButtonToggled ? .secondaryLabel : .systemGreen
            let number = adjustValue(configuration?.reblogsCount ?? 0, increment: !buttonFlags.reblogsButtonToggled)
            reblogsButton.configuration!.title = number?.roundedWithAbbreviations
            configuration?.reblogsCount = number ?? 0
            buttonFlags.reblogsButtonToggled.toggle()
            delegate?.postButtonsStackViewDidTapReblogsButton(self)
        }, for: .touchUpInside)
        
        favoritesButton.addAction(UIAction { [unowned self] _ in
            favoritesButton.configuration!.baseForegroundColor = buttonFlags.favoritesButtonToggled ? .secondaryLabel : .systemYellow
            favoritesButton.configuration!.image = buttonFlags.favoritesButtonToggled ? UIImage(systemName: "star") : UIImage(systemName: "star.fill")
//            favoritesButton.configuration!.title = adjustAndFormatNumber(number: configuration?.favoritesCount ?? 0, shouldDecrement: buttonFlags.favoritesButtonToggled)
            buttonFlags.favoritesButtonToggled.toggle()
            delegate?.postButtonsStackViewDidTapFavoritesButton(self)
        }, for: .touchUpInside)
        
        shareButton.addAction(UIAction { [unowned self] _ in
            delegate?.postButtonsStackViewDidTapShareButton(self)
        }, for: .touchUpInside)
        
        func adjustValue(_ value: Int, increment: Bool) -> Int? {
            guard value > 0 else {
                return nil
            }
            return increment ? value + 1 : value - 1
        }
    }
}

extension PostButtonsStackView {
    
    public struct Configuration: Hashable {
        
        public let repliesCount: Int
        
        public var reblogsCount: Int
        
        public var favoritesCount: Int
        
        public let buttonFlags: ButtonFlags
        
        public init(repliesCount: Int, reblogsCount: Int, favoritesCount: Int, buttonFlags: ButtonFlags) {
            self.repliesCount = repliesCount
            self.reblogsCount = reblogsCount
            self.favoritesCount = favoritesCount
            self.buttonFlags = buttonFlags
        }
    }
}

extension PostButtonsStackView {
    
    public struct ButtonFlags: Hashable {
        
        public var reblogsButtonToggled = false
        
        public var favoritesButtonToggled = false
        
        public init(reblogsButtonToggled: Bool = false, favoritesButtonToggled: Bool = false) {
            self.reblogsButtonToggled = reblogsButtonToggled
            self.favoritesButtonToggled = favoritesButtonToggled
        }
    }
}
