//
//  ImageDownloader.swift
//  MastodonUtilities
//
//  Created by Nikita Prokhorchuk on 7.12.24.
//

import UIKit
import NetworkFoundation
import MastodonCoreUI

@MainActor
public final class ImageDownloader {

    private(set) public var cache = [URL: CacheEntry]()
    
    public init() {
    }
}

extension ImageDownloader {
    
    @discardableResult
    public func loadImage(from url: URL) async throws -> UIImage? {
        try await UIImage(data: loadImageData(from: url))
    }
    
    @discardableResult
    public func loadAnimatedImage(from url: URL) async throws -> UIImage? {
        try await UIImage.animatedImage(withGIFData: loadImageData(from: url))
    }
}

extension ImageDownloader {
    
    public func clearCache() {
        cache.removeAll()
    }
}

extension ImageDownloader {
    
    private func loadImageData(from url: URL) async throws -> Data {
        if let cached = cache[url] {
            return switch cached {
            case .ready(let data):
                data
            case .inProgress(let task):
                try await task.value
            }
        }
        
        let task = Task {
            try await NetworkService.imageDownload.data(for: URLRequest(url: url))
        }
        
        cache[url] = .inProgress(task)
        
        do {
            let data = try await task.value
            cache[url] = .ready(data)
            return data
        } catch {
            cache[url] = nil
            throw error
        }
    }
}

extension ImageDownloader {
    
    public enum CacheEntry: Sendable {
        
        case inProgress(Task<Data, Error>)
        
        case ready(Data)
    }
}
