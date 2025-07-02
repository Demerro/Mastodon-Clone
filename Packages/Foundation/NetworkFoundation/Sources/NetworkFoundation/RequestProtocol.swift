//
//  RequestProtocol.swift
//  NetworkFoundation
//
//  Created by Nikita Prokhorchuk on 24.11.24.
//

import Foundation

public protocol RequestProtocol {
  
    associatedtype `Type`
    
    associatedtype Error: Swift.Error
    
    func response() async throws(Error) -> `Type`
}
