//
//  Logger+Categories.swift
//  osUtilities
//
//  Created by Nikita Prokhorchuk on 24.11.24.
//

import Foundation
import os.log

extension Logger {
    
    public static let request = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "Request")
    
    public static let network = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "NetworkService")
}
