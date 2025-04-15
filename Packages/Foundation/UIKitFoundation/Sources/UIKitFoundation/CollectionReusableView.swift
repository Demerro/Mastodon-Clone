//
//  CollectionReusableView.swift
//  UIKitFoundation
//
//  Created by Nikita Prokhorchuk on 30.11.24.
//

import UIKit

open class CollectionReusableView: UICollectionReusableView, ViewProtocol {
    
    open override class var requiresConstraintBasedLayout: Bool { true }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupCommon()
        setupConstraints()
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
