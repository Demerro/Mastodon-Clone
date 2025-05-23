//
//  AccountRequest.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 2.05.25.
//

import Foundation
import os.log
import NetworkFoundation

struct AccountRequest {
    
    let networkService: NetworkService
    
    let instanceHost: String
    
    let accessToken: String
    
    let acct: String
}

extension AccountRequest: RequestProtocol {
    
    func response() async throws(MastodonError) -> Account {
        Logger.account.debug("Starting request for account(acct: \(acct))")
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = instanceHost
        urlComponents.path = "/api/v1/accounts/lookup"
        urlComponents.queryItems = [
            URLQueryItem(name: "acct", value: acct)
        ]
        
        var request = URLRequest(url: urlComponents.url!)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let data = try await networkService.data(for: request)
            let decodedData = try JSONDecoder.mastodonJSONDecoder.decode(Account.self, from: data)
            Logger.account.info("Request for account(acct: \(acct)) succeeded")
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

extension AccountRequest: Sendable {
}
