//
//  SpoilerStackView.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 4.04.25.
//

import UIKit
import UIKitFoundation
import MastodonCoreUI

public final class SpoilerView: View {
    
    private let spoilerLabel: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.font = .preferredFont(forTextStyle: .headline)
        return $0
    }(UILabel(frame: .zero))
    
    private let tipLabel: UILabel = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.text = "Tap anywhere to reveal"
        $0.textColor = .secondaryLabel
        return $0
    }(UILabel(frame: .zero))
    
    private let imageAttachmentMosaicStackView: ImageAttachmentMosaicStackView = {
        $0.translatesAutoresizingMaskIntoConstraints = false
        return $0
    }(ImageAttachmentMosaicStackView(frame: .zero))
    
    private var oldConstraints = [NSLayoutConstraint]()
    
    private var needsApplyConfiguration = false
    
    public var configuration = Configuration() {
        didSet { setNeedsApplyConfiguration() }
    }
    
    public override func setupCommon() {
        super.setupCommon()
        
        addSubview(imageAttachmentMosaicStackView)
        addSubview(spoilerLabel)
        addSubview(tipLabel)
    }
    
    public override func setupConstraints() {
        super.setupConstraints()
        
        NSLayoutConstraint.activate([
            spoilerLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            trailingAnchor.constraint(greaterThanOrEqualTo: spoilerLabel.trailingAnchor),
            spoilerLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            tipLabel.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            trailingAnchor.constraint(greaterThanOrEqualTo: tipLabel.trailingAnchor),
            tipLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            
            imageAttachmentMosaicStackView.topAnchor.constraint(equalTo: topAnchor),
            imageAttachmentMosaicStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            trailingAnchor.constraint(equalTo: imageAttachmentMosaicStackView.trailingAnchor),
            bottomAnchor.constraint(equalTo: imageAttachmentMosaicStackView.bottomAnchor),
        ])
    }
    
    public override func updateConstraints() {
        applyConfigurationIfNeeded()
        super.updateConstraints()
    }
}

extension SpoilerView {
    
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
        spoilerLabel.text = configuration.text
        imageAttachmentMosaicStackView.configuration = configuration.imageAttachmentMosaicStackViewConfiguration
        
        let textOnlySpoiler = configuration.imageAttachmentMosaicStackViewConfiguration is ImageAttachmentMosaicStackView.EmptyConfiguration
        imageAttachmentMosaicStackView.isHidden = textOnlySpoiler
        
        var constraints = [NSLayoutConstraint]()
        
        if textOnlySpoiler {
            constraints += [
                heightAnchor.constraint(equalToConstant: 100.0).priority(.defaultHigh)
            ]
        }
        
        if configuration.text?.isEmpty ?? true {
            constraints += [
                tipLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
            ]
        } else {
            constraints += [
                spoilerLabel.bottomAnchor.constraint(equalTo: centerYAnchor),
                tipLabel.topAnchor.constraint(equalTo: centerYAnchor),
            ]
        }
        
        NSLayoutConstraint.deactivate(oldConstraints)
        NSLayoutConstraint.activate(constraints)
        oldConstraints = constraints
    }
}

extension SpoilerView {
    
    public struct Configuration {
        
        public var text: String? = nil
        
        public var imageAttachmentMosaicStackViewConfiguration: ImageAttachmentMosaicStackView.Configuration = ImageAttachmentMosaicStackView.EmptyConfiguration()
        
        public init() {
        }
    }
}
