//
//  RequestProtocol.swift
//  Network
//
//  Created by Nikita Prokhorchuk on 24.11.24.
//

import Foundation

public protocol RequestProtocol {
  
    associatedtype `Type`: Decodable
    
    associatedtype Error: Swift.Error
    
    var jsonDecoder: JSONDecoder { get }
    
    func response() async throws(Error) -> `Type`
}
