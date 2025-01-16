//
//  ProfileStore.swift
//  MastodonAccountsDomain
//
//  Created by Nikita Prokhorchuk on 28.12.24.
//

import AuthorizationDomain

@MainActor
public final class ProfileStore {
    
    public var instanceName: String {
        AuthorizationService.instanceName ?? ""
    }
    
    public var profile: Account? {
        get async throws {
            guard let instanceHost = AuthorizationService.instanceName,
                  let accessToken = try? AuthorizationService.getAccessToken(for: instanceHost)
            else {
                return nil
            }
            return try await ProfileRequest(
                networkService: .api,
                instanceHost: instanceHost,
                accessToken: accessToken
            ).response()
        }
    }
    
    public init() {
    }
}
