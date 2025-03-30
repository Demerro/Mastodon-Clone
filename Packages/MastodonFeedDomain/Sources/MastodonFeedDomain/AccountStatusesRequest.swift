//
//  AccountStatusesRequest.swift
//  MastodonFeedDomain
//
//  Created by Nikita Prokhorchuk on 1.02.25.
//

import Foundation
import os.log
import NetworkFoundation

public struct AccountStatusesRequest {
    
    public let jsonDecoder: JSONDecoder = {
        let iso8601Formatter = DateFormatter()
        iso8601Formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        iso8601Formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let jsonDecoder = JSONDecoder()
        jsonDecoder.dateDecodingStrategy = .formatted(iso8601Formatter)
        
        return jsonDecoder
    }()
    
    public let networkService: NetworkService
    
    public let instanceHost: String
    
    public let accessToken: String
    
    public let accountID: String
    
    public init(networkService: NetworkService, instanceHost: String, accessToken: String, accountID: String) {
        self.networkService = networkService
        self.instanceHost = instanceHost
        self.accessToken = accessToken
        self.accountID = accountID
    }
}

extension AccountStatusesRequest: RequestProtocol {
    
    public func response() async throws(Error) -> [Status] {
        Logger.feedDomain.info("Starting request for account statuses")
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = instanceHost
        urlComponents.path = "/api/v1/accounts/\(accountID)/statuses"
        
        var request = URLRequest(url: urlComponents.url!)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let data = try await networkService.data(for: request)
            let decodedData = try jsonDecoder.decode([Status].self, from: data)
            Logger.feedDomain.debug("Request for account statuses succeeded")
            return decodedData
        } catch let networkError as NetworkService.Error {
            Logger.feedDomain.error("Encountered network error: \(networkError)")
            throw .network(networkError)
        } catch let decodingError as DecodingError {
            Logger.feedDomain.error("Encountered decoding error: \(decodingError)")
            throw .decoding(decodingError)
        } catch let error {
            Logger.feedDomain.error("Encountered unknown error: \(error)")
            throw .unknown(error)
        }
    }
}

extension AccountStatusesRequest {
    
    public enum Error: Swift.Error {
        
        case network(NetworkService.Error)
        
        case decoding(DecodingError)
        
        case unknown(Swift.Error)
    }
}

extension AccountStatusesRequest: Sendable {
}
