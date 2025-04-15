//
//  ViewProtocol.swift
//  UIKitFoundation
//
//  Created by Nikita Prokhorchuk on 23.11.24.
//

import UIKit

public protocol ViewProtocol: UIView {
    
    func setupCommon()
    
    func setupConstraints()
    
    func setupAfterLayoutSubviews()
}
