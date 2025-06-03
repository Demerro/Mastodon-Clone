//
//  InstancesStore.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 30.11.24.
//

@MainActor
public final class InstancesStore {
    
    public private(set) var instances = [Instance]()
    
    public init() {
    }
}

extension InstancesStore {
    
    public func listInstances() async throws(MastodonError) {
        let response = try await InstancesListRequest(networkService: .default()).response()
        instances = response.instances.sorted { $0.statusesCount > $1.statusesCount }
    }
}

extension InstancesStore {
    
    public func searchInstances(query: String) async throws(MastodonError) {
        instances = try await InstancesSearchRequest(networkService: .default(), query: query).response().instances
    }
}
