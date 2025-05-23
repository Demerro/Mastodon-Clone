//
//  Logger+AccountStatusesCategory.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 13.04.25.
//

import os.log
import osUtilities

extension Logger {
    
    static let account = Logger(subsystem: subsystem, category: "Account", flag: "Debug")
}
