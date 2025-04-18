//
//  InstancesSearchRequest.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 30.11.24.
//

import Foundation
import os.log
import NetworkFoundation

struct InstancesSearchRequest {
    
    let networkService: NetworkService
    
    let query: String
}

extension InstancesSearchRequest: RequestProtocol {
    
    func response() async throws(MastodonError) -> InstancesResponse {
        assert(!InstancesConstants.instancesSecret.isEmpty)
        
        Logger.instances.debug("Starting request for instances search")
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "instances.social"
        urlComponents.path = "/api/1.0/instances/search"
        urlComponents.queryItems = [
            URLQueryItem(name: "q", value: query)
        ]
        
        var request = URLRequest(url: urlComponents.url!)
        request.addValue("Bearer \(InstancesConstants.instancesSecret)", forHTTPHeaderField: "Authorization")
        
        do {
            let data = try await networkService.data(for: request)
            let instanceSearchResponse = try JSONDecoder.mastodonJSONDecoder.decode(InstancesResponse.self, from: data)
            Logger.instances.info("Request for instances search succeeded")
            return instanceSearchResponse
        } catch let networkError as NetworkService.Error {
            Logger.instances.error("Encountered network error: \(networkError)")
            throw .network(networkError)
        } catch let decodingError as DecodingError {
            Logger.instances.error("Encountered decoding error: \(decodingError)")
            throw .decoding(decodingError)
        } catch let error {
            Logger.instances.error("Encountered unknown error: \(error)")
            throw .unknown(error)
        }
    }
}
