//
//  PublicTimelineRequest.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 15.04.25.
//

import Foundation
import os.log
import NetworkFoundation

public struct PublicTimelineRequest {
    
    public let networkService: NetworkService
    
    public let instanceHost: String
    
    public let accessToken: String
    
    public let maxId: String?
    
    public let limit: Int
    
    public init(networkService: NetworkService, instanceHost: String, accessToken: String, maxId: String? = nil, limit: Int = 20) {
        self.networkService = networkService
        self.instanceHost = instanceHost
        self.accessToken = accessToken
        self.maxId = maxId
        self.limit = limit
    }
}

extension PublicTimelineRequest: RequestProtocol {
    
    public func response() async throws(MastodonError) -> [Status] {
        Logger.timelines.debug("Starting request for public timeline")
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = instanceHost
        urlComponents.path = "/api/v1/timelines/public"
        urlComponents.queryItems = [
            URLQueryItem(name: "max_id", value: maxId),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        var request = URLRequest(url: urlComponents.url!)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let data = try await networkService.data(for: request)
            let decodedData = try JSONDecoder.mastodonJSONDecoder.decode([Status].self, from: data)
            Logger.timelines.info("Request for public timeline succeeded")
            return decodedData
        } catch let networkError as NetworkService.Error {
            Logger.timelines.error("Encountered network error: \(networkError)")
            throw .network(networkError)
        } catch let decodingError as DecodingError {
            Logger.timelines.error("Encountered decoding error: \(decodingError)")
            throw .decoding(decodingError)
        } catch let error {
            Logger.timelines.error("Encountered unknown error: \(error)")
            throw .unknown(error)
        }
    }
}

extension PublicTimelineRequest: Sendable {
}
