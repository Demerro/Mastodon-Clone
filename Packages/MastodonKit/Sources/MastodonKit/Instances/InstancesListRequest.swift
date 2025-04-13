//
//  InstancesListRequest.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 7.12.24.
//

import Foundation
import os.log
import NetworkFoundation

struct InstancesListRequest {
    
    let jsonDecoder = JSONDecoder()
    
    let networkService: NetworkService
}

extension InstancesListRequest: RequestProtocol {
    
    func response() async throws(InstancesError) -> InstancesResponse {
        assert(!InstancesConstants.instancesSecret.isEmpty)
        
        Logger.instances.debug("Starting request for instances list")
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = "instances.social"
        urlComponents.path = "/api/1.0/instances/list"
        urlComponents.queryItems = [
            URLQueryItem(name: "count", value: "1000"),
            URLQueryItem(name: "include_dead", value: "false"),
            URLQueryItem(name: "include_closed", value: "false"),
            URLQueryItem(name: "min_active_users", value: "500"),
        ]
        
        var request = URLRequest(url: urlComponents.url!)
        request.addValue("Bearer \(InstancesConstants.instancesSecret)", forHTTPHeaderField: "Authorization")
        
        do {
            let data = try await networkService.data(for: request)
            let decodedData = try jsonDecoder.decode(InstancesResponse.self, from: data)
            Logger.instances.info("Request for instances list succeeded")
            return decodedData
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
