//
//  ImageDownloader.swift
//  Network
//
//  Created by Nikita Prokhorchuk on 7.12.24.
//

import UIKit

@MainActor
public final class ImageDownloader {

    private(set) public var cache = [URL: CacheEntry]()
    
    public init() {
    }
}

extension ImageDownloader {
    
    @discardableResult
    public func loadImage(from url: URL) async throws -> UIImage? {
        if let cached = cache[url] {
            return switch cached {
            case .ready(let image):
                image
            case .inProgress(let task):
                try await task.value
            }
        }

        let task = Task {
            try await UIImage(data: NetworkService.imageDownload.data(for: URLRequest(url: url)))
        }
        
        cache[url] = .inProgress(task)

        do {
            let image = try await task.value
            cache[url] = .ready(image)
            return image
        } catch {
            cache[url] = nil
            throw error
        }
    }
}

extension ImageDownloader {
    
    public func clearCache() {
        cache.removeAll()
    }
}

extension ImageDownloader {
    
    public enum CacheEntry: Sendable {
        
        case inProgress(Task<UIImage?, Error>)
        
        case ready(UIImage?)
    }
}
