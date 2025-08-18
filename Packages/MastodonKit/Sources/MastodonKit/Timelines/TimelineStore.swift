//
//  TimelineStore.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 16.04.25.
//

import Foundation

public final actor TimelineStore {
    
    @MainActor
    private(set) public var statuses = [Status]()
    
    private var publicTimelineMaxId: String?
    
    private var homeTimelineMaxId: String?
    
    private(set) public var publicTimelineAllStatusesDisplayed = false
    
    private(set) public var homeTimelineAllStatusesDisplayed = false
    
    private var showingHomeTimeline = false
    
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
        let request = PublicTimelineRequest(networkService: .default(), instanceHost: instanceName, accessToken: accessToken, maxId: publicTimelineMaxId)
        return try await Utils.parseHTMLContentAndSortStatuses(try await request.response())
    }
    
    private func loadHomeTimeline() async throws(Swift.Error) -> [Status] {
        guard let instanceName = await AuthorizationService.shared.instanceName,
              let accessToken = try? await AuthorizationService.shared.getAccessToken(for: instanceName)
        else {
            assertionFailure()
            throw MastodonError.unknown(nil)
        }
        let request = HomeTimelineRequest(networkService: .default(), instanceHost: instanceName, accessToken: accessToken, maxId: homeTimelineMaxId)
        return try await Utils.parseHTMLContentAndSortStatuses(try await request.response())
    }
}

extension TimelineStore {
    
    public func refreshHomeTimeline() async throws(Swift.Error) {
        homeTimelineAllStatusesDisplayed = false
        homeTimelineMaxId = nil
        let homeTimeline = try await loadHomeTimeline()
        homeTimelineMaxId = homeTimeline.last?.id
        showingHomeTimeline = true
        await MainActor.run {
            statuses = homeTimeline
        }
    }
    
    public func appendHomeTimeline() async throws(Swift.Error) {
        guard !homeTimelineAllStatusesDisplayed else { return }
        let homeTimeline = try await loadHomeTimeline()
        if let maxId = homeTimeline.last?.id {
            homeTimelineMaxId = maxId
            await MainActor.run {
                statuses += homeTimeline
            }
        } else {
            homeTimelineAllStatusesDisplayed = true
        }
    }
}

extension TimelineStore {
    
    public func refreshPublicTimeline() async throws(Swift.Error) {
        publicTimelineAllStatusesDisplayed = false
        publicTimelineMaxId = nil
        let publicTimeline = try await loadPublicTimeline()
        publicTimelineMaxId = publicTimeline.last?.id
        showingHomeTimeline = false
        await MainActor.run {
            statuses = publicTimeline
        }
    }
    
    public func appendPublicTimeline() async throws(Swift.Error) {
        guard !publicTimelineAllStatusesDisplayed else { return }
        let publicTimeline = try await loadPublicTimeline()
        if let maxId = publicTimeline.last?.id {
            publicTimelineMaxId = maxId
            await MainActor.run {
                statuses += publicTimeline
            }
        } else {
            publicTimelineAllStatusesDisplayed = true
        }
    }
}

extension TimelineStore {
    
    public func appendStatusToHomeTimeline(_ status: Status) {
        guard showingHomeTimeline else { return }
        let parsedStatus = try? Utils.parseHTMLContent(in: status)
        Task { @MainActor in
            statuses.insert(parsedStatus ?? status, at: 0)
        }
    }
}
