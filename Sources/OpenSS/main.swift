import AppKit
import ApplicationServices
import Carbon
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let popover = NSPopover()
    private var hotKey: HotKey?
    private var pickerController: WindowPickerController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        hotKey = HotKey(keyCode: UInt32(kVK_ANSI_L), modifiers: UInt32(cmdKey | shiftKey)) { [weak self] in
            self?.openWindowPicker()
        }
    }

    private func configureStatusItem() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "camera.viewfinder", accessibilityDescription: "OpenSS")
            button.toolTip = "OpenSS"
            button.target = self
            button.action = #selector(toggleWindowPicker)
        }

        popover.behavior = .transient
        popover.animates = true
    }

    @objc private func toggleWindowPicker() {
        if popover.isShown {
            popover.performClose(nil)
        } else {
            openWindowPicker()
        }
    }

    @objc private func openWindowPicker() {
        let controller = WindowPickerController()
        controller.onClose = { [weak self] in
            self?.popover.performClose(nil)
            self?.pickerController = nil
        }
        controller.onCheckPermissions = { [weak self] in
            self?.checkPermissions()
        }
        controller.onRestart = {
            AppRelauncher.relaunch()
        }
        self.pickerController = controller
        popover.contentViewController = controller
        popover.contentSize = NSSize(width: 520, height: 500)

        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        controller.focusPicker()
    }

    @objc private func checkPermissions() {
        PermissionPrompter.requestScreenCaptureIfNeeded()
        PermissionPrompter.requestAccessibilityIfNeeded()

        let status = PermissionStatus.current
        Alert.show(
            title: "OpenSS Permissions",
            message: """
            Screen Recording: \(status.screenRecording ? "Granted" : "Needs permission")
            Accessibility: \(status.accessibility ? "Granted" : "Needs permission")

            Both permissions are needed for long screenshots. Screen Recording captures the selected window; Accessibility lets OpenSS send scroll gestures.
            """
        )
        pickerController?.refreshPermissionStatus()
    }
}

