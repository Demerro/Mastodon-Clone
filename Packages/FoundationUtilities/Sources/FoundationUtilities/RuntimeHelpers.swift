//
//  RuntimeHelpers.swift
//  FoundationUtilities
//
//  Created by Nikita Prokhorchuk on 9.01.25.
//

import Foundation

@inlinable
public func NSSelectorFromEncodedString(_ encodedSelectorName: String) -> Selector {
    NSSelectorFromString(String(data: Data(base64Encoded: encodedSelectorName)!, encoding: .utf8)!)
}

@inlinable
public func NSClassFromEncodedString(_ encodedClassName: String) -> AnyClass? {
    NSClassFromString(String(data: Data(base64Encoded: encodedClassName)!, encoding: .utf8)!)
}
