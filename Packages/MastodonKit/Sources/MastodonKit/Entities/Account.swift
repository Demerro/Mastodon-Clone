//
//  Account.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 26.12.24.
//

import Foundation

public struct Account {
    
    public let id: String
    
    public let username: String
    
    public let acct: String
    
    public let displayName: String

    public let note: String
    
    public let avatar: URL
    
    public let avatarStatic: URL
    
    public let header: URL
    
    public let headerStatic: URL
    
    public let locked: Bool
    
    public let createdAt: String
    
    public let statusesCount: Int
    
    public let followersCount: Int
    
    public let followingCount: Int
    
    public let bot: Bool
    
    public let fields: [Field]
}

extension Account {
    
    private enum CodingKeys: String, CodingKey {
        
        case id
        
        case username
        
        case acct
        
        case displayName = "display_name"
        
        case note
        
        case avatar
        
        case avatarStatic = "avatar_static"
        
        case header
        
        case headerStatic = "header_static"
        
        case locked
        
        case createdAt = "created_at"
        
        case statusesCount = "statuses_count"
        
        case followersCount = "followers_count"
        
        case followingCount = "following_count"
        
        case bot
        
        case fields
    }
}

extension Account: Sendable {
}

extension Account: Identifiable {
}

extension Account: Decodable {
}
