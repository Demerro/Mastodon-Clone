//
//  ProfileView.swift
//  MastodonProfileUI
//
//  Created by Nikita Prokhorchuk on 13.01.25.
//

import UIKit
import UIKitFoundation

final class ProfileView: View {
    
    let overlayScrollView: UIScrollView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.contentInsetAdjustmentBehavior = .never
        $0.showsHorizontalScrollIndicator = false
        $0.layer.zPosition = .greatestFiniteMagnitude
        return $0
    }(UIScrollView(frame: .zero))
    
    let containerScrollView: UIScrollView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.contentInsetAdjustmentBehavior = .never
        $0.scrollsToTop = false
        $0.showsVerticalScrollIndicator = false
        $0.showsHorizontalScrollIndicator = false
        $0.preservesSuperviewLayoutMargins = true
        return $0
    }(UIScrollView(frame: .zero))
    
    let headerView: HeaderView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.preservesSuperviewLayoutMargins = true
        return $0
    }(HeaderView(frame: .zero))
    
    let categorySegmentedControl: CategorySegmentedControl = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.categoryTitles = ["Posts", "Posts and Replies", "Media", "About"]
        $0.backgroundColor = .systemBackground
        $0.layer.shadowOpacity = 1.0
        return $0
    }(CategorySegmentedControl(frame: .zero))
    
    let pagingCollectionView: PagingCollectionView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.register(PagingCollectionViewCell.self, forCellWithReuseIdentifier: PagingCollectionViewCell.identifier)
        return $0
    }(PagingCollectionView(frame: .zero))
    
    let refreshControl: UIRefreshControl = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.tintColor = .white
        return $0
    }(UIRefreshControl(frame: .zero))
    
    override func setupCommon() {
        super.setupCommon()
        addSubview(overlayScrollView)
        addSubview(containerScrollView)
        containerScrollView.addSubview(pagingCollectionView)
        containerScrollView.addSubview(headerView)
        containerScrollView.addSubview(categorySegmentedControl)
        overlayScrollView.addSubview(refreshControl)
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        NSLayoutConstraint.activate([
            overlayScrollView.topAnchor.constraint(equalTo: topAnchor),
            overlayScrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: overlayScrollView.trailingAnchor),
            bottomAnchor.constraint(equalTo: overlayScrollView.bottomAnchor),
            
            containerScrollView.topAnchor.constraint(equalTo: topAnchor),
            containerScrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: containerScrollView.trailingAnchor),
            bottomAnchor.constraint(equalTo: containerScrollView.bottomAnchor),
            
            headerView.topAnchor.constraint(equalTo: containerScrollView.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: headerView.trailingAnchor),
            
            categorySegmentedControl.topAnchor.constraint(equalToSystemSpacingBelow: headerView.bottomAnchor, multiplier: 2.0),
            categorySegmentedControl.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: categorySegmentedControl.trailingAnchor),
            
            pagingCollectionView.topAnchor.constraint(equalTo: categorySegmentedControl.bottomAnchor),
            pagingCollectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: pagingCollectionView.trailingAnchor),
            bottomAnchor.constraint(equalTo: pagingCollectionView.bottomAnchor),
            
            refreshControl.topAnchor.constraint(equalToSystemSpacingBelow: safeAreaLayoutGuide.topAnchor, multiplier: 3.0),
            refreshControl.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }
    
    override func setupAfterLayoutSubviews() {
        super.setupAfterLayoutSubviews()
        RunLoop.current.perform { [categorySegmentedControl] in
            MainActor.assumeIsolated {
                categorySegmentedControl.layer.shadowPath = UIBezierPath(rect: CGRect(
                    x: 0.0,
                    y: categorySegmentedControl.bounds.maxY,
                    width: categorySegmentedControl.bounds.width,
                    height: 1.0)
                ).cgPath
            }
        }
    }
}
