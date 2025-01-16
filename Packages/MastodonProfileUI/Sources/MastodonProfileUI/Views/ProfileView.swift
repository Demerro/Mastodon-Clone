//
//  ProfileView.swift
//  MastodonProfileUI
//
//  Created by Nikita Prokhorchuk on 13.01.25.
//

import UIKit
import UIKitFoundation

final class ProfileView: View {
    
    private let underlyingScrollView: UIScrollView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.preservesSuperviewLayoutMargins = true
        $0.alwaysBounceVertical = true
        $0.showsVerticalScrollIndicator = false
        $0.showsHorizontalScrollIndicator = false
        $0.contentInsetAdjustmentBehavior = .never
        return $0
    }(UIScrollView(frame: .zero))
    
    let headerView: HeaderView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.preservesSuperviewLayoutMargins = true
        return $0
    }(HeaderView(frame: .zero))
    
    private let categorySegmentedControl: CategorySegmentedControl = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.categoryTitles = ["Posts", "Posts and Replies", "Media", "About"]
        return $0
    }(CategorySegmentedControl(frame: .zero))
    
    override func setupCommon() {
        super.setupCommon()
        addSubview(underlyingScrollView)
        underlyingScrollView.addSubview(headerView)
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        NSLayoutConstraint.activate([
            underlyingScrollView.topAnchor.constraint(equalTo: topAnchor),
            underlyingScrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: underlyingScrollView.trailingAnchor),
            bottomAnchor.constraint(equalTo: underlyingScrollView.bottomAnchor),
            
            headerView.topAnchor.constraint(equalTo: underlyingScrollView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
        ])
    }
}
