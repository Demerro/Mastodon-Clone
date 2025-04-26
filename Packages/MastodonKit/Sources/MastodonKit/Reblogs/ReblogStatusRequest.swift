//
//  ReblogsStatusRequest.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 26.04.25.
//

import Foundation
import os.log
import NetworkFoundation

struct ReblogsStatusRequest {
    
    let networkService: NetworkService
    
    let instanceHost: String
    
    let accessToken: String
    
    let id: String
}

extension ReblogsStatusRequest: RequestProtocol {
    
    func response() async throws(MastodonError) -> Status {
        Logger.reblogs.debug("Starting request for reblog status")
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = instanceHost
        urlComponents.path = "/api/v1/statuses/\(id)/reblog"
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let data = try await networkService.data(for: request)
            let decodedData = try JSONDecoder.mastodonJSONDecoder.decode(Status.self, from: data)
            Logger.reblogs.info("Request for reblog status succeeded")
            return decodedData
        } catch let networkError as NetworkService.Error {
            Logger.reblogs.error("Encountered network error: \(networkError)")
            throw .network(networkError)
        } catch let decodingError as DecodingError {
            Logger.reblogs.error("Encountered decoding error: \(decodingError)")
            throw .decoding(decodingError)
        } catch let error {
            Logger.reblogs.error("Encountered unknown error: \(error)")
            throw .unknown(error)
        }
    }
}

extension ReblogsStatusRequest: Sendable {
}
