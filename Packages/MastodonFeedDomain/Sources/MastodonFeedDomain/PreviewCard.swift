//
//  PreviewCard.swift
//  MastodonFeedDomain
//
//  Created by Nikita Prokhorchuk on 29.01.25.
//

import Foundation

public struct PreviewCard {
    
    public let url: URL
    
    public let title: String
    
    public let description: String
    
    public let type: PreviewCardType
    
    public let width: Double
    
    public let height: Double
    
    public let imageURL: URL?
    
    public let blurHash: String?
}

extension PreviewCard {
    
    public enum PreviewCardType: String, Decodable, Sendable {
        
        case photo
        
        case video
        
        case link
    }
}

extension PreviewCard: Decodable {
    
    private enum CodingKeys: String, CodingKey {
        
        case url
        
        case title
        
        case description
        
        case type
        
        case width
        
        case height
        
        case imageURL = "image"
        
        case blurHash = "blurhash"
    }
}

extension PreviewCard: Sendable {
}
