//
//  InstancesView.swift
//  MastodonAuthorizationUI
//
//  Created by Nikita Prokhorchuk on 5.12.24.
//

import UIKit
import UIKitFoundation

final class InstancesView: View {
    
    private static let gradientColors = [
        UIColor.systemGroupedBackground.cgColor,
        UIColor.tintColor.withAlphaComponent(0.3).cgColor,
    ]
    
    private let gradientView: LayerView<CAGradientLayer> = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.isUserInteractionEnabled = false
        $0.setLayer.colors = InstancesView.gradientColors
        $0.setLayer.startPoint = CGPoint(x: 0.5, y: 0.25)
        return $0
    }(LayerView<CAGradientLayer>(frame: .zero))
    
    private(set) lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: makeCompositionalLayout())
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.preservesSuperviewLayoutMargins = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.delaysContentTouches = false
        return collectionView
    }()
    
    let nothingFoundLabel: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.text = "Nothing found"
        $0.font = .preferredFont(forTextStyle: .headline)
        $0.isHidden = true
        return $0
    }(UILabel(frame: .zero))
    
    override func setupCommon() {
        super.setupCommon()
        backgroundColor = .systemGroupedBackground
        addSubview(gradientView)
        addSubview(collectionView)
        addSubview(nothingFoundLabel)
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor),
            safeAreaLayoutGuide.trailingAnchor.constraint(equalTo: collectionView.trailingAnchor),
            bottomAnchor.constraint(equalTo: collectionView.bottomAnchor),
            
            gradientView.topAnchor.constraint(equalTo: topAnchor),
            gradientView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: gradientView.trailingAnchor),
            bottomAnchor.constraint(equalTo: gradientView.bottomAnchor),
            
            nothingFoundLabel.topAnchor.constraint(equalToSystemSpacingBelow: safeAreaLayoutGuide.topAnchor, multiplier: 2.0),
            nothingFoundLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
        ])
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        gradientView.setLayer.colors = InstancesView.gradientColors
    }
}

extension InstancesView {
    
    private func makeCompositionalLayout() -> UICollectionViewCompositionalLayout {
        let configuration = UICollectionViewCompositionalLayoutConfiguration()
        configuration.contentInsetsReference = .layoutMargins
        return UICollectionViewCompositionalLayout(sectionProvider: { _, environment in
            let item = NSCollectionLayoutItem(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(300)
                )
            )
            let group = NSCollectionLayoutGroup.horizontal(
                layoutSize: NSCollectionLayoutSize(
                    widthDimension: .fractionalWidth(1.0),
                    heightDimension: .estimated(300)
                ),
                subitems: [item]
            )
            let section = NSCollectionLayoutSection(group: group)
            section.interGroupSpacing = environment.container.contentInsets.leading
            return section
        }, configuration: configuration)
    }
}
