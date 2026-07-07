import AppKit
import ApplicationServices
import Carbon

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
