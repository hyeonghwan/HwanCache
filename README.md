# HwanCache

Fast and efficient image caching library for iOS

## Features

- **Memory + Disk Caching**: Automatic multi-level caching
- **Customizable Policies**: Extensible cache eviction strategies
- **Thumbnail Downsampling (Memory-only)**: Thumbnails are generated on the fly and stored only in memory. 
  The disk cache stores only the original image to reduce disk usage and avoid redundant file writes.
- **Swift Concurrency**: Modern async/await API
- **Flexible Strategy**: Memory-only, disk-only, both, or none
- **Disk, Memory Policy**: Disk & Memory Policy: Auto-eviction (LRU), TTL, cost limit

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/HwanCache.git", from: "0.1.0")
]
```

## Usage

### Basic Setup

```swift
import HwanCache

// 1. Implement HWImageDownloader protocol
struct MyImageDownloader: HWImageDownloader {
    func downloadImage(from urlString: String) async throws -> Data {
        // Your download implementation
        let (data, _) = try await URLSession.shared.data(from: URL(string: urlString)!)
        return data
    }
}

// 2. Create image service
let downloader = MyImageDownloader()
let imageService = HWDefaultImageService(downloader: downloader)
```

### Load Images

```swift
// Load original image
let image = try await imageService.loadImage(
    from: url,
    displayMode: .original,
    cacheStrategy: .both  // Memory + Disk
)

// Load thumbnail
let thumbnail = try await imageService.loadImage(
    from: url,
    displayMode: .thumbnail(size: CGSize(width: 100, height: 100)),
    cacheStrategy: .both
)
```

### Cache Strategies

```swift
// Memory only (fast, cleared on app restart)
.memoryOnly

// Disk only (persistent, slower access)
.diskOnly

// Both (recommended)
.both

// No caching
.none
```

### Manual Cache Management

```swift
let cacheManager = HWCacheManager.shared

// Clear memory cache
cacheManager.clearMemoryCache()

// Clear disk cache
await cacheManager.clearDiskCache()

// Clear all
await cacheManager.clearAllCache()

// Get disk cache size
let size = await cacheManager.diskCacheSize()
print("Cache size: \(size) bytes")
```

## Cache File Structure

> Library/Caches/HwanCache/
> |-- 3a7b19fef8cd9db212f8d338ce58d8ad2e5c57d0c3d824ae9f34c57b8cf2a1f2   // original image for URL


### Disk Cache Key Design
HwanCache stores **only original image data** in disk cache.
Therefore the disk cache key is derived solely from the original URL (SHA256 hashed),
and does not include thumbnail size or display options.

Thumbnails are always memory-only and derived from the original disk data.


## Requirements

- iOS 13.0+ / macOS 12.0+
- Swift 5.9+
- Xcode 15.0+

## License
MIT License

## Author
Hwan
