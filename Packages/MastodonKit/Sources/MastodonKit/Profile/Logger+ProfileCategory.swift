//
//  Logger+ProfileCategory.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 13.04.25.
//

import os.log
import osUtilities

extension Logger {
    
    static let profile = conditionalDebugLogger(subsystem: subsystem, category: "Profile")
}