@MainActor
final class WindowPickerController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    var onClose: (() -> Void)?
    var onCheckPermissions: (() -> Void)?
    var onRestart: (() -> Void)?

    private let windows = WindowInfo.visibleWindows()
    private let tableView = HoverSelectingTableView()
    private let progress = NSProgressIndicator()
    private let permissionLabel = NSTextField(labelWithString: "")
    private let statusLabel = NSTextField(labelWithString: "Click a window to capture.")
    private let contentOnlyCheckbox = NSButton(checkboxWithTitle: "Content only", target: nil, action: nil)
    private var permissionHeightConstraint: NSLayoutConstraint?
    private var previewCache: [CGWindowID: NSImage] = [:]
    private var isCapturing = false

    init() {
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 520, height: 500))
        preferredContentSize = NSSize(width: 520, height: 500)
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        buildUI()
        refreshPermissionStatus()
    }

    func focusPicker() {
        view.window?.makeFirstResponder(tableView)
    }

    private func buildUI() {
        let content = view
        content.wantsLayer = true
        content.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor

        let title = NSTextField(labelWithString: "OpenSS")
        title.alignment = .center
        title.font = .systemFont(ofSize: 20, weight: .bold)

        let subtitle = NSTextField(labelWithString: "Pick a window for a long screenshot.")
        subtitle.textColor = .secondaryLabelColor
        subtitle.alignment = .center
        subtitle.lineBreakMode = .byWordWrapping
        subtitle.maximumNumberOfLines = 2

        permissionLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        permissionLabel.alignment = .center
        permissionLabel.lineBreakMode = .byWordWrapping
        permissionLabel.maximumNumberOfLines = 2

        statusLabel.lineBreakMode = .byTruncatingTail
        statusLabel.maximumNumberOfLines = 1

        let scrollView = NSScrollView()
        scrollView.borderType = .noBorder
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.documentView = tableView

        let previewColumn = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("preview"))
        previewColumn.title = "Windows"
        previewColumn.width = 480
        tableView.addTableColumn(previewColumn)
        tableView.headerView = nil
        tableView.rowHeight = 70
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.selectionHighlightStyle = .regular
        tableView.backgroundColor = .clear
        tableView.intercellSpacing = NSSize(width: 0, height: 6)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.onHoverRow = { [weak self] row in
            guard let self, row >= 0, row < self.windows.count else { return }
            self.statusLabel.stringValue = "\(self.windows[row].ownerName) - \(self.windows[row].title)"
        }
        tableView.onClickRow = { [weak self] row in
            guard let self, row >= 0, row < self.windows.count else { return }
            self.tableView.selectRowIndexes(IndexSet(integer: row), byExtendingSelection: false)
            self.captureSelectedWindow()
        }

        let permissionsButton = NSButton(title: "Check Permissions", target: self, action: #selector(checkPermissionsTapped))
        permissionsButton.bezelStyle = .rounded

        let restartButton = NSButton(title: "Restart OpenSS", target: self, action: #selector(restartTapped))
        restartButton.bezelStyle = .rounded

        let quitButton = NSButton(title: "Quit", target: NSApplication.shared, action: #selector(NSApplication.terminate(_:)))
        quitButton.bezelStyle = .rounded

        contentOnlyCheckbox.target = self
        contentOnlyCheckbox.state = .on

        progress.isIndeterminate = true
        progress.minValue = 0
        progress.maxValue = 1
        progress.doubleValue = 0

        [title, subtitle, permissionLabel, scrollView, contentOnlyCheckbox, permissionsButton, restartButton, quitButton, progress, statusLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            content.addSubview($0)
        }

        let permissionHeightConstraint = permissionLabel.heightAnchor.constraint(equalToConstant: 0)
        self.permissionHeightConstraint = permissionHeightConstraint

        NSLayoutConstraint.activate([
            title.topAnchor.constraint(equalTo: content.topAnchor, constant: 18),
            title.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            title.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),

            subtitle.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 6),
            subtitle.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            subtitle.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),

            permissionLabel.topAnchor.constraint(equalTo: subtitle.bottomAnchor, constant: 12),
            permissionLabel.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            permissionLabel.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            permissionHeightConstraint,

            scrollView.topAnchor.constraint(equalTo: permissionLabel.bottomAnchor, constant: 10),
            scrollView.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 20),
            scrollView.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -20),
            scrollView.bottomAnchor.constraint(equalTo: contentOnlyCheckbox.topAnchor, constant: -12),

            contentOnlyCheckbox.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            contentOnlyCheckbox.bottomAnchor.constraint(equalTo: progress.topAnchor, constant: -12),

            progress.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            progress.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            progress.bottomAnchor.constraint(equalTo: permissionsButton.topAnchor, constant: -12),

            permissionsButton.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            permissionsButton.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: -12),

            restartButton.centerXAnchor.constraint(equalTo: scrollView.centerXAnchor),
            restartButton.centerYAnchor.constraint(equalTo: permissionsButton.centerYAnchor),

            quitButton.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            quitButton.centerYAnchor.constraint(equalTo: permissionsButton.centerYAnchor),

            statusLabel.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            statusLabel.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            statusLabel.bottomAnchor.constraint(equalTo: content.bottomAnchor, constant: -16)
        ])
    }

    func numberOfRows(in tableView: NSTableView) -> Int {
        windows.count
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let id = NSUserInterfaceItemIdentifier("previewCell")
        let cell = tableView.makeView(withIdentifier: id, owner: self) as? WindowPreviewCell ?? WindowPreviewCell()
        cell.identifier = id
        let info = windows[row]
        cell.configure(
            appName: info.ownerName,
            windowTitle: info.title,
            image: previewImage(for: info)
        )
        return cell
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        WindowPickerRowView()
    }

    func refreshPermissionStatus() {
        let status = PermissionStatus.current
        if status.isReady {
            permissionLabel.stringValue = ""
            permissionLabel.isHidden = true
            permissionHeightConstraint?.constant = 0
        } else {
            permissionLabel.stringValue = status.pickerTitle
            permissionLabel.textColor = .systemRed
            permissionLabel.isHidden = false
            permissionHeightConstraint?.constant = 34
        }
    }

    private func previewImage(for window: WindowInfo) -> NSImage? {
        if let cached = previewCache[window.id] { return cached }
        guard let cgImage = WindowPreviewProvider.capture(windowID: window.id) else {
            return nil
        }
        let image = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        previewCache[window.id] = image
        return image
    }

    @objc private func checkPermissionsTapped() {
        onCheckPermissions?()
    }

    @objc private func restartTapped() {
        onRestart?()
    }

    private func captureSelectedWindow() {
        guard !isCapturing else { return }
        let row = tableView.selectedRow
        guard row >= 0, row < windows.count else {
            Alert.show(title: "No Window Selected", message: "Choose the window you want OpenSS to scroll and capture.")
            return
        }

        PermissionPrompter.requestScreenCaptureIfNeeded()
        PermissionPrompter.requestAccessibilityIfNeeded()

        isCapturing = true
        statusLabel.stringValue = "Capturing until the page stops scrolling..."
        progress.startAnimation(nil)

        let info = windows[row]
        let options = CaptureOptions(contentOnly: contentOnlyCheckbox.state == .on)
        view.window?.orderOut(nil)

        DispatchQueue.global(qos: .userInitiated).async {
            let result = LongScreenshot.capture(window: info, options: options) { [weak self] current in
                DispatchQueue.main.async {
                    self?.statusLabel.stringValue = "Captured \(current) frames..."
                }
            }

            DispatchQueue.main.async {
                self.isCapturing = false
                self.progress.stopAnimation(nil)
                switch result {
                case .success(let url):
                    self.statusLabel.stringValue = "Saved to \(url.path)"
                    NSWorkspace.shared.activateFileViewerSelecting([url])
                case .failure(let error):
                    self.statusLabel.stringValue = "Capture failed."
                    Alert.show(title: "Capture Failed", message: error.localizedDescription)
                }
            }
        }
    }
}

