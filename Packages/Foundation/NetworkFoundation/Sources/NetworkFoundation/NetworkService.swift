//
//  NetworkService.swift
//  Network
//
//  Created by Nikita Prokhorchuk on 24.11.24.
//

import Foundation
import os.log

public struct NetworkService: Sendable {
    
    public let session: URLSession
    
    private init(session: URLSession) {
        self.session = session
    }
    
    public func data(for request: URLRequest) async throws(Error) -> Data {
        Logger.network.debug("Starting network request")
        
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(for: request)
        } catch let urlError as URLError {
            Logger.network.error("Encountered URL error: \(urlError)")
            throw .clientOrTransportSpecific(urlError)
        } catch let error {
            Logger.network.error("Encountered error: \(error)")
            throw .clientOrTransport(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            Logger.network.error("Encountered unknown error")
            throw .unknown
        }
        
        switch httpResponse.statusCode {
        case 400:
            Logger.network.error("Encountered bad request error")
            throw .badRequest
        case 401:
            Logger.network.error("Encountered unauthorized error")
            throw .unauthorized
        case 403:
            Logger.network.error("Encountered forbidden error")
            throw .forbidden
        case 404:
            Logger.network.error("Encountered not found error")
            throw .notFound
        case 500:
            Logger.network.error("Encountered server error")
            throw .server(httpResponse)
        case 200...299:
            Logger.network.debug("Network request succeeded")
            return data
        default:
            Logger.network.error("Encountered unknown error")
            throw .unknown
        }
    }
}

extension NetworkService {
    
    public enum Error: Swift.Error {
        
        case clientOrTransportSpecific(URLError)
        
        case clientOrTransport(Swift.Error)
        
        case server(HTTPURLResponse)
        
        case badRequest
        
        case unauthorized
        
        case forbidden
        
        case notFound
        
        case unknown
    }
}

extension NetworkService {
    
    public static let api: NetworkService = {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["Content-Type": "application/json"]
        config.waitsForConnectivity = true
        return NetworkService(session: URLSession(configuration: config))
    }()
    
    public static let apiWithCache: NetworkService = {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["Content-Type": "application/json"]
        config.waitsForConnectivity = true
        config.requestCachePolicy = .returnCacheDataElseLoad
        return NetworkService(session: URLSession(configuration: config))
    }()
    
    public static let imageDownload = NetworkService(session: .shared)
    
    public static let imageDownloadWithCache: NetworkService = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        return NetworkService(session: URLSession(configuration: config))
    }()
}
