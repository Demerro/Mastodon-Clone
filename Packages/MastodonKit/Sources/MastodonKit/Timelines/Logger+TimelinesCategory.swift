//
//  Logger+TimelinesCategory.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 15.04.25.
//

import os.log
import osUtilities

extension Logger {
    
    static let timelines = Logger(subsystem: subsystem, category: "Timelines", flag: "Debug")
}