struct PermissionStatus {
    let screenRecording: Bool
    let accessibility: Bool

    var isReady: Bool {
        screenRecording
    }

    var menuTitle: String {
        isReady ? "Permissions OK" : "Permissions Need Attention"
    }

    var pickerTitle: String {
        if isReady {
            return accessibility
                ? "Permissions OK: previews and scrolling are enabled."
                : "Previews OK. Accessibility may need a restart before scrolling works."
        }

        var missing: [String] = []
        if !screenRecording { missing.append("Screen Recording") }
        return "Permissions pending: \(missing.joined(separator: ", ")). If toggles are already on, restart OpenSS."
    }

    static var current: PermissionStatus {
        PermissionStatus(
            screenRecording: PermissionPrompter.hasScreenCapturePermission || WindowPreviewProvider.canReadWindowDetails(),
            accessibility: AXIsProcessTrusted()
        )
    }
}

@MainActor
final class HoverSelectingTableView: NSTableView {
    var onHoverRow: ((Int) -> Void)?
    var onClickRow: ((Int) -> Void)?
    private var activeTrackingArea: NSTrackingArea?
    private var hoveredRow = -1

    override func updateTrackingAreas() {
        if let activeTrackingArea {
            removeTrackingArea(activeTrackingArea)
        }

        let trackingArea = NSTrackingArea(
            rect: bounds,
            options: [.mouseEnteredAndExited, .mouseMoved, .activeAlways, .inVisibleRect],
            owner: self,
            userInfo: nil
        )
        addTrackingArea(trackingArea)
        activeTrackingArea = trackingArea
        super.updateTrackingAreas()
    }

    override func mouseMoved(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let row = self.row(at: point)
        updateHover(row: row)
        if row >= 0 {
            onHoverRow?(row)
        }
        super.mouseMoved(with: event)
    }

    override func mouseExited(with event: NSEvent) {
        updateHover(row: -1)
        super.mouseExited(with: event)
    }

    override func mouseDown(with event: NSEvent) {
        let point = convert(event.locationInWindow, from: nil)
        let clickedRow = row(at: point)
        super.mouseDown(with: event)

        if clickedRow >= 0 {
            onClickRow?(clickedRow)
        }
    }

