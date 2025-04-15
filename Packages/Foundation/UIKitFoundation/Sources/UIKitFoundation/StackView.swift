//
//  StackView.swift
//  UIKitFoundation
//
//  Created by Nikita Prokhorchuk on 28.12.24.
//

import UIKit

open class StackView: UIStackView, ViewProtocol, ViewProtocolPrivate {
    
    final var setupFlags = SetupFlags()
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupCommon()
        setupConstraints()
    }
    
    @available(*, unavailable)
    public required init(coder: NSCoder) {
        fatalError()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        _layoutSubviews()
    }
    
    open func setupCommon() {
    }
    
    open func setupConstraints() {
    }
    
    open func setupAfterLayoutSubviews() {
    }
}
