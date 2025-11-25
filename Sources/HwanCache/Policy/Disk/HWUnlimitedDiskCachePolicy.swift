//
//  File.swift
//  HwanCache
//
//  Created by hwan on 11/25/25.
//

import Foundation

public struct HWUnlimitedDiskCachePolicy: HWDiskCachePolicy {
    public let maxCacheSize: Int64 = Int64.max

    public init() {}

    public func shouldCleanup(currentSize: Int64) -> Bool {
        false
    }

    public func filesToRemove(from files: [URL], currentSize: Int64, fileManager: FileManager) throws -> [URL] {
        []
    }

    public func didAccessFile(at url: URL, fileManager: FileManager) throws {
    }
}
