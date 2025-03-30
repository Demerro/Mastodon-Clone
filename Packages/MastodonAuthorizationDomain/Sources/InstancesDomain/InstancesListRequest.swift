//
//  InstancesListRequest.swift
//  MastodonAuthorizationDomain
//
//  Created by Nikita Prokhorchuk on 7.12.24.
//

import Foundation
import os.log
import NetworkFoundation

struct InstancesListRequest {
    
    private static let baseURLString = "https://instances.social/api/1.0/instances/list"
    
    let jsonDecoder = JSONDecoder()
    
    let networkService: NetworkService
}

extension InstancesListRequest: RequestProtocol {
    
    func response() async throws(InstancesError) -> InstancesResponse {
        Logger.instancesDomain.debug("Starting request for instances list")
        
        var urlComponents = URLComponents(string: Self.baseURLString)!
        urlComponents.queryItems = [
            URLQueryItem(name: "count", value: "1000"),
            URLQueryItem(name: "include_dead", value: "false"),
            URLQueryItem(name: "include_closed", value: "false"),
            URLQueryItem(name: "min_active_users", value: "500"),
        ]
        
        var request = URLRequest(url: urlComponents.url!)
        request.addValue("Bearer \(Constants.instancesSecret)", forHTTPHeaderField: "Authorization")
        
        do {
            let data = try await networkService.data(for: request)
            let decodedData = try jsonDecoder.decode(InstancesResponse.self, from: data)
            Logger.instancesDomain.debug("Request for instances list succeeded")
            return decodedData
        } catch let networkError as NetworkService.Error {
            Logger.instancesDomain.error("Encountered network error: \(networkError)")
            throw .network(networkError)
        } catch let decodingError as DecodingError {
            Logger.instancesDomain.error("Encountered decoding error: \(decodingError)")
            throw .decoding(decodingError)
        } catch let error {
            Logger.instancesDomain.error("Encountered unknown error: \(error)")
            throw .unknown(error)
        }
    }
}
