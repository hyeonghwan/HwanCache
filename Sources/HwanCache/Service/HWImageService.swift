//
//  HWImageService.swift
//  HwanCache
//
//  Created by hwan on 11/25/25.
//

import Foundation

public protocol HWImageService: Sendable {

    /// LoadImage from specific URL
    /// - Parameters:
    ///   - url: source URL, file or network
    ///   - displayMode: origin or thumbnail with size
    ///   - cacheStrategy: caching strategy
    /// - Returns: UIImage or NSImage
    func loadImage(from url: URL, displayMode: HWImageDisplayMode, cacheStrategy: HWCacheStrategy) async throws -> PlatformImage

    func loadImage(from urlRequest: URLRequest, displayMode: HWImageDisplayMode, cacheStrategy: HWCacheStrategy) async throws -> PlatformImage

    /// Store image data directly to cache
    /// - Parameters:
    ///   - imageData: Image data to store
    ///   - key: Cache key (usually URL string)
    ///   - displayMode: origin or thumbnail with size
    ///   - cacheStrategy: caching strategy (includes expiration)
    /// - Returns: UIImage or NSImage
    func store(imageData: Data, forKey key: String, displayMode: HWImageDisplayMode, cacheStrategy: HWCacheStrategy) async throws -> PlatformImage

    /// Remove image from cache
    /// - Parameters:
    ///   - url: Image URL
    ///   - displayMode: origin or thumbnail with size
    ///   - cacheStrategy: caching strategy
    func removeFromCache(url: String, displayMode: HWImageDisplayMode, cacheStrategy: HWCacheStrategy) async
}

public extension HWImageService {
    func loadImage(from url: URL, displayMode: HWImageDisplayMode, cacheStrategy: HWCacheStrategy = .both()) async throws -> PlatformImage {
        try await self.loadImage(from: url, displayMode: displayMode, cacheStrategy: cacheStrategy)
    }

    func loadImage(from urlRequest: URLRequest, displayMode: HWImageDisplayMode, cacheStrategy: HWCacheStrategy = .both()) async throws -> PlatformImage {
        try await self.loadImage(from: urlRequest, displayMode: displayMode, cacheStrategy: cacheStrategy)
    }

    func store(imageData: Data, forKey key: String, displayMode: HWImageDisplayMode = .original, cacheStrategy: HWCacheStrategy = .both()) async throws -> PlatformImage {
        try await self.store(imageData: imageData, forKey: key, displayMode: displayMode, cacheStrategy: cacheStrategy)
    }

    func removeFromCache(url: String, displayMode: HWImageDisplayMode = .original, cacheStrategy: HWCacheStrategy = .both()) async {
        await self.removeFromCache(url: url, displayMode: displayMode, cacheStrategy: cacheStrategy)
    }
}

public protocol HWImageDownloader: Sendable {
    func downloadImage(from urlString: String) async throws -> Data
    func downloadImage(from urlRequest: URLRequest) async throws -> Data
}
