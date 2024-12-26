//
//  Logger+Category.swift
//  Network
//
//  Created by Nikita Prokhorchuk on 8.12.24.
//

import Foundation.NSBundle
import os.log

extension Logger {
    
    static let network = Logger(subsystem: Bundle.main.bundleIdentifier!, category: "NetworkService")
}
