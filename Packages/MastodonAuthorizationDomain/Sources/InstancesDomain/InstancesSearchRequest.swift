//
//  InstancesSearchRequest.swift
//  MastodonAuthorizationDomain
//
//  Created by Nikita Prokhorchuk on 30.11.24.
//

import Foundation
import os.log
import NetworkFoundation

struct InstancesSearchRequest {
    
    static let baseURLString = "https://instances.social/api/1.0/instances/search"
    
    let jsonDecoder = JSONDecoder()
    
    let networkService: NetworkService
    
    let query: String
}

extension InstancesSearchRequest: RequestProtocol {
    
    func response() async throws(InstancesError) -> InstancesResponse {
        Logger.request.debug("Starting request for instances search")
        var urlComponents = URLComponents(string: Self.baseURLString)!
        urlComponents.queryItems = [
            URLQueryItem(name: "q", value: query)
        ]
        var request = URLRequest(url: urlComponents.url!)
        request.addValue("Bearer \(Constants.instancesSecret)", forHTTPHeaderField: "Authorization")
        do {
            let data = try await networkService.data(for: request)
            let instanceSearchResponse = try jsonDecoder.decode(InstancesResponse.self, from: data)
            Logger.request.debug("Request for instances search succeeded")
            return instanceSearchResponse
        } catch let networkError as NetworkService.Error {
            Logger.request.error("Encountered network error: \(networkError)")
            throw .network(networkError)
        } catch let decodingError as DecodingError {
            Logger.request.error("Encountered decoding error: \(decodingError)")
            throw .decoding(decodingError)
        } catch let error {
            Logger.request.error("Encountered unknown error: \(error)")
            throw .unknown(error)
        }
    }
}
