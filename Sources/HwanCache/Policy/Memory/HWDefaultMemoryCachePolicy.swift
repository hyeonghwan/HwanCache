//
//  HWDefaultMemoryCachePolicy.swift
//  HwanCache
//
//  Created by hwan on 11/25/25.
//

import Foundation

/// Default LRU (Least Recently Used) memory cache policy
public struct HWDefaultMemoryCachePolicy: HWMemoryCachePolicy {
    public let countLimit: Int
    public let totalCostLimit: Int

    public init(countLimit: Int = 200, totalCostLimit: Int = 200 * 1024 * 1024) {
        self.countLimit = countLimit
        self.totalCostLimit = totalCostLimit
    }

    public func keysToEvict(from entries: [CacheEntry], newEntryCost: Int) -> [String] {
        // Check if new entry exceeds total cost limit
        guard newEntryCost <= totalCostLimit else {
            return [] // Cannot store this entry
        }

        var currentCost = entries.reduce(0) { $0 + $1.cost }
        var currentCount = entries.count

        // Sort by lastAccessTime (oldest first for LRU)
        let sortedEntries = entries.sorted { $0.lastAccessTime < $1.lastAccessTime }

        var keysToRemove: [String] = []

        for entry in sortedEntries {
            // Check if we need to evict based on cost or count
            let needsEvictionForCost = (currentCost + newEntryCost) > totalCostLimit
            let needsEvictionForCount = (currentCount + 1) > countLimit

            guard needsEvictionForCost || needsEvictionForCount else {
                break
            }

            keysToRemove.append(entry.key)
            currentCost -= entry.cost
            currentCount -= 1
        }

        return keysToRemove
    }

    public func didAccess(entry: CacheEntry) -> CacheEntry {
        var updated = entry
        updated.lastAccessTime = Date()
        updated.accessCount += 1
        return updated
    }
}
