//
//  PostStatusRequest.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 2.06.25.
//

import Foundation
import os.log
import NetworkFoundation

struct PostStatusRequest {
    
    let networkService: NetworkService
    
    let instanceHost: String
    
    let accessToken: String
    
    let status: String
    
    var mediaIds: [String]?
    
    var sensitive: Bool = false
    
    var spoilerText: String?
    
    var visibility: Status.Visibility = .public
    
    init(
        networkService: NetworkService,
        instanceHost: String,
        accessToken: String,
        status: String,
        mediaIds: [String]? = nil,
        sensitive: Bool,
        spoilerText: String? = nil,
        visibility: Status.Visibility
    ) {
        self.networkService = networkService
        self.instanceHost = instanceHost
        self.accessToken = accessToken
        self.status = status
        self.mediaIds = mediaIds
        self.sensitive = sensitive
        self.spoilerText = spoilerText
        self.visibility = visibility
    }
}

extension PostStatusRequest: RequestProtocol {
    
    func response() async throws(MastodonError) -> Status {
        Logger.status.info("Starting request for status upload")
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = instanceHost
        urlComponents.path = "/default/v1/statuses"
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.addValue("Idempotency-Key", forHTTPHeaderField: UUID().uuidString)
        
        var multipartRequest = MultipartRequest()
        multipartRequest.add(key: "status", value: status)
        multipartRequest.add(key: "sensitive", value: String(sensitive))
        multipartRequest.add(key: "visibility", value: visibility.rawValue)
        if let mediaIds {
            multipartRequest.add(key: "media_ids[]", value: mediaIds.joined(separator: ","))
        }
        if let spoilerText {
            multipartRequest.add(key: "spoiler_text", value: spoilerText)
        }
        
        request.httpBody = multipartRequest.httpBody
        request.addValue(multipartRequest.httpContentTypeHeaderValue, forHTTPHeaderField: "Content-Type")
        
        do {
            let data = try await networkService.data(for: request)
            let decodedData = try JSONDecoder.mastodonJSONDecoder.decode(Status.self, from: data)
            Logger.status.info("Request for status upload succeeded")
            return decodedData
        } catch let networkError as NetworkService.Error {
            Logger.status.error("Encountered network error: \(networkError)")
            throw .network(networkError)
        } catch let decodingError as DecodingError {
            Logger.status.error("Encountered decoding error: \(decodingError)")
            throw .decoding(decodingError)
        } catch let error {
            Logger.status.error("Encountered unknown error: \(error)")
            throw .unknown(error)
        }
    }
}
