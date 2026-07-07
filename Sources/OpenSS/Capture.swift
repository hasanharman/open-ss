import AppKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

struct CaptureOptions: Sendable {
    let contentOnly: Bool
}

enum LongScreenshotError: LocalizedError {
    case screenCapturePermission
    case accessibilityPermission
    case windowCaptureFailed
    case imageStitchFailed
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .screenCapturePermission:
            return "Screen Recording permission is required. Enable it in System Settings, then relaunch OpenSS."
        case .accessibilityPermission:
            return "Accessibility permission is required so OpenSS can scroll the selected window."
        case .windowCaptureFailed:
            return "OpenSS could not capture the selected window. Make sure the window is visible and not minimized."
        case .imageStitchFailed:
            return "OpenSS captured frames but could not stitch them into one image."
        case .saveFailed:
            return "OpenSS could not save the screenshot to your Desktop."
        }
    }
}

enum LongScreenshot {
    private static let maximumAutoScrollFrames = 80

    static func capture(
        window: WindowInfo,
        options: CaptureOptions,
        progress: (Int) -> Void
    ) -> Result<URL, Error> {
        guard PermissionPrompter.hasScreenCapturePermission else { return .failure(LongScreenshotError.screenCapturePermission) }

        focus(processID: window.ownerPID)
        Thread.sleep(forTimeInterval: 0.45)
        let scrollPoint = scrollablePoint(in: window, contentOnly: options.contentOnly)
        click(at: scrollPoint)
        Thread.sleep(forTimeInterval: 0.18)

        guard let firstRawImage = captureWindow(window.id), let firstImage = prepare(firstRawImage, window: window, options: options) else {
            return .failure(LongScreenshotError.windowCaptureFailed)
        }

        var frameCount = 1
        progress(frameCount)

        // Keep only the first full frame plus a detached copy of each later frame's
        // stitch slice. Retaining every full-resolution frame (~25 MB each on Retina)
        // for up to 80 frames peaks near 2 GB; slices plus fingerprints stay small.
        let ignoringTopRatio = options.contentOnly ? 0.08 : 0.18
        let sliceStart = ImageStitcher.sliceStart(forFirstFrameHeight: firstImage.height)
        var slices: [CGImage] = []
        var previousFingerprint = ImageComparator.fingerprint(firstImage, ignoringTopRatio: ignoringTopRatio)
        let scrollAmount = adaptiveScrollAmount(for: window)

        for _ in 1..<maximumAutoScrollFrames {
            scrollDown(amount: scrollAmount, at: scrollPoint)
            Thread.sleep(forTimeInterval: 0.55)

            guard let nextRawImage = captureWindow(window.id), let nextImage = prepare(nextRawImage, window: window, options: options) else {
                break
            }

            let nextFingerprint = ImageComparator.fingerprint(nextImage, ignoringTopRatio: ignoringTopRatio)
            if ImageComparator.isSimilar(previousFingerprint, nextFingerprint) {
                break
            }

            guard let slice = ImageStitcher.copySlice(of: nextImage, from: sliceStart) else {
                break
            }

            slices.append(slice)
            previousFingerprint = nextFingerprint
            frameCount += 1
            progress(frameCount)
        }

        guard let stitched = ImageStitcher.stitch(first: firstImage, slices: slices) else {
            return .failure(LongScreenshotError.imageStitchFailed)
        }

        guard let url = ImageWriter.writePNG(image: stitched) else {
            return .failure(LongScreenshotError.saveFailed)
        }

        return .success(url)
    }

    private static func captureWindow(_ id: CGWindowID) -> CGImage? {
        CGWindowListCreateImage(.null, [.optionIncludingWindow], id, [.boundsIgnoreFraming, .bestResolution])
    }

    private static func focus(processID: pid_t) {
        NSRunningApplication(processIdentifier: processID)?.activate(options: [.activateIgnoringOtherApps])
    }

    private static func adaptiveScrollAmount(for window: WindowInfo) -> Int {
        let visibleHeight = max(400, Int(window.bounds.height))
        return min(1600, max(420, Int(Double(visibleHeight) * 0.62)))
    }

    private static func scrollDown(amount: Int, at point: CGPoint) {
        let event = CGEvent(scrollWheelEvent2Source: nil, units: .pixel, wheelCount: 1, wheel1: -Int32(amount), wheel2: 0, wheel3: 0)
        event?.location = point
        event?.post(tap: .cghidEventTap)
    }

    private static func scrollablePoint(in window: WindowInfo, contentOnly: Bool) -> CGPoint {
        let x = window.bounds.midX
        let yOffset = contentOnly ? max(150, window.bounds.height * 0.22) : max(90, window.bounds.height * 0.16)
        let y = window.bounds.minY + yOffset
        return CGPoint(x: x, y: y)
    }

    private static func click(at point: CGPoint) {
        let source = CGEventSource(stateID: .hidSystemState)
        CGEvent(mouseEventSource: source, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left)?.post(tap: .cghidEventTap)
        CGEvent(mouseEventSource: source, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left)?.post(tap: .cghidEventTap)
    }

