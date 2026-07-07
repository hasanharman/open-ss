import AppKit
import CoreGraphics

struct WindowInfo: Sendable {
    let id: CGWindowID
    let ownerPID: pid_t
    let ownerName: String
    let title: String
    let bounds: CGRect

    static func visibleWindows() -> [WindowInfo] {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let items = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else { return [] }

        return items.compactMap { item in
            guard
                let id = item[kCGWindowNumber as String] as? UInt32,
                let ownerPID = item[kCGWindowOwnerPID as String] as? pid_t,
                let ownerName = item[kCGWindowOwnerName as String] as? String,
                let boundsDict = item[kCGWindowBounds as String] as? [String: Any],
                let bounds = CGRect(dictionaryRepresentation: boundsDict as CFDictionary)
            else { return nil }

            let layer = item[kCGWindowLayer as String] as? Int ?? 0
            let alpha = item[kCGWindowAlpha as String] as? Double ?? 1
            let title = (item[kCGWindowName as String] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard layer == 0, alpha > 0, bounds.width > 160, bounds.height > 120 else { return nil }
            let displayTitle = title.isEmpty ? "(Untitled)" : title
            return WindowInfo(id: CGWindowID(id), ownerPID: ownerPID, ownerName: ownerName, title: displayTitle, bounds: bounds)
        }
        .sorted { left, right in
            if left.ownerName == right.ownerName { return left.title < right.title }
            return left.ownerName < right.ownerName
        }
    }
}

enum WindowPreviewProvider {
    static func capture(windowID: CGWindowID) -> CGImage? {
        if let image = CGWindowListCreateImage(.null, [.optionIncludingWindow], windowID, [.boundsIgnoreFraming, .bestResolution]) {
            return image
        }

        let array = [windowID] as CFArray
        return CGImage(windowListFromArrayScreenBounds: .null, windowArray: array, imageOption: [.boundsIgnoreFraming, .bestResolution])
    }

    /// Captures a window and downscales it for thumbnail display. Full-resolution
    /// captures are ~25 MB each on Retina displays; caching those for every open
    /// window just to render a 88x50pt cell wastes hundreds of MB.
    static func thumbnail(windowID: CGWindowID, maxPixelWidth: Int) -> CGImage? {
        guard let image = capture(windowID: windowID) else { return nil }
        guard image.width > maxPixelWidth else { return image }

        let scale = Double(maxPixelWidth) / Double(image.width)
        let height = max(1, Int(Double(image.height) * scale))
        guard
            let context = CGContext(
                data: nil,
                width: maxPixelWidth,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else { return image }

        context.interpolationQuality = .medium
        context.draw(image, in: CGRect(x: 0, y: 0, width: maxPixelWidth, height: height))
        return context.makeImage()
    }

    static func canReadWindowDetails() -> Bool {
        let options: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let items = CGWindowListCopyWindowInfo(options, kCGNullWindowID) as? [[String: Any]] else { return false }
        return items.contains { item in
            guard
                let ownerPID = item[kCGWindowOwnerPID as String] as? pid_t,
                ownerPID != ProcessInfo.processInfo.processIdentifier,
                let name = item[kCGWindowName as String] as? String
            else { return false }
            return !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }
}
