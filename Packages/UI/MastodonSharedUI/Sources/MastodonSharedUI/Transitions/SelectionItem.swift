//
//  SelectionItem.swift
//  MastodonSharedUI
//
//  Created by Nikita Prokhorchuk on 12.05.25.
//

import UIKit

public struct SelectionItem {
    
    public let view: UIView
    
    public let image: UIImage
    
    public init(view: UIView, image: UIImage) {
        self.view = view
        self.image = image
    }
}
