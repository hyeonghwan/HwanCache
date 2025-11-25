//
//  DownSampleHelper.swift
//  HwanCache
//
//  Created by hwan on 11/25/25.
//

import Foundation
import CoreGraphics
import ImageIO

enum DownSampleHelper {
    static func downsampleImage(data: Data, to pointSize: CGSize, scale: CGFloat = PlatformScreen.main?.scale ?? 1.0) -> PlatformImage? {
        let imageSourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
        guard let imageSource = CGImageSourceCreateWithData(data as CFData, imageSourceOptions) else {
            return nil
        }
        let maxDimensionInPixels = max(pointSize.width, pointSize.height) * scale
        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxDimensionInPixels
        ]
        guard let downsampledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, downsampleOptions as CFDictionary) else {
            return nil
        }
        return PlatformImage(cgImage: downsampledImage, scale: scale, orientation: .up)
    }
}
