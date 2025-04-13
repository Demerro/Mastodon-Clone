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
    
    public func listInstances() async throws(InstancesError) {
        let response = try await InstancesListRequest(networkService: .api).response()
        instances = response.instances.sorted { $0.statusesCount > $1.statusesCount }
    }
}

extension InstancesStore {
    
    public func searchInstances(query: String) async throws(InstancesError) {
        instances = try await InstancesSearchRequest(networkService: .api, query: query).response().instances
    }
}