    private func updateHover(row: Int) {
        guard hoveredRow != row else { return }
        let oldRow = hoveredRow
        hoveredRow = row
        [oldRow, row].forEach { index in
            guard index >= 0, let rowView = rowView(atRow: index, makeIfNecessary: false) as? WindowPickerRowView else { return }
            rowView.isHovered = index == row
        }
    }
}

@MainActor
final class WindowPickerRowView: NSTableRowView {
    var isHovered = false {
        didSet { needsDisplay = true }
    }

    override var isSelected: Bool {
        didSet { needsDisplay = true }
    }

    override func drawBackground(in dirtyRect: NSRect) {
        let rect = bounds.insetBy(dx: 0, dy: 2)
        let path = NSBezierPath(roundedRect: rect, xRadius: 7, yRadius: 7)
        if isSelected {
            NSColor.controlAccentColor.setFill()
        } else if isHovered {
            NSColor.controlAccentColor.withAlphaComponent(0.22).setFill()
        } else {
            NSColor.controlBackgroundColor.withAlphaComponent(0.65).setFill()
        }
        path.fill()
    }

    override func drawSelection(in dirtyRect: NSRect) {
        drawBackground(in: dirtyRect)
    }
}

@MainActor
final class WindowPreviewCell: NSTableCellView {
    private let previewView = NSImageView()
    private let appLabel = NSTextField(labelWithString: "")
    private let titleLabel = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        buildUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        buildUI()
    }

    func configure(appName: String, windowTitle: String, image: NSImage?) {
        appLabel.stringValue = appName
        titleLabel.stringValue = windowTitle
        previewView.image = image ?? NSImage(systemSymbolName: "rectangle.dashed", accessibilityDescription: "No preview")
        previewView.contentTintColor = image == nil ? .tertiaryLabelColor : nil
    }

    private func buildUI() {
        wantsLayer = true

        previewView.imageScaling = .scaleProportionallyUpOrDown
        previewView.wantsLayer = true
        previewView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.28).cgColor
        previewView.layer?.cornerRadius = 4
        previewView.layer?.masksToBounds = true

        appLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        appLabel.textColor = .labelColor
        appLabel.lineBreakMode = .byTruncatingTail
        appLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        titleLabel.font = .systemFont(ofSize: 13, weight: .regular)
        titleLabel.textColor = .secondaryLabelColor
        titleLabel.lineBreakMode = .byTruncatingTail
        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        [previewView, appLabel, titleLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            previewView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            previewView.centerYAnchor.constraint(equalTo: centerYAnchor),
            previewView.widthAnchor.constraint(equalToConstant: 88),
            previewView.heightAnchor.constraint(equalToConstant: 50),

            appLabel.leadingAnchor.constraint(equalTo: previewView.trailingAnchor, constant: 14),
            appLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            appLabel.bottomAnchor.constraint(equalTo: centerYAnchor, constant: -2),

            titleLabel.leadingAnchor.constraint(equalTo: appLabel.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: appLabel.trailingAnchor),
            titleLabel.topAnchor.constraint(equalTo: centerYAnchor, constant: 2)
        ])
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

struct WindowInfo {
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

struct CaptureOptions: Sendable {
    let contentOnly: Bool
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

        var frames: [CGImage] = []
        guard let firstRawImage = captureWindow(window.id), let firstImage = prepare(firstRawImage, window: window, options: options) else {
            return .failure(LongScreenshotError.windowCaptureFailed)
        }

        frames.append(firstImage)
        progress(frames.count)

        let scrollAmount = adaptiveScrollAmount(for: window)
        var previousImage = firstImage

        for _ in 1..<maximumAutoScrollFrames {
            scrollDown(amount: scrollAmount, at: scrollPoint)
            Thread.sleep(forTimeInterval: 0.55)

            guard let nextRawImage = captureWindow(window.id), let nextImage = prepare(nextRawImage, window: window, options: options) else {
                break
            }

            if ImageComparator.isVisuallySimilar(previousImage, nextImage, ignoringTopRatio: options.contentOnly ? 0.08 : 0.18) {
                break
            }

            frames.append(nextImage)
            previousImage = nextImage
            progress(frames.count)
        }