    private static func prepare(_ image: CGImage, window: WindowInfo, options: CaptureOptions) -> CGImage? {
        guard options.contentOnly else { return image }
        return CaptureCropper.cropContent(from: image, ownerName: window.ownerName)
    }
}

enum ImageComparator {
    static func isSimilar(_ left: [UInt8]?, _ right: [UInt8]?) -> Bool {
        guard let left, let right, left.count == right.count, !left.isEmpty else { return false }

        let totalDifference = zip(left, right).reduce(0) { partial, pair in
            partial + abs(Int(pair.0) - Int(pair.1))
        }
        let averageDifference = Double(totalDifference) / Double(left.count)
        return averageDifference < 1.2
    }

    static func fingerprint(_ image: CGImage, ignoringTopRatio: Double) -> [UInt8]? {
        let width = 32
        let height = 32
        var pixels = [UInt8](repeating: 0, count: width * height * 4)

        guard
            let context = CGContext(
                data: &pixels,
                width: width,
                height: height,
                bitsPerComponent: 8,
                bytesPerRow: width * 4,
                space: CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else { return nil }

        context.interpolationQuality = .low
        let sourceTop = Int(Double(image.height) * max(0, min(0.7, ignoringTopRatio)))
        let sourceRect = CGRect(x: 0, y: sourceTop, width: image.width, height: max(1, image.height - sourceTop))
        guard let cropped = image.cropping(to: sourceRect) else { return nil }
        context.draw(cropped, in: CGRect(x: 0, y: 0, width: width, height: height))

        var grayscale = [UInt8]()
        grayscale.reserveCapacity(width * height)
        for index in stride(from: 0, to: pixels.count, by: 4) {
            let red = Double(pixels[index])
            let green = Double(pixels[index + 1])
            let blue = Double(pixels[index + 2])
            grayscale.append(UInt8((red * 0.299 + green * 0.587 + blue * 0.114).rounded()))
        }
        return grayscale
    }
}

enum CaptureCropper {
    static func cropContent(from image: CGImage, ownerName: String) -> CGImage? {
        let top = topInset(for: ownerName, imageHeight: image.height)
        guard top > 0 else { return image }
        let rect = CGRect(x: 0, y: top, width: image.width, height: max(1, image.height - top))
        return image.cropping(to: rect) ?? image
    }

    private static func topInset(for ownerName: String, imageHeight: Int) -> Int {
        let app = ownerName.lowercased()
        if app.contains("chrome") || app.contains("edge") || app.contains("brave") || app.contains("arc") {
            return min(150, max(96, Int(Double(imageHeight) * 0.115)))
        }
        if app.contains("safari") {
            return min(130, max(78, Int(Double(imageHeight) * 0.095)))
        }
        return 0
    }
}

enum ImageStitcher {
    static func sliceStart(forFirstFrameHeight firstHeight: Int) -> Int {
        let repeatedHeader = min(96, max(0, firstHeight / 6))
        return min(firstHeight - 1, max(repeatedHeader, firstHeight / 4))
    }

    /// Copies the region below `sliceStart` into its own bitmap. `CGImage.cropping(to:)`
    /// shares the parent image's backing store, so a plain crop would keep the whole
    /// full-resolution frame alive for the duration of the capture.
    static func copySlice(of frame: CGImage, from sliceStart: Int) -> CGImage? {
        let sliceHeight = frame.height - sliceStart
        guard sliceHeight > 0 else { return nil }
        guard let cropped = frame.cropping(to: CGRect(x: 0, y: sliceStart, width: frame.width, height: sliceHeight)) else { return nil }

        guard
            let context = CGContext(
                data: nil,
                width: cropped.width,
                height: cropped.height,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: cropped.colorSpace ?? CGColorSpaceCreateDeviceRGB(),
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else { return nil }

        context.draw(cropped, in: CGRect(x: 0, y: 0, width: cropped.width, height: cropped.height))
        return context.makeImage()
    }

    static func stitch(first: CGImage, slices: [CGImage]) -> CGImage? {
        guard !slices.isEmpty else { return first }

        let width = first.width
        let totalHeight = first.height + slices.reduce(0) { $0 + $1.height }

        guard
            let colorSpace = first.colorSpace ?? CGColorSpace(name: CGColorSpace.sRGB),
            let context = CGContext(
                data: nil,
                width: width,
                height: totalHeight,
                bitsPerComponent: 8,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            )
        else { return nil }

        context.interpolationQuality = .high
        var cursor = 0
        draw(first, in: context, y: cursor, height: first.height)
        cursor += first.height

        for slice in slices {
            draw(slice, in: context, y: cursor, height: slice.height)
            cursor += slice.height
        }

        return context.makeImage()
    }

    private static func draw(_ image: CGImage, in context: CGContext, y: Int, height: Int) {
        let drawY = context.height - y - height
        context.draw(image, in: CGRect(x: 0, y: drawY, width: image.width, height: height))
    }
}

enum ImageWriter {
    static func writePNG(image: CGImage) -> URL? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let filename = "OpenSS-\(formatter.string(from: Date())).png"
        let url = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask)[0].appendingPathComponent(filename)

        guard
            let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil)
        else { return nil }

        CGImageDestinationAddImage(destination, image, nil)
        return CGImageDestinationFinalize(destination) ? url : nil
    }
}
