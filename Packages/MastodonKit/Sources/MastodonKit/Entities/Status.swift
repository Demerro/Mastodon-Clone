//
//  Status.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 5.04.25.
//

import Foundation

public struct Status: Sendable, Decodable, Identifiable {
    
    public let id: String
    
    public let createdAt: Date
    
    public let sensitive: Bool
    
    public let spoilerText: String
    
    public let url: URL
    
    public let repliesCount: Int
    
    public var reblogsCount: Int
    
    public var favouritesCount: Int
    
    public var favourited: Bool
    
    public var reblogged: Bool
    
    public var content: String
    
    public let account: Account
    
    public let mediaAttachments: [MediaAttachment]
    
    public let previewCard: PreviewCard?
}

extension Status {
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        sensitive = try container.decode(Bool.self, forKey: .sensitive)
        spoilerText = try container.decode(String.self, forKey: .spoilerText)
        url = try container.decode(URL.self, forKey: .url)
        repliesCount = try container.decode(Int.self, forKey: .repliesCount)
        reblogsCount = try container.decode(Int.self, forKey: .reblogsCount)
        favouritesCount = try container.decode(Int.self, forKey: .favouritesCount)
        favourited = try container.decodeIfPresent(Bool.self, forKey: .favourited) ?? false
        reblogged = try container.decodeIfPresent(Bool.self, forKey: .reblogged) ?? false
        content = try container.decode(String.self, forKey: .content)
        account = try container.decode(Account.self, forKey: .account)
        mediaAttachments = try container.decodeIfPresent([MediaAttachment].self, forKey: .mediaAttachments) ?? []
        previewCard = try container.decodeIfPresent(PreviewCard.self, forKey: .previewCard)
    }
}

extension Status {
    
    private enum CodingKeys: String, CodingKey {
        
        case id
        
        case createdAt = "created_at"
        
        case sensitive
        
        case spoilerText = "spoiler_text"
        
        case url
        
        case repliesCount = "replies_count"
        
        case reblogsCount = "reblogs_count"
        
        case favouritesCount = "favourites_count"
        
        case favourited
        
        case reblogged
        
        case content
        
        case account
        
        case mediaAttachments = "media_attachments"
        
        case previewCard = "card"
    }
}

extension Status {
    
    public enum Visibility: String {
        case `public`
        case unlisted
        case `private`
    }
}
