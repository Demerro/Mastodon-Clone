//
//  Logger+MediaCategory.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 30.05.25.
//

import os.log
import osUtilities

extension Logger {
    
    static let media = Logger(subsystem: subsystem, category: "Media", flag: "Debug")
}