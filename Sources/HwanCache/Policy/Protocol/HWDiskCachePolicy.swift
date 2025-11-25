//
//  File.swift
//  HwanCache
//
//  Created by hwan on 11/25/25.
//

import Foundation

public protocol HWDiskCachePolicy {
    var maxCacheSize: Int64 { get }
    func shouldCleanup(currentSize: Int64) -> Bool
    func filesToRemove(from files: [URL], currentSize: Int64, fileManager: FileManager) throws -> [URL]
    func didAccessFile(at url: URL, fileManager: FileManager) throws
}
