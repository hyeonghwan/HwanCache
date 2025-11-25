//
//  File.swift
//  HwanCache
//
//  Created by hwan on 11/25/25.
//

import Foundation

public enum HWMemoryStorageType {
    case custom(policy: HWMemoryCachePolicy)
    case nsCache
}
