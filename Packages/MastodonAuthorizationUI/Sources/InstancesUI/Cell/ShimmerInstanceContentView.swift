//
//  ShimmerInstanceContentView.swift
//  MastodonAuthorizationUI
//
//  Created by Nikita Prokhorchuk on 9.12.24.
//

import UIKit
import UIKitFoundation

final class ShimmerInstanceContentView: View, UIContentView {
    
    private let thumbnailShimmerView: UIView = {
        $0.layer.cornerRadius = 13.0
        $0.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        return $0
    }(ShimmerInstanceContentView.makeShimmerView())
    
    private let nameShimmerView = ShimmerInstanceContentView.makeShimmerView()
    
    private let informationShimmerView = ShimmerInstanceContentView.makeShimmerView()
    
    private let descriptionStackView: UIStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.distribution = .fillEqually
        $0.axis = .vertical
        $0.spacing = 5.0
        return $0
    }(UIStackView(frame: .zero))
    
    private var appliedConfiguration: Configuration!
    
    var configuration: any UIContentConfiguration {
        get {
            appliedConfiguration
        }
        set {
            guard let newConfiguration = newValue as? Configuration else { return }
            appliedConfiguration = newConfiguration
        }
    }
    
    init(configuration: Configuration) {
        super.init(frame: .zero)
        appliedConfiguration = configuration
    }
    
    override func setupCommon() {
        super.setupCommon()
        addSubview(thumbnailShimmerView)
        addSubview(nameShimmerView)
        addSubview(informationShimmerView)
        addSubview(descriptionStackView)
    }
    
    override func setupConstraints() {
        super.setupConstraints()
        var constraints = [
            thumbnailShimmerView.topAnchor.constraint(equalTo: topAnchor),
            thumbnailShimmerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: thumbnailShimmerView.trailingAnchor),
            thumbnailShimmerView.heightAnchor.constraint(equalToConstant: 200.0),
            
            nameShimmerView.topAnchor.constraint(equalToSystemSpacingBelow: thumbnailShimmerView.bottomAnchor, multiplier: 1.0),
            nameShimmerView.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 1.0),
            centerXAnchor.constraint(equalTo: nameShimmerView.trailingAnchor, constant: 4.0),
            nameShimmerView.heightAnchor.constraint(equalToConstant: 20.0),
            
            informationShimmerView.topAnchor.constraint(equalToSystemSpacingBelow: thumbnailShimmerView.bottomAnchor, multiplier: 1.0),
            informationShimmerView.leadingAnchor.constraint(equalTo: centerXAnchor, constant: 4.0),
            trailingAnchor.constraint(equalToSystemSpacingAfter: informationShimmerView.trailingAnchor, multiplier: 1.0),
            informationShimmerView.heightAnchor.constraint(equalToConstant: 20.0),
            
            descriptionStackView.topAnchor.constraint(equalToSystemSpacingBelow: nameShimmerView.bottomAnchor, multiplier: 1.0),
            descriptionStackView.leadingAnchor.constraint(equalToSystemSpacingAfter: leadingAnchor, multiplier: 1.0),
            trailingAnchor.constraint(equalToSystemSpacingAfter: descriptionStackView.trailingAnchor, multiplier: 1.0),
            bottomAnchor.constraint(equalToSystemSpacingBelow: descriptionStackView.bottomAnchor, multiplier: 1.0).priority(.defaultHigh),
        ]
        constraints += makeShimmerConstraints(for: descriptionStackView, count: 3)
        NSLayoutConstraint.activate(constraints)
    }
}

extension ShimmerInstanceContentView {
    
    private static func makeShimmerView() -> UIView {
        let view = UIView(frame: .zero)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .systemGray6
        view.layer.cornerCurve = .continuous
        view.layer.cornerRadius = 5.0
        return view
    }
}

extension ShimmerInstanceContentView {
    
    private func makeShimmerConstraints(for stackView: UIStackView, count: Int) -> [NSLayoutConstraint] {
        var constraints = [NSLayoutConstraint]()
        constraints.reserveCapacity(count * 2)
        for _ in 0..<count {
            let shimmerView = ShimmerInstanceContentView.makeShimmerView()
            stackView.addArrangedSubview(shimmerView)
            constraints += [
                shimmerView.widthAnchor.constraint(equalTo: stackView.widthAnchor),
                shimmerView.heightAnchor.constraint(equalToConstant: 16.0),
            ]
        }
        return constraints
    }
}

extension ShimmerInstanceContentView {
    
    struct Configuration: UIContentConfiguration {
        
        func makeContentView() -> any UIView & UIContentView {
            ShimmerInstanceContentView(configuration: self)
        }
        
        func updated(for state: any UIConfigurationState) -> ShimmerInstanceContentView.Configuration {
            self
        }
    }
}
