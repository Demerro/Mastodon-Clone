//
//  ImageDetailsTransitioningDelegate.swift
//  MastodonProfileUI
//
//  Created by Nikita Prokhorchuk on 19.01.25.
//

import UIKit

@MainActor
protocol ImageDetailsTransitioningDelegate: AnyObject {
    
    func willTransitionItemWith(context: any UIViewControllerContextTransitioning, coordinator: (any UIViewControllerTransitionCoordinator)?)
    
    func item(forTransitionWith context: any UIViewControllerContextTransitioning) -> ImageDetailsItem
    
    func itemFrame(in view: UIView, forTransitionWith context: any UIViewControllerContextTransitioning) -> CGRect
    
    func didTransitionItemWith(context: any UIViewControllerContextTransitioning)
}

struct ImageDetailsItem {
    
    let image: UIImage
    
    let cornerRadius: CGFloat
    
    let borderWidth: CGFloat
    
    let borderColor: CGColor?
}
