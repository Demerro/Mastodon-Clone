//
//  StatusesWithoutRepliesStore.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 2.05.25.
//

@MainActor
public final class StatusesWithoutRepliesStore {
    
    private(set) public var statuses = [Status]()
    
    private var maxId: String?
    
    private(set) public var allStatusesDisplayed = false
    
    var accountId: String?
    
    var shouldCache = false
}

extension StatusesWithoutRepliesStore {
    
    public func refreshStatuses() async throws(Swift.Error) {
        guard let accountId else {
            assertionFailure("Account ID is nil")
            return
        }
        allStatusesDisplayed = false
        maxId = nil
        let statuses = try await loadStatuses(with: accountId)
        maxId = statuses.last?.id
        self.statuses = statuses
    }
    
    public func appendStatuses() async throws(Swift.Error) {
        guard !allStatusesDisplayed else { return }
        guard let accountId else {
            assertionFailure("Account ID is nil")
            return
        }
        let statuses = try await loadStatuses(with: accountId)
        if let maxId = statuses.last?.id {
            self.maxId = maxId
            self.statuses += statuses
        } else {
            allStatusesDisplayed = true
        }
    }
}

extension StatusesWithoutRepliesStore {
    
    private func loadStatuses(with accountId: String) async throws(Swift.Error) -> [Status] {
        guard let instanceName = AuthorizationService.shared.instanceName,
              let accessToken = try? AuthorizationService.shared.getAccessToken(for: instanceName)
        else {
            assertionFailure()
            throw MastodonError.unknown(nil)
        }
        let request = AccountStatusesRequest(
            networkService: shouldCache ? .apiWithCache : .api,
            instanceHost: instanceName,
            accessToken: accessToken,
            accountID: accountId,
            excludeReplies: true,
            maxId: maxId
        )
        return try await Utils.parseHTMLContentAndSortStatuses(try await request.response())
    }
}
