//
//  MediaDeleteRequest.swift
//  MastodonKit
//
//  Created on 3.06.25.
//

import Foundation
import os.log
import NetworkFoundation

struct MediaDeleteRequest {
    
    let networkService: NetworkService
    
    let instanceHost: String
    
    let accessToken: String
    
    let mediaId: String
}

extension MediaDeleteRequest: RequestProtocol {
    
    func response() async throws(MastodonError) -> Void {
        Logger.media.info("Starting request for media deletion")
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = instanceHost
        urlComponents.path = "/api/v1/media/\(mediaId)"
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "DELETE"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            _ = try await networkService.data(for: request)
            Logger.media.info("Media deletion request succeeded")
        } catch let networkError {
            Logger.media.error("Encountered network error: \(networkError)")
            throw .network(networkError)
        }
    }
}

extension MediaDeleteRequest: Sendable {
}
