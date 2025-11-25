//
//  HWMemoryCachePolicy.swift
//  HwanCache
//
//  Created by hwan on 11/25/25.
//

import Foundation

public struct CacheEntry {
    public let key: String
    public let cost: Int
    public var lastAccessTime: Date
    public var accessCount: Int
    public let createdTime: Date

    public init(key: String, cost: Int, lastAccessTime: Date = Date(), accessCount: Int = 0, createdTime: Date = Date()) {
        self.key = key
        self.cost = cost
        self.lastAccessTime = lastAccessTime
        self.accessCount = accessCount
        self.createdTime = createdTime
    }
}

public protocol HWMemoryCachePolicy: Sendable {
    var countLimit: Int { get }
    var totalCostLimit: Int { get }

    /// Determine which entries should be evicted
    /// - Parameters:
    ///   - entries: Current cache entries
    ///   - newEntryCost: Cost of the new entry to be added
    /// - Returns: Keys of entries to evict
    func keysToEvict(from entries: [CacheEntry], newEntryCost: Int) -> [String]

    /// Update entry metadata when accessed
    /// - Parameter entry: Entry that was accessed
    /// - Returns: Updated entry
    func didAccess(entry: CacheEntry) -> CacheEntry
}