        guard let stitched = ImageStitcher.stitch(frames: frames) else {
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
    static func isVisuallySimilar(_ left: CGImage, _ right: CGImage, ignoringTopRatio: Double) -> Bool {
        guard
            let leftFingerprint = fingerprint(left, ignoringTopRatio: ignoringTopRatio),
            let rightFingerprint = fingerprint(right, ignoringTopRatio: ignoringTopRatio),
            leftFingerprint.count == rightFingerprint.count
        else { return false }

        let totalDifference = zip(leftFingerprint, rightFingerprint).reduce(0) { partial, pair in
            partial + abs(Int(pair.0) - Int(pair.1))
        }
        let averageDifference = Double(totalDifference) / Double(leftFingerprint.count)
        return averageDifference < 1.2
    }

    private static func fingerprint(_ image: CGImage, ignoringTopRatio: Double) -> [UInt8]? {
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
    static func stitch(frames: [CGImage]) -> CGImage? {
        guard let first = frames.first else { return nil }
        guard frames.count > 1 else { return first }

        let width = first.width
        let firstHeight = first.height
        let repeatedHeader = min(96, max(0, firstHeight / 6))
        let sliceStart = min(firstHeight - 1, max(repeatedHeader, firstHeight / 4))
        let sliceHeight = max(1, firstHeight - sliceStart)
        let totalHeight = firstHeight + (frames.count - 1) * sliceHeight

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
        draw(first, in: context, y: cursor, height: firstHeight)
        cursor += firstHeight

        for frame in frames.dropFirst() {
            guard let cropped = frame.cropping(to: CGRect(x: 0, y: sliceStart, width: min(width, frame.width), height: min(sliceHeight, frame.height - sliceStart))) else {
                continue
            }
            draw(cropped, in: context, y: cursor, height: cropped.height)
            cursor += cropped.height
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

enum PermissionPrompter {
    static var hasScreenCapturePermission: Bool {
        CGPreflightScreenCaptureAccess() || WindowPreviewProvider.canReadWindowDetails()
    }

    static func requestScreenCaptureIfNeeded() {
        if !CGPreflightScreenCaptureAccess() {
            CGRequestScreenCaptureAccess()
        }
    }

    static func requestAccessibilityIfNeeded() {
        if !AXIsProcessTrusted() {
            let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
            AXIsProcessTrustedWithOptions(options)
        }
    }
}

enum AppRelauncher {
    @MainActor
    static func relaunch() {
        let bundleURL = Bundle.main.bundleURL
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true

        NSWorkspace.shared.openApplication(at: bundleURL, configuration: configuration) { _, error in
            Task { @MainActor in
                if let error {
                    Alert.show(title: "Restart Failed", message: error.localizedDescription)
                    return
                }
                NSApp.terminate(nil)
            }
        }
    }
}

final class HotKey: @unchecked Sendable {
    private var hotKeyRef: EventHotKeyRef?
    private var handlerRef: EventHandlerRef?
    private let callback: @MainActor @Sendable () -> Void

    init(keyCode: UInt32, modifiers: UInt32, callback: @escaping @MainActor @Sendable () -> Void) {
        self.callback = callback

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let selfPointer = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            guard let event, let userData else { return noErr }
            var hotKeyID = EventHotKeyID()
            GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            let hotKey = Unmanaged<HotKey>.fromOpaque(userData).takeUnretainedValue()
            Task { @MainActor in hotKey.callback() }
            return noErr
        }, 1, &eventType, selfPointer, &handlerRef)

        var hotKeyID = EventHotKeyID(signature: OSType(0x4F53534C), id: 1)
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }

    deinit {
        if let hotKeyRef { UnregisterEventHotKey(hotKeyRef) }
        if let handlerRef { RemoveEventHandler(handlerRef) }
    }
}

final class IntegerFormatter: NumberFormatter, @unchecked Sendable {
    override init() {
        super.init()
        numberStyle = .none
        allowsFloats = false
        minimum = 1
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}

@MainActor
enum Alert {
    static func show(title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
}

@main
enum OpenSSMain {
    @MainActor
    private static var delegate: AppDelegate?

    @MainActor
    static func main() {
        let app = NSApplication.shared
        let appDelegate = AppDelegate()
        delegate = appDelegate
        app.delegate = appDelegate
        app.run()
    }
}
