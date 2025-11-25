//
//  HWImageServiceError.swift
//  HwanCache
//
//  Created by hwan on 11/25/25.
//

import Foundation

/// Error types that can occur during HwanCache image processing
public enum HWImageServiceError: Error {
    /// The URL is invalid or nil
    case invalidURL

    /// Unable to extract URL from URLRequest
    case invalidURLRequest

    /// Image data is corrupted or not a valid image format
    case invalidImageData

    /// Failed to download image from network
    /// - Parameter error: Underlying network error
    case downloadFailed(Error)

    /// Failed to read image from file system
    /// - Parameter error: File system error
    case fileReadFailed(Error)

    /// Failed to downsample image for thumbnail generation
    case downsampleFailed

    /// Failed to store image in cache
    /// - Parameter error: Cache storage error
    case cacheStoreFailed(Error)

    /// Failed to retrieve image from cache
    /// - Parameter error: Cache retrieval error
    case cacheRetrieveFailed(Error)

    /// Item cost exceeds cache total cost limit
    case costExceedsLimit(itemCost: Int, cacheLimit: Int)

    /// Insufficient cache space even after eviction
    case insufficientCacheSpace
}

extension HWImageServiceError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL."
        case .invalidURLRequest:
            return "Unable to extract URL from URLRequest."
        case .invalidImageData:
            return "Invalid image data."
        case .downloadFailed(let error):
            return "Image download failed: \(error.localizedDescription)"
        case .fileReadFailed(let error):
            return "File read failed: \(error.localizedDescription)"
        case .downsampleFailed:
            return "Image downsampling (thumbnail generation) failed."
        case .cacheStoreFailed(let error):
            return "Cache storage failed: \(error.localizedDescription)"
        case .cacheRetrieveFailed(let error):
            return "Cache retrieval failed: \(error.localizedDescription)"
        case .costExceedsLimit(let itemCost, let cacheLimit):
            return "Item cost (\(itemCost) bytes) exceeds cache limit (\(cacheLimit) bytes)."
        case .insufficientCacheSpace:
            return "Insufficient cache space even after eviction."
        }
    }
}
