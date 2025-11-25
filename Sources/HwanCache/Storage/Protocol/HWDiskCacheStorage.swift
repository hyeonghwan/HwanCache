//
//  HWDiskCacheStorage.swift
//  HwanCache
//
//  Created by hwan on 11/25/25.
//

import Foundation

public protocol HWDiskCacheStorage: Sendable {
    
    /// Store data to disk cache
    /// - Parameters:
    ///   - data: Data to store
    ///   - key: Unique key for the data
    /// - Throws: HWImageServiceError if storage fails
    func store(_ data: Data, forKey key: String) async throws

    /// Retrieve data from disk cache
    /// - Parameter key: Unique key for the data
    /// - Returns: Cached data if exists, nil otherwise
    /// - Throws: HWImageServiceError if retrieval fails
    func retrieve(forKey key: String) async throws -> Data?

    /// Remove data from disk cache
    /// - Parameter key: Unique key for the data
    /// - Throws: HWImageServiceError if removal fails
    func remove(forKey key: String) async throws

    /// Remove all data from disk cache
    /// - Throws: HWImageServiceError if removal fails
    func removeAll() async throws
    
    
    /// Get content cache size from Disk
    /// - Returns: cache size
    func cacheSize() async -> Int64
}
