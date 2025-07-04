//
//  MediaUploadRequest.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 30.05.25.
//

import Foundation
import os.log
import NetworkFoundation

struct MediaUploadRequest {
    
    let networkService: NetworkService
    
    let instanceHost: String
    
    let accessToken: String
    
    let fileData: Data

    let fileName: String
    
    let mimeType: String
}

extension MediaUploadRequest: RequestProtocol {
    
    func response() async throws(MastodonError) -> MediaAttachment {
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
        request.httpBody = multipartRequest.httpBody
        request.addValue(multipartRequest.httpContentTypeHeaderValue, forHTTPHeaderField: "Content-Type")
        
        do {
            let data = try await networkService.data(for: request)
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
