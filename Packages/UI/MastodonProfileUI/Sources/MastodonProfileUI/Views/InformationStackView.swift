//
//  InformationStackView.swift
//  MastodonProfileUI
//
//  Created by Nikita Prokhorchuk on 6.01.25.
//

import UIKit
import UIKitFoundation
import SwiftUtilities

final class InformationStackView: StackView {
    
    private let postsItem: _InformationStackViewItem = {
        $0.title = "posts"
        return $0
    }(_InformationStackViewItem(frame: .zero))
    
    private let followingItem: _InformationStackViewItem = {
        $0.title = "following"
        return $0
    }(_InformationStackViewItem(frame: .zero))
    
    private let followersItem: _InformationStackViewItem = {
        $0.title = "followers"
        return $0
    }(_InformationStackViewItem(frame: .zero))
    
    var configuration: Configuration? {
        didSet {
            guard let configuration, configuration != oldValue else { return }
            apply(configuration: configuration)
        }
    }
    
    override func setupCommon() {
        super.setupCommon()
        spacing = 10.0
        alignment = .center
        addArrangedSubview(postsItem)
        addArrangedSubview(followingItem)
        addArrangedSubview(followersItem)
    }
}

extension InformationStackView {
    
    private func apply(configuration: Configuration) {
        guard let posts = configuration.posts,
              let following = configuration.following,
              let followers = configuration.followers
        else {
            return
        }
        postsItem.amount = posts
        followingItem.amount = following
        followersItem.amount = followers
    }
}

extension InformationStackView {
    
    private func addSeparator() {
        let separator = UIView(frame: .zero)
        separator.backgroundColor = .separator
        separator.layer.cornerCurve = .continuous
        separator.layer.cornerRadius = 1.0
        addArrangedSubview(separator)
        NSLayoutConstraint.activate([
            separator.widthAnchor.constraint(equalToConstant: 1.0),
            separator.heightAnchor.constraint(equalTo: heightAnchor),
        ])
    }
}

extension InformationStackView {
    
    struct Configuration: Hashable {
        
        var posts: Int?
        
        var following: Int?
        
        var followers: Int?
    }
}

fileprivate final class _InformationStackViewItem: StackView {
    
    var amount: Int = 0 {
        didSet { amountLabel.text = "\(amount.roundedWithAbbreviations)" }
    }
    
    var title: String? {
        didSet { titleLabel.text = title }
    }
    
    private let amountLabel: UILabel = {
        $0.font = .preferredFont(forTextStyle: .headline)
        $0.numberOfLines = 1
        return $0
    }(UILabel(frame: .zero))
    
    private let titleLabel: UILabel = {
        $0.font = .preferredFont(forTextStyle: .footnote)
        $0.numberOfLines = 1
        return $0
    }(UILabel(frame: .zero))
    
    override func setupCommon() {
        super.setupCommon()
        alignment = .center
        axis = .vertical
        addArrangedSubview(amountLabel)
        addArrangedSubview(titleLabel)
    }
}
