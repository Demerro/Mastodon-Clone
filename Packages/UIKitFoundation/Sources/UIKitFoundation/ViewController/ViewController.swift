//
//  ViewController.swift
//  UIKitFoundation
//
//  Created by Nikita Prokhorchuk on 23.11.24.
//

import UIKit

open class ViewController: UIViewController, ViewControllerProtocol {
    
    public init() {
        super.init(nibName: nil, bundle: nil)
        setupCommon()
        setupViewConstraints()
    }
    
    @available(*, unavailable)
    public override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        fatalError()
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError()
    }
    
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        setupAfterViewDidLayoutSubviews()
    }
    
    open func setupCommon() {
    }
    
    open func setupViewConstraints() {
    }
    
    open func setupAfterViewDidLayoutSubviews() {
    }
}
