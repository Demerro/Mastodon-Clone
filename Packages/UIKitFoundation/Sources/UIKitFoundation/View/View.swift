//
//  View.swift
//  UIKitFoundation
//
//  Created by Nikita Prokhorchuk on 23.11.24.
//

import UIKit

open class View: UIView, ViewProtocol {
    
    final var setupFlags = SetupFlags()
    
    public override class var requiresConstraintBasedLayout: Bool { true }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupCommon()
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError()
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        setupAfterLayoutSubviews()
    }
    
    open func setupCommon() {
    }
    
    open func setupConstraints() {
    }
    
    open func setupAfterLayoutSubviews() {
    }
}
