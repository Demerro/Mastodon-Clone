//
//  ObtainTokenRequest.swift
//  MastodonAuthorizationDomain
//
//  Created by Nikita Prokhorchuk on 24.11.24.
//

import Foundation
import os.log
import NetworkFoundation

struct ObtainTokenRequest {
    
    let jsonDecoder = JSONDecoder()
    
    let networkService: NetworkService
    
    let instanceHost: String
    
    let code: String
}

extension ObtainTokenRequest: RequestProtocol {
    
    func response() async throws(Error) -> ObtainTokenResponse {
        Logger.authorization.info("Starting request for token")
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = instanceHost
        urlComponents.path = "/oauth/token"
        urlComponents.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "client_id", value: AuthorizationConstants.clientKey),
            URLQueryItem(name: "client_secret", value: AuthorizationConstants.clientSecret),
            URLQueryItem(name: "redirect_uri", value: AuthorizationConstants.redirectURI),
            URLQueryItem(name: "scope", value: AuthorizationConstants.scopes),
        ]
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        
        do {
            let data = try await networkService.data(for: request)
            let decodedData = try jsonDecoder.decode(ObtainTokenResponse.self, from: data)
            Logger.authorization.info("Token request succeeded")
            return decodedData
        } catch let networkError as NetworkService.Error {
            Logger.authorization.error("Encountered network error: \(networkError)")
            throw .network(networkError)
        } catch let decodingError as DecodingError {
            Logger.authorization.error("Encountered decoding error: \(decodingError)")
            throw .decoding(decodingError)
        } catch let error {
            Logger.authorization.error("Encountered unknown error: \(error)")
            throw .unknown(error)
        }
    }
}

extension ObtainTokenRequest {
    
    enum Error: Swift.Error {
        
        case network(NetworkService.Error)
        
        case decoding(DecodingError)
        
        case unknown(Swift.Error)
    }
}
