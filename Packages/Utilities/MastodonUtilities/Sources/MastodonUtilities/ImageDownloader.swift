//
//  ImageDownloader.swift
//  MastodonUtilities
//
//  Created by Nikita Prokhorchuk on 7.12.24.
//

import UIKit
import os.log
import NetworkFoundation
import MastodonCoreUI
import osUtilities

@MainActor
public final class ImageDownloader {

    private let cache = NSCache<NSURL, CacheEntryWrapper>()
    
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
    
    private func loadImageData(from url: URL) async throws -> Data {
        let nsURL = url as NSURL
        
        Logger.imageDownloader.debug("Attempting to load image data for URL: \(url.absoluteString)")
        
        if let cacheEntryWrapper = cache.object(forKey: nsURL) {
            Logger.imageDownloader.debug("Cache hit for URL: \(url.absoluteString)")
            
            switch cacheEntryWrapper.entry {
            case .ready(let data):
                Logger.imageDownloader.info("Cache entry is ready for URL: \(url.absoluteString)")
                return data
            case .inProgress(let task):
                Logger.imageDownloader.info("Cache entry is in-progress for URL: \(url.absoluteString), awaiting task result")
                return try await task.value
            }
        }
        
        Logger.imageDownloader.debug("Cache miss for URL: \(url.absoluteString), starting download task")
        
        let task = Task {
            Logger.imageDownloader.debug("Started download task for URL: \(url.absoluteString)")
            return try await NetworkService.imageDownload.data(for: URLRequest(url: url))
        }
        
        cache.setObject(CacheEntryWrapper(entry: .inProgress(task)), forKey: nsURL)
        
        do {
            let data = try await task.value
            Logger.imageDownloader.info("Successfully downloaded data for URL: \(url.absoluteString), caching the result")
            cache.setObject(CacheEntryWrapper(entry: .ready(data)), forKey: nsURL)
            return data
        } catch {
            Logger.imageDownloader.error("Failed to download data for URL: \(url.absoluteString). Error: \(error)")
            cache.removeObject(forKey: nsURL)
            throw error
        }
    }
}

extension ImageDownloader {
    
    public func cancelDownloadingIfNeeded(for url: URL) {
        if case let .inProgress(task) = cache.object(forKey: url as NSURL)?.entry {
            task.cancel()
            Logger.imageDownloader.info("Cancel downloading for URL: \(url.absoluteString)")
        }
    }
}

extension ImageDownloader {
    
    fileprivate enum CacheEntry: Sendable {
        
        case inProgress(Task<Data, Error>)
        
        case ready(Data)
    }
    
    fileprivate final class CacheEntryWrapper {
        
        let entry: CacheEntry
        
        init(entry: CacheEntry) {
            self.entry = entry
        }
    }
}

extension Logger {
    
    fileprivate static let imageDownloader = Logger(subsystem: "com.demerro.MastodonUtilities", category: "ImageDownloader", flag: "Debug")
}
