//
//  NetworkService.swift
//  NetworkFoundation
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
}

extension NetworkService {
    
    public func data(for request: URLRequest) async throws(Error) -> Data {
        Logger.network.debug("Starting data request")
        
        return try await performNetworkRequest { [session] in
            try await session.data(for: request)
        }
    }
    
    public func upload(for request: URLRequest, from data: Data) async throws(Error) -> Data {
        Logger.network.debug("Starting upload request")
        return try await performNetworkRequest { [session] in
            try await session.upload(for: request, from: data)
        }
    }
}

extension NetworkService {
    
    private func performNetworkRequest(task: () async throws -> (Data, URLResponse)) async throws(Error) -> Data {
        let (data, response): (Data, URLResponse)
        
        do {
            (data, response) = try await task()
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
        
        try validateResponse(httpResponse)
        
        Logger.network.debug("Network request succeeded")
        return data
    }
    
    private func validateResponse(_ httpResponse: HTTPURLResponse) throws(Error) {
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
        case 422:
            Logger.network.error("Encountered unprocessable entity error")
            throw .unprocessableEntity
        case 500:
            Logger.network.error("Encountered server error")
            throw .server(httpResponse)
        case 200...299:
            return
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
        
        case unprocessableEntity
        
        case unknown
    }
}

extension NetworkService {
    
    public static func `default`(delegate: URLSessionDelegate? = nil, delegateQueue: OperationQueue? = nil) -> NetworkService {
        NetworkService(session: URLSession(configuration: .default, delegate: delegate, delegateQueue: delegateQueue))
    }
    
    public static func defaultWithCache(delegate: URLSessionDelegate? = nil, delegateQueue: OperationQueue? = nil) -> NetworkService {
        let configuration = URLSessionConfiguration.default
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        return NetworkService(session: URLSession(configuration: configuration, delegate: delegate, delegateQueue: delegateQueue))
    }
    
    public static func api(delegate: URLSessionDelegate? = nil, delegateQueue: OperationQueue? = nil) -> NetworkService {
        createNetworkService(withCache: false, delegate: delegate, delegateQueue: delegateQueue)
    }
    
    public static func apiWithCache(delegate: URLSessionDelegate? = nil, delegateQueue: OperationQueue? = nil) -> NetworkService {
        createNetworkService(withCache: true, delegate: delegate, delegateQueue: delegateQueue)
    }
    
    private static func createNetworkService(withCache: Bool, delegate: URLSessionDelegate?, delegateQueue: OperationQueue?) -> NetworkService {
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["Content-Type": "application/json"]
        config.waitsForConnectivity = true
        
        if withCache {
            config.requestCachePolicy = .returnCacheDataElseLoad
        }
        
        return NetworkService(session: URLSession(configuration: config, delegate: delegate, delegateQueue: delegateQueue))
    }
}
