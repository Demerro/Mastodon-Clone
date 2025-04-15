//
//  Logger+Extras.swift
//  osUtilities
//
//  Created by Nikita Prokhorchuk on 13.04.25.
//

import Foundation
import os.log

extension Logger {
    
    public init(subsystem: String, category: String, flag: String) {
#if RELEASE
        self.init(subsystem: subsystem, category: category)
#else
        if ProcessInfo.processInfo.environment["\(subsystem).\(category).\(flag)"] == "YES" {
            self.init(subsystem: subsystem, category: category)
        } else {
            self.init(.disabled)
        }
#endif
    }
}
