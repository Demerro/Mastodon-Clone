//
//  PostStatusStore.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 2.06.25.
//

import Foundation

@MainActor
public final class PostStatusStore: NSObject {
    
    private(set) public var mediaAttachments = [UUID: MediaAttachment]()
    
    private var uploadedStatus: Status?
}

extension PostStatusStore {
    
    public func uploadStatus(status: String, spoilerText: String, visibility: Status.Visibility) async throws(MastodonError) {
        guard let (instanceName, token) = authInfo else { return }
        let request = PostStatusRequest(
            networkService: .default(delegate: self),
            instanceHost: instanceName,
            accessToken: token,
            status: status,
            mediaIds: mediaAttachments.values.map { $0.id },
            sensitive: !spoilerText.isEmpty,
            spoilerText: spoilerText,
            visibility: visibility
        )
        mediaAttachments.removeAll()
        uploadedStatus = try await request.response()
    }
    
    public func uploadMedia(data: Data, fileName: String, mimeType: String, storageId id: UUID) async throws(MastodonError) {
        guard let (instanceName, token) = authInfo else { return }
        let request = MediaUploadRequest(
            networkService: .default(),
            instanceHost: instanceName,
            accessToken: token,
            fileData: data,
            fileName: fileName,
            mimeType: mimeType
        )
        mediaAttachments[id] = try await request.response()
    }
}

extension PostStatusStore {
    
    public func removeMediaAttachment(withStorageId id: UUID) async throws(MastodonError) {
        guard let mediaAttachment = mediaAttachments.removeValue(forKey: id),
              let (instanceName, token) = authInfo
        else { return }
        let request = MediaDeleteRequest(
            networkService: .default(),
            instanceHost: instanceName,
            accessToken: token,
            mediaId: mediaAttachment.id
        )
        try await request.response()
    }
}

extension PostStatusStore {
    
    private var authInfo: (String, String)? {
        let authService = AuthorizationService.shared
        guard let instanceName = authService.instanceName,
              let token = try? authService.getAccessToken(for: instanceName)
        else {
            assertionFailure("No instance or access token found")
            return nil
        }
        return (instanceName, token)
    }
}

extension PostStatusStore: URLSessionTaskDelegate {
    
    nonisolated public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
    }
}
