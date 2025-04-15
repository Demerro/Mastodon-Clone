//
//  LayoutInvalidationDelegate.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 4.04.25.
//

import UIKit

public protocol LayoutInvalidationDelegate: AnyObject {
    
    func invalidateLayout(_ cell: UICollectionViewCell)
}
