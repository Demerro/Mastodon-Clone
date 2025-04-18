//
//  MastodonError.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 16.04.25.
//

import Foundation
import NetworkFoundation

public enum MastodonError: Error {
    
    case network(NetworkService.Error)
    
    case decoding(DecodingError)
    
    case unknown(Error)
}
