//
//  TimelineStore.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 16.04.25.
//

import Foundation

public final actor TimelineStore {
    
    private(set) public var statuses = [Status]()
    
    private var publicTimelineMaxId: String?
    
    private var homeTimelineMaxId: String?
    
    public init() {
    }
}

extension TimelineStore {
    
    private func loadPublicTimeline() async throws(Swift.Error) -> [Status] {
        guard let instanceName = await AuthorizationService.shared.instanceName,
              let accessToken = try? await AuthorizationService.shared.getAccessToken(for: instanceName)
        else {
            assertionFailure()
            throw MastodonError.unknown(nil)
        }
        let request = PublicTimelineRequest(networkService: .api, instanceHost: instanceName, accessToken: accessToken, maxId: publicTimelineMaxId)
        return try await parseHTMLContentAndSortStatuses(try await request.response())
    }
    
    private func loadHomeTimeline() async throws(Swift.Error) -> [Status] {
        guard let instanceName = await AuthorizationService.shared.instanceName,
              let accessToken = try? await AuthorizationService.shared.getAccessToken(for: instanceName)
        else {
            assertionFailure()
            throw MastodonError.unknown(nil)
        }
        let request = HomeTimelineRequest(networkService: .api, instanceHost: instanceName, accessToken: accessToken, maxId: homeTimelineMaxId)
        return try await parseHTMLContentAndSortStatuses(try await request.response())
    }
}

extension TimelineStore {
    
    public func refreshHomeTimeline() async throws(Swift.Error) {
        homeTimelineMaxId = nil
        let homeTimeline = try await loadHomeTimeline()
        homeTimelineMaxId = homeTimeline.last?.id
        statuses = homeTimeline
    }
    
    public func appendHomeTimeline() async throws(Swift.Error) {
        let homeTimeline = try await loadHomeTimeline()
        if let maxId = homeTimeline.last?.id {
            homeTimelineMaxId = maxId
        }
        statuses += homeTimeline
    }
}

extension TimelineStore {
    
    public func refreshPublicTimeline() async throws(Swift.Error) {
        publicTimelineMaxId = nil
        let publicTimeline = try await loadPublicTimeline()
        publicTimelineMaxId = publicTimeline.last?.id
        statuses = publicTimeline
    }
    
    public func appendPublicTimeline() async throws(Swift.Error) {
        let publicTimeline = try await loadPublicTimeline()
        if let maxId = publicTimeline.last?.id {
            publicTimelineMaxId = maxId
        }
        statuses += publicTimeline
    }
}

extension TimelineStore {
    
    private func parseHTMLContentAndSortStatuses(_ statuses: [Status]) async throws(Swift.Error) -> [Status] {
        try await withThrowingTaskGroup(of: Status.self) { taskGroup in
            for var status in statuses {
                taskGroup.addTask {
                    guard !status.content.isEmpty else { return status }
                    var content = try NSAttributedString(data: status.content.data(using: .utf8)!, options: [
                        .documentType: NSAttributedString.DocumentType.html,
                        .characterEncoding: String.Encoding.utf8.rawValue,
                    ], documentAttributes: nil).string
                    content.removeLast()
                    status.content = content
                    return status
                }
            }
            return try await taskGroup
                .reduce(into: [Status]()) { $0.append($1) }
                .sorted { $0.id > $1.id }
        }
    }
}
