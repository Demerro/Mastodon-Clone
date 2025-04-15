//
//  ViewControllerProtocol.swift
//  UIKitFoundation
//
//  Created by Nikita Prokhorchuk on 23.11.24.
//

import UIKit

public protocol ViewControllerProtocol: UIViewController {
    
    func setupCommon()
    
    func setupViewConstraints()
    
    func setupAfterViewDidLayoutSubviews()
}
