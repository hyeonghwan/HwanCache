//
//  File.swift
//  HwanCache
//
//  Created by hwan on 11/25/25.
//

import Foundation

public struct HWSizeBasedDiskCachePolicy: HWDiskCachePolicy {
    public let maxCacheSize: Int64

    public init(maxCacheSize: Int64 = 100 * 1024 * 1024) {
        self.maxCacheSize = maxCacheSize
    }

    public func shouldCleanup(currentSize: Int64) -> Bool {
        currentSize > maxCacheSize
    }

    public func filesToRemove(from files: [URL], currentSize: Int64, fileManager: FileManager) throws -> [URL] {
        let sorted = files.sorted { url1, url2 in
            let size1 = (try? url1.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            let size2 = (try? url2.resourceValues(forKeys: [.fileSizeKey]))?.fileSize ?? 0
            return size1 > size2
        }

        var toRemove: [URL] = []
        var sizeToRemove = currentSize - maxCacheSize

        for file in sorted {
            guard sizeToRemove > 0 else { break }

            let fileSize = try fileManager.attributesOfItem(atPath: file.path)[.size] as? Int64 ?? 0
            toRemove.append(file)
            sizeToRemove -= fileSize
        }

        return toRemove
    }

    public func didAccessFile(at url: URL, fileManager: FileManager) throws {
    }
}
