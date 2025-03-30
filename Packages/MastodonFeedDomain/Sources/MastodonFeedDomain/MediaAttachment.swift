//
//  MediaAttachment.swift
//  MastodonFeedDomain
//
//  Created by Nikita Prokhorchuk on 1.02.25.
//

import Foundation

public struct MediaAttachment: Sendable, Decodable, Identifiable {
    
    public let id: String
    
    public let type: MediaType
    
    public let url: URL
    
    public let previewURL: URL
    
    public let meta: Meta
    
    public let blurHash: String?
}

extension MediaAttachment {
    
    private enum CodingKeys: String, CodingKey {
        
        case id
        
        case type
        
        case url
        
        case previewURL = "preview_url"
        
        case meta
        
        case blurHash = "blurhash"
    }
}

extension MediaAttachment {
    
    public enum MediaType: String, Sendable, Decodable {
        
        case image
        
        case gifv
        
        case video
                
        case audio
        
        case unknown
    }
}

extension MediaAttachment {
    
    public struct Meta: Sendable, Decodable {
        
        public let original: Size
        
        public let small: Size
    }
}

extension MediaAttachment.Meta {
    
    public struct Size: Sendable, Decodable {
        
        public let width: Double
        
        public let height: Double
        
        public let duration: Double?
    }
}
