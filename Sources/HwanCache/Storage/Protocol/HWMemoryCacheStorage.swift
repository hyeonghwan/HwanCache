//
//  HWMemoryCacheStorage.swift
//  HwanCache
//
//  Created by hwan on 11/25/25.
//

import Foundation

/// Protocol for memory-based image caching
public protocol HWMemoryCacheStorage: Sendable {
    /// Store an image in memory cache
    /// - Parameters:
    ///   - image: Image to store
    ///   - key: Unique key for the image
    /// - Throws: HWImageServiceError if storage fails
    func store(_ image: PlatformImage, forKey key: String) throws

    /// Retrieve an image from memory cache
    /// - Parameter key: Unique key for the image
    /// - Returns: Cached image if exists, nil otherwise
    func retrieve(forKey key: String) -> PlatformImage?

    /// Remove an image from memory cache
    /// - Parameter key: Unique key for the image
    func remove(forKey key: String)

    /// Remove all images from memory cache
    func removeAll()
}
