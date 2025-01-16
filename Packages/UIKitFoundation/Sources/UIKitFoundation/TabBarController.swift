//
//  TabBarController.swift
//  UIKitFoundation
//
//  Created by Nikita Prokhorchuk on 29.12.24.
//

import UIKit

open class TabBarController: UITabBarController {
    
    public init(viewControllers: [UIViewController]) {
        super.init(nibName: nil, bundle: nil)
        self.viewControllers = viewControllers
    }
    
    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError()
    }
}
