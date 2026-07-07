import AppKit

@MainActor
final class WindowPickerController: NSViewController, NSTableViewDataSource, NSTableViewDelegate {
    var onClose: (() -> Void)?
    var onCheckPermissions: (() -> Void)?
    var onRestart: (() -> Void)?

    private static let previewMaxPixelWidth = 360

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
        guard let cgImage = WindowPreviewProvider.thumbnail(windowID: window.id, maxPixelWidth: Self.previewMaxPixelWidth) else {
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
