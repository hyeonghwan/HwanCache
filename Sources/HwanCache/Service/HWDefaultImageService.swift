//
//  HWDefaultImageService.swift
//  HwanCache
//
//  Created by hwan on 11/25/25.
//

import Foundation

public final class HWDefaultImageService: HWImageService {
    private let downloader: HWImageDownloader
    private let cacheManager: HWCacheManager

    public init(downloader: HWImageDownloader, cacheManager: HWCacheManager = HWCacheManager.shared) {
        self.downloader = downloader
        self.cacheManager = cacheManager
    }

    public func loadImage(from url: URL, displayMode: HWImageDisplayMode, cacheStrategy: HWCacheStrategy = .both()) async throws -> PlatformImage {
        let urlString = url.absoluteString
        guard !urlString.isEmpty else {
            throw HWImageServiceError.invalidURL
        }

        let cacheKey = HWCacheKey(url: urlString, displayMode: displayMode)

        // Retrieve from cache
        if let cachedImage = try? await cacheManager.retrieve(forKey: cacheKey, displayMode: displayMode, strategy: cacheStrategy) {
            return cachedImage
        }

        // Load image data
        let imageData: Data
        if url.isFileURL {
            do {
                imageData = try Data(contentsOf: url)
            } catch {
                throw HWImageServiceError.fileReadFailed(error)
            }
        } else {
            do {
                imageData = try await downloader.downloadImage(from: urlString)
            } catch {
                throw HWImageServiceError.downloadFailed(error)
            }
        }

        // Create image from data
        let image = try createImage(from: imageData, displayMode: displayMode)

        // Store to cache (no expiration for loadImage)
        try? await cacheManager.store(image: image, data: imageData, forKey: cacheKey, strategy: cacheStrategy)

        return image
    }

    public func loadImage(from urlRequest: URLRequest, displayMode: HWImageDisplayMode, cacheStrategy: HWCacheStrategy = .both()) async throws -> PlatformImage {
        guard let url = urlRequest.url else {
            throw HWImageServiceError.invalidURLRequest
        }

        let urlString = url.absoluteString
        guard !urlString.isEmpty else {
            throw HWImageServiceError.invalidURL
        }

        let cacheKey = HWCacheKey(url: urlString, displayMode: displayMode)

        // Retrieve from cache
        if let cachedImage = try? await cacheManager.retrieve(forKey: cacheKey, displayMode: displayMode, strategy: cacheStrategy) {
            return cachedImage
        }

        // Load image data
        let imageData: Data
        if url.isFileURL {
            do {
                imageData = try Data(contentsOf: url)
            } catch {
                throw HWImageServiceError.fileReadFailed(error)
            }
        } else {
            do {
                imageData = try await downloader.downloadImage(from: urlRequest)
            } catch {
                throw HWImageServiceError.downloadFailed(error)
            }
        }

        // Create image from data
        let image = try createImage(from: imageData, displayMode: displayMode)

        // Store to cache (no expiration for loadImage)
        try? await cacheManager.store(image: image, data: imageData, forKey: cacheKey, strategy: cacheStrategy)

        return image
    }

    public func store(imageData: Data, forKey key: String, displayMode: HWImageDisplayMode, cacheStrategy: HWCacheStrategy) async throws -> PlatformImage {
        let cacheKey = HWCacheKey(url: key, displayMode: displayMode)

        // Create image from data
        let image = try createImage(from: imageData, displayMode: displayMode)

        // Store to cache
        try await cacheManager.store(image: image, data: imageData, forKey: cacheKey, strategy: cacheStrategy)

        return image
    }

    public func removeFromCache(url: String, displayMode: HWImageDisplayMode, cacheStrategy: HWCacheStrategy) async {
        let cacheKey = HWCacheKey(url: url, displayMode: displayMode)
        await cacheManager.remove(forKey: cacheKey, strategy: cacheStrategy)
    }

    private func createImage(from data: Data, displayMode: HWImageDisplayMode) throws -> PlatformImage {
        switch displayMode {
        case .thumbnail(let size):
            guard let image = DownSampleHelper.downsampleImage(data: data, to: size) else {
                throw HWImageServiceError.downsampleFailed
            }
            return image
        case .original:
            guard let image = PlatformImage(data: data) else {
                throw HWImageServiceError.invalidImageData
            }
            return image
        }
    }
}
