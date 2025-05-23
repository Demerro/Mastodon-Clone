//
//  VerifyCredentialsRequest.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 2.05.25.
//

import Foundation
import os.log
import NetworkFoundation

struct VerifyCredentialsRequest {

    let networkService: NetworkService
    
    let instanceHost: String
    
    let accessToken: String
}

extension VerifyCredentialsRequest: RequestProtocol {
    
    func response() async throws(MastodonError) -> Account {
        Logger.account.debug("Starting request for credentials verification")
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = instanceHost
        urlComponents.path = "/api/v1/accounts/verify_credentials"
        
        var request = URLRequest(url: urlComponents.url!)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let data = try await networkService.data(for: request)
            let decodedData = try JSONDecoder.mastodonJSONDecoder.decode(Account.self, from: data)
            Logger.account.info("Request for credentials verification succeeded")
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
