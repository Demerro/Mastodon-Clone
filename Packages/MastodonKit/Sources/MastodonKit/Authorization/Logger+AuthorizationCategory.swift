//
//  Logger+AuthorizationCategory.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 13.04.25.
//

import os.log
import osUtilities

extension Logger {
    
    static let authorization = conditionalDebugLogger(subsystem: subsystem, category: "Authorization")
}
