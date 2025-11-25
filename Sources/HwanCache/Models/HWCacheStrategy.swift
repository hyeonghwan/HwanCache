//
//  HWCacheStrategy.swift
//  HwanCache
//
//  Created by hwan on 11/25/25.
//

import Foundation

public enum HWCacheStrategy: Sendable {
    case memoryOnly
    case diskOnly(expiration: TimeInterval? = nil)
    case both(diskExpiration: TimeInterval? = nil)
    case none

    public var diskExpiration: TimeInterval? {
        switch self {
        case .diskOnly(let expiration):
            return expiration
        case .both(let diskExpiration):
            return diskExpiration
        case .memoryOnly, .none:
            return nil
        }
    }

    public var storageType: StorageType {
        switch self {
        case .memoryOnly: return .memoryOnly
        case .diskOnly: return .diskOnly
        case .both: return .both
        case .none: return .none
        }
    }

    public enum StorageType {
        case memoryOnly, diskOnly, both, none
    }
}
