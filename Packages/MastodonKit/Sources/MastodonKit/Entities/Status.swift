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
    
    public let repliesCount: Int
    
    public let reblogsCount: Int
    
    public let favouritesCount: Int
    
    public let favourited: Bool
    
    public let reblogged: Bool
    
    public var content: String
    
    public let account: Account
    
    public let mediaAttachments: [MediaAttachment]
    
    public let previewCard: PreviewCard?
}

extension Status {
    
    private enum CodingKeys: String, CodingKey {
        
        case id
        
        case createdAt = "created_at"
        
        case sensitive
        
        case spoilerText = "spoiler_text"
        
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
