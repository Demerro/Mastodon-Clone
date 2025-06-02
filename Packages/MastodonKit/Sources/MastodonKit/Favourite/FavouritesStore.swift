//
//  FavouritesStore.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 26.04.25.
//

import Foundation

public final actor FavouritesStore {
    
    public init() {
    }
}

extension FavouritesStore {
    
    public func favouriteStatus(by id: Status.ID) async throws(Swift.Error) {
        guard let instanceName = await AuthorizationService.shared.instanceName,
              let accessToken = try? await AuthorizationService.shared.getAccessToken(for: instanceName)
        else {
            assertionFailure()
            throw MastodonError.unknown(nil)
        }
        let request = FavouriteStatusRequest(networkService: .api(), instanceHost: instanceName, accessToken: accessToken, id: id)
        _ = try await request.response()
    }
    
    public func unfavouriteStatus(by id: Status.ID) async throws(Swift.Error) {
        guard let instanceName = await AuthorizationService.shared.instanceName,
              let accessToken = try? await AuthorizationService.shared.getAccessToken(for: instanceName)
        else {
            assertionFailure()
            throw MastodonError.unknown(nil)
        }
        let request = UnfavouriteStatusRequest(networkService: .api(), instanceHost: instanceName, accessToken: accessToken, id: id)
        _ = try await request.response()
    }
}
