import CryptoKit
import Foundation
import ImageIO
import UIKit

actor ImagePipeline {
    private let session: URLSession
    private let memoryCache = NSCache<NSString, UIImage>()
    private let diskCacheDirectory: URL?
    private var waitersByKey: [String: [CheckedContinuation<UIImage?, Never>]] = [:]

    init() {
        let config = URLSessionConfiguration.ephemeral
        config.urlCache = nil
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.httpCookieStorage = nil
        config.httpShouldSetCookies = false
        config.urlCredentialStorage = nil
        config.timeoutIntervalForRequest = 15
        self.session = URLSession(configuration: config)
        self.memoryCache.countLimit = 120

        if let cachesRoot = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)
            .first
        {
            let dir = cachesRoot.appendingPathComponent("KinetixImageCache", isDirectory: true)
            try? FileManager.default.createDirectory(
                at: dir,
                withIntermediateDirectories: true,
            )
            self.diskCacheDirectory = dir
        } else {
            self.diskCacheDirectory = nil
        }
    }

    func image(
        for url: URL,
        maxPixelDimension: Int,
    ) async -> UIImage? {
        guard url.scheme?.lowercased() == "https",
            let host = url.host,
            !host.isEmpty
        else {
            return nil
        }

        let clampedDimension = max(64, min(maxPixelDimension, 2048))
        let cacheKey = "\(url.absoluteString)|\(clampedDimension)"
        let nsKey = cacheKey as NSString

        if let cached = memoryCache.object(forKey: nsKey) {
            return cached
        }

        if waitersByKey[cacheKey] != nil {
            return await withCheckedContinuation { continuation in
                waitersByKey[cacheKey, default: []].append(continuation)
            }
        }

        waitersByKey[cacheKey] = []
        let loaded = await fetchAndDecode(
            url: url,
            maxPixelDimension: clampedDimension,
        )

        if let loaded {
            memoryCache.setObject(loaded, forKey: nsKey)
        }

        let waiters = waitersByKey.removeValue(forKey: cacheKey) ?? []
        for waiter in waiters {
            waiter.resume(returning: loaded)
        }

        return loaded
    }

    private func fetchAndDecode(
        url: URL,
        maxPixelDimension: Int,
    ) async -> UIImage? {
        let diskURL = diskFileURL(for: url)
        if let diskURL,
            let diskData = try? Data(contentsOf: diskURL),
            let decoded = await Self.downsample(
                data: diskData,
                maxPixelDimension: maxPixelDimension,
            )
        {
            return decoded
        }

        guard let (data, _) = try? await session.data(from: url),
            !Task.isCancelled,
            !data.isEmpty
        else {
            return nil
        }

        guard
            let decoded = await Self.downsample(
                data: data,
                maxPixelDimension: maxPixelDimension,
            )
        else {
            return nil
        }

        if let diskURL {
            try? data.write(to: diskURL, options: .atomic)
        }

        return decoded
    }

    private func diskFileURL(for url: URL) -> URL? {
        guard let diskCacheDirectory else {
            return nil
        }

        let digest = SHA256.hash(data: Data(url.absoluteString.utf8))
        let filename = digest.map { String(format: "%02x", $0) }.joined()
        return diskCacheDirectory.appendingPathComponent(filename, isDirectory: false)
    }

    @concurrent
    private static func downsample(
        data: Data,
        maxPixelDimension: Int,
    ) async -> UIImage? {
        let sourceOptions: [CFString: Any] = [
            kCGImageSourceShouldCache: false
        ]
        guard
            let source = CGImageSourceCreateWithData(
                data as CFData,
                sourceOptions as CFDictionary,
            )
        else {
            return nil
        }

        let downsampleOptions: [CFString: Any] = [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceShouldCacheImmediately: true,
            kCGImageSourceCreateThumbnailWithTransform: true,
            kCGImageSourceThumbnailMaxPixelSize: maxPixelDimension,
        ]
        guard
            let cgImage = CGImageSourceCreateThumbnailAtIndex(
                source,
                0,
                downsampleOptions as CFDictionary,
            )
        else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }
}
