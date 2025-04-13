//
//  Logger+InstancesCategory.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 12.04.25.
//

import os.log
import osUtilities

extension Logger {
    
    static let instances = conditionalDebugLogger(subsystem: subsystem, category: "Instances")
}
