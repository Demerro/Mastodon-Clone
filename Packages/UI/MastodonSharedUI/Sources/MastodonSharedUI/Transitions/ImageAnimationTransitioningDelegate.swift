//
//  ImageAnimationTransitioningDelegate.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 26.03.25.
//

import UIKit

@MainActor
public protocol ImageAnimationTransitioningDelegate: AnyObject {
    
    func willTransitionItem()
    
    var item: TransitionItem? { get }
    
    func itemFrame(in view: UIView) -> CGRect
    
    func didTransitionItem()
}

public struct TransitionItem {
    
    public let image: UIImage
    
    public let cornerRadius: CGFloat
    
    public init(image: UIImage, cornerRadius: CGFloat) {
        self.image = image
        self.cornerRadius = cornerRadius
    }
}
