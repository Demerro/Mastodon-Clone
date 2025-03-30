//
//  Logger+Category.swift
//  MastodonFeedDomain
//
//  Created by Nikita Prokhorchuk on 1.02.25.
//

import Foundation
import os.log

extension Logger {
    
    static let feedDomain = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "FeedDomain")
}
