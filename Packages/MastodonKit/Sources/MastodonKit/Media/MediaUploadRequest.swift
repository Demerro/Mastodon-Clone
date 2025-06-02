//
//  MediaUploadRequest.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 30.05.25.
//

import Foundation
import os.log
import NetworkFoundation

public struct MediaUploadRequest {
    
    public let networkService: NetworkService
    
    public let instanceHost: String
    
    public let accessToken: String
    
    public let fileData: Data

    public let fileName: String
    
    public let mimeType: String
    
    public init(networkService: NetworkService, instanceHost: String, accessToken: String, fileData: Data, fileName: String, mimeType: String) {
        self.networkService = networkService
        self.instanceHost = instanceHost
        self.accessToken = accessToken
        self.fileData = fileData
        self.fileName = fileName
        self.mimeType = mimeType
    }
}

extension MediaUploadRequest: RequestProtocol {
    
    public func response() async throws(MastodonError) -> MediaAttachment {
        Logger.media.info("Starting request for media upload")
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = instanceHost
        urlComponents.path = "/api/v2/media"
        
        var request = URLRequest(url: urlComponents.url!)
        request.httpMethod = "POST"
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        
        var multipartRequest = MultipartRequest()
        multipartRequest.add(key: "file", fileName: fileName, fileMimeType: mimeType, fileData: fileData)
        
        request.addValue(multipartRequest.httpContentTypeHeaderValue, forHTTPHeaderField: "Content-Type")
        
        do {
            let data = try await networkService.upload(for: request, from: multipartRequest.httpBody)
            let decodedData = try JSONDecoder.mastodonJSONDecoder.decode(MediaAttachment.self, from: data)
            Logger.media.info("Request for media upload succeeded")
            return decodedData
        } catch let networkError as NetworkService.Error {
            Logger.media.error("Encountered network error: \(networkError)")
            throw .network(networkError)
        } catch let decodingError as DecodingError {
            Logger.media.error("Encountered decoding error: \(decodingError)")
            throw .decoding(decodingError)
        } catch let error {
            Logger.media.error("Encountered unknown error: \(error)")
            throw .unknown(error)
        }
    }
}

extension MediaUploadRequest: Sendable {
}
