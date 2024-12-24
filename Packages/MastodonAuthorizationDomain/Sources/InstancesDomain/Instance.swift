//
//  Instance.swift
//  MastodonAuthorizationDomain
//
//  Created by Nikita Prokhorchuk on 30.11.24.
//

import Foundation

public struct Instance {
    
    public let id: String
    
    public let name: String
    
    public let description: String?
    
    public let usersCount: Int
    
    public let postsCount: Int
    
    public let thumbnailURL: URL?
    
    public init(
        id: String,
        name: String,
        description: String?,
        usersCount: Int,
        postsCount: Int,
        thumbnailURL: URL?
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.usersCount = usersCount
        self.postsCount = postsCount
        self.thumbnailURL = thumbnailURL
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        description = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .info).decodeIfPresent(String.self, forKey: .shortDescription)
        usersCount = Int(try container.decode(String.self, forKey: .users)) ?? 0
        postsCount = Int(try container.decode(String.self, forKey: .statuses)) ?? 0
        thumbnailURL = try container.decodeIfPresent(URL.self, forKey: .thumbnail)
    }
}

extension Instance {
    
    private enum CodingKeys: String, CodingKey {
        
        case id
        
        case name
        
        case users
        
        case statuses
        
        case thumbnail
        
        case info
        
        case shortDescription = "short_description"
    }
}

extension Instance: Decodable {
}

extension Instance: Identifiable {
}

extension Instance: Sendable {
}
