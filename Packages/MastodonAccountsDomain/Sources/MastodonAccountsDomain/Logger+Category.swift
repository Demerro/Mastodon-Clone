//
//  Logger+Category.swift
//  MastodonAccountsDomain
//
//  Created by Nikita Prokhorchuk on 26.12.24.
//

import Foundation
import os.log

extension Logger {
    
    static let accountsDomain = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "AccountsDomain")
}
