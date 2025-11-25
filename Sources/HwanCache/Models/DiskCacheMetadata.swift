//
//  DiskCacheMetadata.swift
//  HwanCache
//
//  Created by hwan on 11/25/25.
//

import Foundation

/// Metadata for disk cached items including TTL expiration
struct DiskCacheMetadata: Codable {
    let createdAt: Date
    let expiration: TimeInterval?

    var isExpired: Bool {
        guard let expiration = expiration else { return false }
        return Date().timeIntervalSince(createdAt) > expiration
    }

    init(createdAt: Date = Date(), expiration: TimeInterval? = nil) {
        self.createdAt = createdAt
        self.expiration = expiration
    }
}
