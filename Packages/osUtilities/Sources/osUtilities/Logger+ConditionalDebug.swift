//
//  Logger+ConditionalDebug.swift
//  osUtilities
//
//  Created by Nikita Prokhorchuk on 13.04.25.
//

import Foundation
import os.log

extension Logger {
    
    /**
     Creates a logger instance that behaves differently in `DEBUG` and non-`DEBUG` build configurations.

     - In `DEBUG` builds:
       - The logger is enabled only if the environment variable `"<subsystem>.<category>Debug"` is set to `"YES"`.
       - If the environment variable is not set or has a value other than `"YES"`, a disabled logger is returned (no-op logger).

     - In non-`DEBUG` builds:
       - The logger is always enabled for the given subsystem and category.

     This allows selective logging during development and ensures all logs are enabled in production builds.

     - Parameters:
       - subsystem: A string identifying the subsystem for the logger. Typically the name of the module or app component.
       - category: A string identifying the category for the logger. Used to group related log messages within a subsystem.

     - Returns: A `Logger` instance that is conditionally enabled based on build configuration and environment variables.
     
     - Example:
     ```swift
     let logger = Logger.conditionalDebugLogger(subsystem: "com.example.app", category: "network")
     logger.debug("Debug message")
     ```
     If the environment variable `com.example.app.networkDebug` is set to `"YES"`, the message will be logged. Otherwise, logging is disabled in `DEBUG` builds.
     */
    public static func conditionalDebugLogger(subsystem: String, category: String) -> Self {
#if DEBUG
        return if ProcessInfo.processInfo.environment["\(subsystem).\(category)Debug"] == "YES" {
            Logger(subsystem: subsystem, category: category)
        } else {
            Logger(.disabled)
        }
#else
        return Logger(subsystem: subsystem, category: category)
#endif
    }
}
