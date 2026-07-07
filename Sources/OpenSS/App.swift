import AppKit
import Carbon

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
