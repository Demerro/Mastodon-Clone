//
//  Logger+Category.swift
//  NetworkFoundation
//
//  Created by Nikita Prokhorchuk on 8.12.24.
//

import os.log
import osUtilities

extension Logger {
    
    static let network = Logger(subsystem: "com.demerro.NetworkFoundation", category: "NetworkService", flag: "Debug")
}
