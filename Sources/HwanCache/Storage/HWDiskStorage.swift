//
//  HWDiskStorage.swift
//  HwanCache
//
//  Created by hwan on 11/25/25.
//

import Foundation

final class HWDiskStorage: HWDiskCacheStorage, @unchecked Sendable {
    private let fileManager: FileManager
    private let cacheDirectory: URL
    private let policy: HWDiskCachePolicy
    private let queue: DispatchQueue

    init(
        cacheDirectory: URL? = nil,
        fileManager: FileManager = .default,
        policy: HWDiskCachePolicy = HWLRUDiskCachePolicy(),
        queue: DispatchQueue? = nil
    ) {
        self.fileManager = fileManager
        self.policy = policy
        self.queue = queue ?? DispatchQueue(label: "com.hwancache.disk", qos: .utility)

        if let cacheDirectory {
            self.cacheDirectory = cacheDirectory
        } else {
            let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
            self.cacheDirectory = paths[0].appendingPathComponent("HwanCache", isDirectory: true)
        }

        if !fileManager.fileExists(atPath: self.cacheDirectory.path) {
            try? fileManager.createDirectory(at: self.cacheDirectory, withIntermediateDirectories: true)
        }
    }

    private func fileURL(forKey key: String) -> URL {
        cacheDirectory.appendingPathComponent(key, isDirectory: false)
    }

    private func metadataFileURL(forKey key: String) -> URL {
        cacheDirectory.appendingPathComponent(key + ".meta", isDirectory: false)
    }

    func store(_ data: Data, forKey key: String) async throws {
        try await store(data, forKey: key, expiration: nil)
    }

    func store(_ data: Data, forKey key: String, expiration: TimeInterval?) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: HWImageServiceError.invalidImageData)
                    return
                }
                do {
                    let fileURL = self.fileURL(forKey: key)
                    try data.write(to: fileURL, options: .atomic)

                    // Store metadata
                    let metadata = DiskCacheMetadata(expiration: expiration)
                    try self.storeMetadataSync(metadata, forKey: key)

                    try self.cleanupIfNeeded()
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: HWImageServiceError.cacheStoreFailed(error))
                }
            }
        }
    }

    func retrieve(forKey key: String) async throws -> Data? {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Data?, Error>) in
            queue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: HWImageServiceError.invalidImageData)
                    return
                }
                do {
                    let fileURL = self.fileURL(forKey: key)
                    guard self.fileManager.fileExists(atPath: fileURL.path) else {
                        continuation.resume(returning: nil)
                        return
                    }

                    // Check expiration
                    if let metadata = try? self.retrieveMetadataSync(forKey: key), metadata.isExpired {
                        // Remove expired cache
                        try? self.fileManager.removeItem(at: fileURL)
                        try? self.fileManager.removeItem(at: self.metadataFileURL(forKey: key))
                        continuation.resume(returning: nil)
                        return
                    }

                    try self.policy.didAccessFile(at: fileURL, fileManager: self.fileManager)
                    let data = try Data(contentsOf: fileURL)
                    continuation.resume(returning: data)
                } catch {
                    continuation.resume(throwing: HWImageServiceError.cacheRetrieveFailed(error))
                }
            }
        }
    }

    func remove(forKey key: String) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: HWImageServiceError.invalidImageData)
                    return
                }
                let fileURL = self.fileURL(forKey: key)
                let metadataURL = self.metadataFileURL(forKey: key)

                try? self.fileManager.removeItem(at: fileURL)
                try? self.fileManager.removeItem(at: metadataURL)

                continuation.resume()
            }
        }
    }

    func removeAll() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            queue.async { [weak self] in
                guard let self else {
                    continuation.resume(throwing: HWImageServiceError.invalidImageData)
                    return
                }
                do {
                    let contents = try self.fileManager.contentsOfDirectory(
                        at: self.cacheDirectory,
                        includingPropertiesForKeys: nil
                    )
                    for url in contents {
                        try self.fileManager.removeItem(at: url)
                    }
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: HWImageServiceError.cacheStoreFailed(error))
                }
            }
        }
    }

    func cacheSize() async -> Int64 {
        await withCheckedContinuation { (continuation: CheckedContinuation<Int64, Never>) in
            queue.async { [weak self] in
                guard let self else {
                    continuation.resume(returning: 0)
                    return
                }
                let size = self.cacheSizeSync()
                continuation.resume(returning: size)
            }
        }
    }

    private func cacheSizeSync() -> Int64 {
        guard let contents = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else { return 0 }

        return contents.reduce(0) { sum, url in
            let fileSize = (try? url.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return sum + Int64(fileSize)
        }
    }

    private func cleanupIfNeeded() throws {
        let currentSize = cacheSizeSync()

        guard policy.shouldCleanup(currentSize: currentSize) else { return }

        let files = try getAllFiles()
        let filesToRemove = try policy.filesToRemove(from: files, currentSize: currentSize, fileManager: fileManager)

        for file in filesToRemove {
            try fileManager.removeItem(at: file)
        }
    }

    private func getAllFiles() throws -> [URL] {
        try fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.fileSizeKey, .contentModificationDateKey, .creationDateKey],
            options: .skipsHiddenFiles
        )
    }

    private func storeMetadataSync(_ metadata: DiskCacheMetadata, forKey key: String) throws {
        let metadataURL = metadataFileURL(forKey: key)
        let encoder = JSONEncoder()
        let data = try encoder.encode(metadata)
        try data.write(to: metadataURL, options: .atomic)
    }

    private func retrieveMetadataSync(forKey key: String) throws -> DiskCacheMetadata? {
        let metadataURL = metadataFileURL(forKey: key)
        guard fileManager.fileExists(atPath: metadataURL.path) else {
            return nil
        }
        let data = try Data(contentsOf: metadataURL)
        let decoder = JSONDecoder()
        return try decoder.decode(DiskCacheMetadata.self, from: data)
    }
}

