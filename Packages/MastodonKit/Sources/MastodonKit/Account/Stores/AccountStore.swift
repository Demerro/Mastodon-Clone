//
//  AccountStore.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 2.05.25.
//

import Foundation

@MainActor
public final class AccountStore {
    
    private let dateFormatter: DateFormatter = {
        $0.dateStyle = .medium
        $0.timeStyle = .none
        return $0
    }(DateFormatter())
    
    private(set) public var account: Account?

    private let username: String?
    
    public let statusesWithMediaOnlyStore = StatusesWithMediaOnlyStore()
    
    public let statusesWithoutReblogsStore = StatusesWithoutReblogsStore()
 
    public let statusesWithoutRepliesStore = StatusesWithoutRepliesStore()
    
    public init(username: String?) {
        self.username = username
        statusesWithMediaOnlyStore.shouldCache = username == nil
        statusesWithoutReblogsStore.shouldCache = username == nil
        statusesWithoutRepliesStore.shouldCache = username == nil
    }
}

extension AccountStore {
    
    public func fetchAccount() async throws(MastodonError) {
        guard let instanceName = AuthorizationService.shared.instanceName,
              let accessToken = try? AuthorizationService.shared.getAccessToken(for: instanceName)
        else {
            assertionFailure()
            throw MastodonError.unknown(nil)
        }
        var account = if let username {
            try await AccountRequest(networkService: .default(), instanceHost: instanceName, accessToken: accessToken, acct: username)
                .response()
        } else {
            try await VerifyCredentialsRequest(networkService: .defaultWithCache(), instanceHost: instanceName, accessToken: accessToken)
                .response()
        }
        account.fields.insert(Field(name: "Joined", value: dateFormatter.string(from: account.createdAt), verifiedAt: nil), at: 0)
        self.account = account
        statusesWithMediaOnlyStore.accountId = account.id
        statusesWithoutReblogsStore.accountId = account.id
        statusesWithoutRepliesStore.accountId = account.id
    }
}
