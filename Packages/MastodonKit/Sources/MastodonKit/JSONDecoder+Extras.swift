//
//  JSONDecoder+Extras.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 16.04.25.
//

import Foundation

extension JSONDecoder {
    
    static let mastodonJSONDecoder: JSONDecoder = {
        let iso8601Formatter = DateFormatter()
        iso8601Formatter.locale = Locale(identifier: "en_US_POSIX")
        iso8601Formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
        iso8601Formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .formatted(iso8601Formatter)
        
        return jsonDecoder
    }()
}
