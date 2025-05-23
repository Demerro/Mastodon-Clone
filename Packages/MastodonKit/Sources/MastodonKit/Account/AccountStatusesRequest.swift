//
//  AccountStatusesRequest.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 1.02.25.
//

import Foundation
import os.log
import NetworkFoundation

struct AccountStatusesRequest {
    
    let networkService: NetworkService
    
    let instanceHost: String
    
    let accessToken: String
    
    let accountID: String
    
    var onlyMedia = false
    
    var excludeReplies = false
    
    var excludeReblogs = false
    
    var limit = 20
    
    var maxId: String?
}

extension AccountStatusesRequest: RequestProtocol {
    
    func response() async throws(MastodonError) -> [Status] {
        Logger.account.debug("Starting request for account(id: \(accountID) statuses")
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = instanceHost
        urlComponents.path = "/api/v1/accounts/\(accountID)/statuses"
        urlComponents.queryItems = [
            URLQueryItem(name: "only_media", value: String(onlyMedia)),
            URLQueryItem(name: "exclude_replies", value: String(excludeReplies)),
            URLQueryItem(name: "exclude_reblogs", value: String(excludeReblogs)),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "max_id", value: maxId),
        ]
        
        var request = URLRequest(url: urlComponents.url!)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let data = try await networkService.data(for: request)
            let decodedData = try JSONDecoder.mastodonJSONDecoder.decode([Status].self, from: data)
            Logger.account.info("Request for account(id: \(accountID)) statuses succeeded")
            return decodedData
        } catch let networkError as NetworkService.Error {
            Logger.account.error("Encountered network error: \(networkError)")
            throw .network(networkError)
        } catch let decodingError as DecodingError {
            Logger.account.error("Encountered decoding error: \(decodingError)")
            throw .decoding(decodingError)
        } catch let error {
            Logger.account.error("Encountered unknown error: \(error)")
            throw .unknown(error)
        }
    }
}

extension AccountStatusesRequest: Sendable {
}
