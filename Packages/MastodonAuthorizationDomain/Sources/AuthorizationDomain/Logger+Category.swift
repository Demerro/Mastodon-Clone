//
//  Logger+Category.swift
//  MastodonAuthorizationDomain
//
//  Created by Nikita Prokhorchuk on 26.12.24.
//

import Foundation
import os.log

extension Logger {
    
    static let authorizationDomain = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "AuthorizationDomain")
}
