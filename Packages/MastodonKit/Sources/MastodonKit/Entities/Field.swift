//
//  Field.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 26.12.24.
//

import Foundation

public struct Field {
    
    public let name: String
    
    public let value: String
    
    public let verifiedAt: Date?
    
    public init(name: String, value: String, verifiedAt: Date?) {
        self.name = name
        self.value = value
        self.verifiedAt = verifiedAt
    }
}

extension Field {
    
    private enum CodingKeys: String, CodingKey {
        
        case name
        
        case value
        
        case verifiedAt = "verified_at"
    }
}

extension Field: Decodable {
}

extension Field: Sendable {
}

extension Field: Hashable {
}
