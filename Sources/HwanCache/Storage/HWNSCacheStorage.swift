//
//  HWNSCacheStorage.swift
//  HwanCache
//
//  Created by hwan on 11/25/25.
//

import Foundation

/// NSCache-based memory storage implementation
/// Note: NSCache uses its own eviction policy and cannot be customized
final class HWNSCacheStorage: HWMemoryCacheStorage, @unchecked Sendable {
    private let cache = NSCache<NSString, PlatformImage>()
    private let totalCostLimit: Int

    /// Initialize NSCache storage with limits
    /// - Parameters:
    ///   - countLimit: Maximum number of objects (default: 500)
    ///   - totalCostLimit: Maximum total cost in bytes (default: 500MB)
    init(countLimit: Int = 500, totalCostLimit: Int = 500 * 1024 * 1024) {
        self.totalCostLimit = totalCostLimit
        cache.countLimit = countLimit
        cache.totalCostLimit = totalCostLimit
    }

    func store(_ image: PlatformImage, forKey key: String) throws {
        let cost = calculateImageCost(image)

        // Check if single item exceeds limit
        guard cost <= totalCostLimit else {
            throw HWImageServiceError.costExceedsLimit(itemCost: cost, cacheLimit: totalCostLimit)
        }

        // NSCache handles eviction automatically
        cache.setObject(image, forKey: key as NSString, cost: cost)
    }

    func retrieve(forKey key: String) -> PlatformImage? {
        return cache.object(forKey: key as NSString)
    }

    func remove(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }

    func removeAll() {
        cache.removeAllObjects()
    }

    private func calculateImageCost(_ image: PlatformImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        let bytesPerPixel = 4
        let cost = cgImage.width * cgImage.height * bytesPerPixel
        return cost
    }
}
