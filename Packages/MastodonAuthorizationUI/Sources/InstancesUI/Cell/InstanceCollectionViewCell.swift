//
//  InstanceCollectionViewCell.swift
//  MastodonAuthorizationUI
//
//  Created by Nikita Prokhorchuk on 3.12.24.
//

import UIKit
import UIKitFoundation
import UIKitUtilities

final class InstanceCollectionViewCell<Identifier: Hashable>: CollectionViewCell {
    
    var itemIdentifier: Identifier?
    
    var isShimmering: Bool = false {
        didSet {
            guard oldValue != isShimmering else { return }
            setNeedsUpdateConfiguration()
        }
    }
    
    override var isHighlighted: Bool {
        get {
            super.isHighlighted
        }
        set {
            super.isHighlighted = newValue
            let animator = UIViewPropertyAnimator(duration: 0.0, timingParameters: UISpringTimingParameters(dampingRatio: 1.0, frequencyResponse: newValue ? 0.2 : 0.5))
            animator.addAnimations {
                self.transform = newValue ? CGAffineTransform(scaleX: 0.95, y: 0.95) : .identity
            }
            animator.startAnimation()
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        itemIdentifier = nil
    }
    
    override var configurationState: UICellConfigurationState {
        var state = super.configurationState
        state.isShimmering = isShimmering
        return state
    }
    
    override func updateConfiguration(using state: UICellConfigurationState) {
        backgroundConfiguration = InstanceContentView.BackgroundConfiguration.configuration(for: state)
    }
}

extension InstanceCollectionViewCell {
    
    func defaultContentConfiguration() -> InstanceContentView.Configuration {
        InstanceContentView.Configuration()
    }
    
    func shimmerContentConfiguration() -> ShimmerInstanceContentView.Configuration {
        ShimmerInstanceContentView.Configuration()
    }
}

extension UIConfigurationStateCustomKey {
    
    fileprivate static let isShimmering = UIConfigurationStateCustomKey("com.demerro.InstanceCollectionViewCell.isShimmering")
}

extension UICellConfigurationState {
    
    fileprivate var isShimmering: Bool {
        get { self[.isShimmering] as? Bool ?? false }
        set { self[.isShimmering] = newValue }
    }
}
