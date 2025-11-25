//
//  HWCacheManager.swift
//  HwanCache
//
//  Created by hwan on 11/25/25.
//

import Foundation

public final class HWCacheManager: @unchecked Sendable {
    public static let shared = HWCacheManager()

    private let memoryCache: HWMemoryCacheStorage
    private let diskCache: HWDiskCacheStorage

    /// Primary initializer with protocol-based dependency injection
    /// - Parameters:
    ///   - memoryStorage: Memory cache storage implementation
    ///   - diskStorage: Disk cache storage implementation
    public init(
        memoryStorage: HWMemoryCacheStorage,
        diskStorage: HWDiskCacheStorage
    ) {
        self.memoryCache = memoryStorage
        self.diskCache = diskStorage
    }

    /// Convenience initializer using either custom memory policy or NSCache
    /// - Parameters:
    ///   - cacheDirectory: Optional custom disk cache directory (default: system cache)
    ///   - fileManager: FileManager to use for disk operations
    ///   - memoryStorageType: Defines whether to use HWMemoryStorage (custom policy) or NSCache
    ///   - diskPolicy: Disk eviction policy (default: LRU)
    ///   - diskQueue: Custom DispatchQueue for disk I/O (default: internal utility queue)
    ///
    /// This initializer lets you easily swap between:
    /// - **HWMemoryStorage** for custom LRU-like memory rules
    /// - **HWNSCacheStorage** for Apple's optimized NSCache behavior
    ///
    /// Disk cache always stores **only original image data**, never thumbnails.
    public convenience init(
        cacheDirectory: URL? = nil,
        fileManager: FileManager = .default,
        memoryStorageType: HWMemoryStorageType = .nsCache,
        diskPolicy: HWDiskCachePolicy = HWLRUDiskCachePolicy(),
        diskQueue: DispatchQueue? = nil
    ) {
        let memoryStorage: HWMemoryCacheStorage

        switch memoryStorageType {
        case .custom(let policy):
            memoryStorage = HWMemoryStorage(policy: policy)
        case .nsCache:
            memoryStorage = HWNSCacheStorage()
        }

        let diskStorage = HWDiskStorage(
            cacheDirectory: cacheDirectory,
            fileManager: fileManager,
            policy: diskPolicy,
            queue: diskQueue
        )

        self.init(memoryStorage: memoryStorage, diskStorage: diskStorage)
    }

    public func storeToMemory(_ image: PlatformImage, forKey key: String) throws {
        try memoryCache.store(image, forKey: key)
    }

    public func retrieveFromMemory(forKey key: String) -> PlatformImage? {
        return memoryCache.retrieve(forKey: key)
    }

    public func removeFromMemory(forKey key: String) {
        memoryCache.remove(forKey: key)
    }

    public func storeToDisk(_ data: Data, forKey key: String) async throws {
        try await storeToDisk(data, forKey: key, expiration: nil)
    }

    public func storeToDisk(_ data: Data, forKey key: String, expiration: TimeInterval?) async throws {
        guard let diskStorage = diskCache as? HWDiskStorage else {
            try await diskCache.store(data, forKey: key)
            return
        }
        try await diskStorage.store(data, forKey: key, expiration: expiration)
    }

    public func retrieveFromDisk(forKey key: String) async throws -> Data? {
        try await diskCache.retrieve(forKey: key)
    }

    public func removeFromDisk(forKey key: String) async throws {
        try await diskCache.remove(forKey: key)
    }

    public func store(image: PlatformImage, data: Data, forKey cacheKey: HWCacheKey, strategy: HWCacheStrategy) async throws {
        switch strategy.storageType {
        case .memoryOnly:
            try storeToMemory(image, forKey: cacheKey.memoryCacheKey)

        case .diskOnly:
            try await storeToDisk(data, forKey: cacheKey.diskCacheKey, expiration: strategy.diskExpiration)

        case .both:
            try storeToMemory(image, forKey: cacheKey.memoryCacheKey)
            try await storeToDisk(data, forKey: cacheKey.diskCacheKey, expiration: strategy.diskExpiration)

        case .none:
            break
        }
    }

    public func remove(forKey cacheKey: HWCacheKey, strategy: HWCacheStrategy) async {
        switch strategy.storageType {
        case .memoryOnly:
            removeFromMemory(forKey: cacheKey.memoryCacheKey)

        case .diskOnly:
            try? await removeFromDisk(forKey: cacheKey.diskCacheKey)

        case .both:
            removeFromMemory(forKey: cacheKey.memoryCacheKey)
            try? await removeFromDisk(forKey: cacheKey.diskCacheKey)

        case .none:
            break
        }
    }

    public func retrieve(forKey cacheKey: HWCacheKey, displayMode: HWImageDisplayMode, strategy: HWCacheStrategy) async throws -> PlatformImage? {
        guard strategy.storageType != .none else { return nil }

        if strategy.storageType == .memoryOnly || strategy.storageType == .both {
            if let cachedImage = retrieveFromMemory(forKey: cacheKey.memoryCacheKey) {
                return cachedImage
            }
        }

        if strategy.storageType == .diskOnly || strategy.storageType == .both {
            if let data = try await retrieveFromDisk(forKey: cacheKey.diskCacheKey) {
                return try createImage(from: data, displayMode: displayMode)
            }
        }

        return nil
    }

    public func clearMemoryCache() {
        memoryCache.removeAll()
    }

    public func clearDiskCache() async {
        try? await diskCache.removeAll()
    }

    public func clearAllCache() async {
        clearMemoryCache()
        await clearDiskCache()
    }

    public func diskCacheSize() async -> Int64 {
        await diskCache.cacheSize()
    }

    private func createImage(from data: Data, displayMode: HWImageDisplayMode) throws -> PlatformImage {
        switch displayMode {
        case .thumbnail(let size):
            guard let image = DownSampleHelper.downsampleImage(data: data, to: size) else {
                throw HWImageServiceError.downsampleFailed
            }
            return image
        case .original:
            guard let image = PlatformImage(data: data) else {
                throw HWImageServiceError.invalidImageData
            }
            return image
        }
    }
}
