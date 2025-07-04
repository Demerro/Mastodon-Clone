//
//  Logger+StatusCategory.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 2.06.25.
//

import os.log
import osUtilities

extension Logger {
    
    static let status = Logger(subsystem: subsystem, category: "Status", flag: "Debug")
}
