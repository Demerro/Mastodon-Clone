//
//  Utils.swift
//  MastodonKit
//
//  Created by Nikita Prokhorchuk on 2.05.25.
//

import Foundation

struct Utils {
    
    static func parseHTMLContentAndSortStatuses(_ statuses: [Status]) async throws(Swift.Error) -> [Status] {
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
