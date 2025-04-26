//
//  Logger+ReblogsCategory.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 26.04.25.
//

import os.log
import osUtilities

extension Logger {
    
    static let reblogs = Logger(subsystem: subsystem, category: "Reblogs", flag: "Debug")
}
