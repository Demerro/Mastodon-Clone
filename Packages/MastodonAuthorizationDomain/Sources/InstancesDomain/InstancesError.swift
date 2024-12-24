//
//  InstancesError.swift
//  MastodonAuthorizationDomain
//
//  Created by Nikita Prokhorchuk on 14.12.24.
//

import Foundation
import NetworkFoundation

public enum InstancesError: Error {
    
    case network(NetworkService.Error)
    
    case decoding(DecodingError)
    
    case unknown(Swift.Error)
}
