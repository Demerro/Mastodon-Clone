//
//  UnavailableConfiguration.swift
//  MastodonCoreUI
//
//  Created by Nikita Prokhorchuk on 13.01.25.
//

import UIKit

public struct UnavailableConfiguration: Hashable {
    
    public var image: UIImage? = nil
    
    public var text: String? = nil
    
    public var secondaryText: String? = nil
    
    internal var style: Style
    
    private init(style: Style) {
        self.style = style
    }
    
    public static func empty() -> Self {
        UnavailableConfiguration(style: .empty)
    }
    
    public static func loading() -> Self {
        UnavailableConfiguration(style: .loading)
    }
}

extension UnavailableConfiguration {
    
    internal enum Style {
        
        case empty
        
        case loading
    }
}
