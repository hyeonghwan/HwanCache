//
//  HWImageDisplayMode.swift
//  HwanCache
//
//  Created by hwan on 11/25/25.
//

import Foundation
import CoreGraphics

public enum HWImageDisplayMode {
    case thumbnail(CGSize)
    case original
}

extension HWImageDisplayMode: Hashable {
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .thumbnail(let size):
            hasher.combine("thumbnail")
            hasher.combine(size.width)
            hasher.combine(size.height)
        case .original:
            hasher.combine("original")
        }
    }

    public static func == (lhs: HWImageDisplayMode, rhs: HWImageDisplayMode) -> Bool {
        switch (lhs, rhs) {
        case (.thumbnail(let lSize), .thumbnail(let rSize)):
            return lSize == rSize
        case (.original, .original):
            return true
        default:
            return false
        }
    }
}
