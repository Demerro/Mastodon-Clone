//
//  ReblogsStore.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 26.04.25.
//

import Foundation

public final actor ReblogsStore {
    
    public init() {
    }
}

extension ReblogsStore {
    
    public func reblogStatus(by id: Status.ID) async throws(Swift.Error) {
        guard let instanceName = await AuthorizationService.shared.instanceName,
              let accessToken = try? await AuthorizationService.shared.getAccessToken(for: instanceName)
        else {
            assertionFailure()
            throw MastodonError.unknown(nil)
        }
        let request = ReblogsStatusRequest(networkService: .default(), instanceHost: instanceName, accessToken: accessToken, id: id)
        _ = try await request.response()
    }
    
    public func unreblogStatus(by id: Status.ID) async throws(Swift.Error) {
        guard let instanceName = await AuthorizationService.shared.instanceName,
              let accessToken = try? await AuthorizationService.shared.getAccessToken(for: instanceName)
        else {
            assertionFailure()
            throw MastodonError.unknown(nil)
        }
        let request = UnreblogsStatusRequest(networkService: .default(), instanceHost: instanceName, accessToken: accessToken, id: id)
        _ = try await request.response()
    }
}
