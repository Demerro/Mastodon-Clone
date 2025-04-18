//
//  ProfileRequest.swift
//  MastodonAccountsDomain
//
//  Created by Nikita Prokhorchuk on 26.12.24.
//

import Foundation
import os.log
import NetworkFoundation

struct ProfileRequest {

    let networkService: NetworkService
    
    let instanceHost: String
    
    let accessToken: String
}

extension ProfileRequest: RequestProtocol {
    
    func response() async throws(MastodonError) -> Account {
        Logger.profile.debug("Starting request for current account")
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = instanceHost
        urlComponents.path = "/api/v1/accounts/verify_credentials"
        
        var request = URLRequest(url: urlComponents.url!)
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        do {
            let data = try await networkService.data(for: request)
            let decodedData = try JSONDecoder.mastodonJSONDecoder.decode(Account.self, from: data)
            Logger.profile.info("Request for current account succeeded")
            return decodedData
        } catch let networkError as NetworkService.Error {
            Logger.profile.error("Encountered network error: \(networkError)")
            throw .network(networkError)
        } catch let decodingError as DecodingError {
            Logger.profile.error("Encountered decoding error: \(decodingError)")
            throw .decoding(decodingError)
        } catch let error {
            Logger.profile.error("Encountered unknown error: \(error)")
            throw .unknown(error)
        }
    }
}
