//
//  AuthorizationConstants.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 27.11.24.
//

import Foundation

struct AuthorizationConstants {
    
    static let clientKey = "I0fwIWdkSC73qHyEqZ7mB0GGQpB1p51il1XPKU3nsu8"
    
    static let clientSecret = Bundle.main.infoDictionary!["Client Secret"] as! String
    
    static let redirectURI = "mastodon-clone://oauth-callback"
    
    static let scopes = "profile push read write"
    
    static let callbackURLScheme = Self.redirectURI.components(separatedBy: "://").first!
}
