//
//  HWMemoryStorage.swift
//  HwanCache
//
//  Created by hwan on 11/25/25.
//

import Foundation

final class HWMemoryStorage: HWMemoryCacheStorage, @unchecked Sendable {
    private var cache: [String: (image: PlatformImage, metadata: CacheEntry)] = [:]
    private let policy: HWMemoryCachePolicy
    private let queue = DispatchQueue(label: "com.hwancache.memory")

    init(policy: HWMemoryCachePolicy = HWDefaultMemoryCachePolicy()) {
        self.policy = policy
    }

    func store(_ image: PlatformImage, forKey key: String) throws {
        try queue.sync {
            let cost = calculateImageCost(image)

            // Check if single item exceeds limit
            guard cost <= policy.totalCostLimit else {
                throw HWImageServiceError.costExceedsLimit(itemCost: cost, cacheLimit: policy.totalCostLimit)
            }

            // Get current entries for eviction calculation
            let currentEntries = cache.values.map { $0.metadata }

            // Determine what to evict
            let keysToEvict = policy.keysToEvict(from: currentEntries, newEntryCost: cost)

            // Check if we can make space
            let currentCost = currentEntries.reduce(0) { $0 + $1.cost }
            let evictedCost = keysToEvict.compactMap { cache[$0]?.metadata.cost }.reduce(0, +)
            let remainingCost = currentCost - evictedCost

            guard (remainingCost + cost) <= policy.totalCostLimit else {
                throw HWImageServiceError.insufficientCacheSpace
            }

            // Evict old entries
            for key in keysToEvict {
                cache.removeValue(forKey: key)
            }

            // Store new entry
            let metadata = CacheEntry(key: key, cost: cost)
            cache[key] = (image: image, metadata: metadata)
        }
    }

    func retrieve(forKey key: String) -> PlatformImage? {
        return queue.sync {
            guard var entry = cache[key] else {
                return nil
            }

            // Update access metadata
            entry.metadata = policy.didAccess(entry: entry.metadata)
            cache[key] = entry

            return entry.image
        }
    }

    func remove(forKey key: String) {
        queue.async {
            self.cache.removeValue(forKey: key)
        }
    }

    func removeAll() {
        queue.async {
            self.cache.removeAll()
        }
    }

    private func calculateImageCost(_ image: PlatformImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        let bytesPerPixel = 4
        let cost = cgImage.width * cgImage.height * bytesPerPixel
        return cost
    }
}
