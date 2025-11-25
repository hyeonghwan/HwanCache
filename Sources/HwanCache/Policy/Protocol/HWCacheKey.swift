//
//  HWCacheKey.swift
//  HwanCache
//
//  Created by hwan on 11/25/25.
//

import Foundation
import CryptoKit

public struct HWCacheKey: Hashable {
    let url: String
    let displayMode: HWImageDisplayMode

    public init(url: String, displayMode: HWImageDisplayMode) {
        self.url = url
        self.displayMode = displayMode
    }

    var diskCacheKey: String {
        guard let data = url.data(using: .utf8) else { return url }
        let hashed = SHA256.hash(data: data)
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    var memoryCacheKey: String {
        switch displayMode {
        case .thumbnail(let size):
            return "\(url)_\(Int(size.width))x\(Int(size.height))"
        case .original:
            return "\(url)_original"
        }
    }
}
