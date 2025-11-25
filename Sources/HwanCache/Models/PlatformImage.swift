//
//  PlatformImage.swift
//  HwanCache
//
//  Created by hwan on 11/25/25.
//

import CoreGraphics

#if canImport(UIKit)
import UIKit
public typealias PlatformImage = UIImage
public typealias PlatformScreen = UIScreen
#elseif canImport(AppKit)
import AppKit
public typealias PlatformImage = NSImage
public typealias PlatformScreen = NSScreen
#endif

#if canImport(AppKit) && !canImport(UIKit)
extension NSImage {
    public convenience init?(cgImage: CGImage, scale: CGFloat, orientation: NSImage.Orientation) {
        let size = CGSize(width: CGFloat(cgImage.width) / scale, height: CGFloat(cgImage.height) / scale)
        self.init(cgImage: cgImage, size: size)
    }

    public var cgImage: CGImage? {
        var rect = CGRect(origin: .zero, size: self.size)
        return self.cgImage(forProposedRect: &rect, context: nil, hints: nil)
    }

    public enum Orientation {
        case up
    }
}

extension NSScreen {
    public var scale: CGFloat {
        return self.backingScaleFactor
    }
}
#endif
