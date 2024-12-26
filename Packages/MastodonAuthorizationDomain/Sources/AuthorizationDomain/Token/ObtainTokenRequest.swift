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
    
    static let baseURLString = "https://mastodon.social/oauth/token"
    
    let jsonDecoder = JSONDecoder()
    
    let networkService: NetworkService
    
    let code: String
}

extension ObtainTokenRequest: RequestProtocol {
    
    func response() async throws(Error) -> ObtainTokenResponse {
        Logger.authorizationDomain.info("Starting request for token")
        var urlComponents = URLComponents(string: Self.baseURLString)!
        urlComponents.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "client_id", value: Constants.clientKey),
            URLQueryItem(name: "client_secret", value: Constants.clientSecret),
            URLQueryItem(name: "redirect_uri", value: Constants.redirectURI),
            URLQueryItem(name: "scope", value: Constants.scopes),
        ]
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        do {
            let data = try await networkService.data(for: request)
            let obtainTokenResponse = try jsonDecoder.decode(ObtainTokenResponse.self, from: data)
            Logger.authorizationDomain.info("Token request succeeded")
            return obtainTokenResponse
        } catch let networkError as NetworkService.Error {
            Logger.authorizationDomain.error("Encountered network error: \(networkError)")
            throw .network(networkError)
        } catch let decodingError as DecodingError {
            Logger.authorizationDomain.error("Encountered decoding error: \(decodingError)")
            throw .decoding(decodingError)
        } catch let error {
            Logger.authorizationDomain.error("Encountered unknown error: \(error)")
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
