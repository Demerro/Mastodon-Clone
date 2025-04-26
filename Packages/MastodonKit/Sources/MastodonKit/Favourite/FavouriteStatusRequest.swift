//
//  FavouriteRequest.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 26.04.25.
//

import Foundation
import os.log
import NetworkFoundation

struct FavouriteStatusRequest {
    
    let networkService: NetworkService
    
    let instanceHost: String
    
    let accessToken: String
    
    let id: String
}

extension FavouriteStatusRequest: RequestProtocol {
    
    func response() async throws(MastodonError) -> Status {
        Logger.favourites.debug("Starting request for favourite status")
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = instanceHost
        urlComponents.path = "/api/v1/statuses/\(id)/favourite"
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let data = try await networkService.data(for: request)
            let decodedData = try JSONDecoder.mastodonJSONDecoder.decode(Status.self, from: data)
            Logger.favourites.info("Request for favourite status succeeded")
            return decodedData
        } catch let networkError as NetworkService.Error {
            Logger.favourites.error("Encountered network error: \(networkError)")
            throw .network(networkError)
        } catch let decodingError as DecodingError {
            Logger.favourites.error("Encountered decoding error: \(decodingError)")
            throw .decoding(decodingError)
        } catch let error {
            Logger.favourites.error("Encountered unknown error: \(error)")
            throw .unknown(error)
        }
    }
}

extension FavouriteStatusRequest: Sendable {
}
