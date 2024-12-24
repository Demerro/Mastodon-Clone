//
//  ObtainTokenResponse.swift
//  MastodonAuthorizationDomain
//
//  Created by Nikita Prokhorchuk on 25.11.24.
//

import Foundation

struct ObtainTokenResponse {
    
    let accessToken: String
}

extension ObtainTokenResponse {
    
    private enum CodingKeys: String, CodingKey {
        
        case accessToken = "access_token"
    }
}

extension ObtainTokenResponse: Decodable {
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        accessToken = try container.decode(String.self, forKey: .accessToken)
    }
}
