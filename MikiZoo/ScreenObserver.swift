import AppKit
import ApplicationServices

// MARK: - Accessible Content

struct AccessibleContent {
    var appName: String = ""
    var windowTitle: String = ""
    var selectedText: String = ""
}

// MARK: - ScreenObserver

/// Layer 1: System event monitoring (clipboard, app switches) — zero API cost.
/// Layer 2: Accessibility API text extraction — also zero API cost.
class ScreenObserver {
    weak var engine: ProactiveTriggerEngine?

    private var clipboardChangeCount: Int = 0
    private var clipboardTimer: Timer?
    private var lastActiveApp: String = ""
    private var appContextTimer: Timer?

    // MARK: - Accessibility Permissions

    /// Requests accessibility permission from macOS if not already granted.
    /// Shows the system prompt once; subsequent calls are no-ops.
    static func requestAccessibilityPermissionIfNeeded() {
        let opts = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        AXIsProcessTrustedWithOptions(opts)
    }

    static var hasAccessibilityPermission: Bool {
        AXIsProcessTrusted()
    }

    // MARK: - Start / Stop

    func start() {
        clipboardChangeCount = NSPasteboard.general.changeCount

        // Poll clipboard every 1.5 s — lightweight, changeCount comparison only
        clipboardTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidActivate(_:)),
            name: NSWorkspace.didActivateApplicationNotification,
            object: nil
        )
    }

    func stop() {
        clipboardTimer?.invalidate()
        clipboardTimer = nil
        appContextTimer?.invalidate()
        appContextTimer = nil
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    // MARK: - Layer 1: Clipboard

    private func checkClipboard() {
        let current = NSPasteboard.general.changeCount
        guard current != clipboardChangeCount else { return }
        clipboardChangeCount = current

        guard let raw = NSPasteboard.general.string(forType: .string) else { return }
        let content = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard content.count > 15 else { return }

        engine?.clipboardChanged(content: content)
    }

    // MARK: - Layer 1: App Switch

    @objc private func appDidActivate(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let name = app.localizedName,
              name != lastActiveApp else { return }

        lastActiveApp = name
        appContextTimer?.invalidate()
        appContextTimer = nil

        engine?.appSwitched(to: name)

        // After 15 seconds in the same app, do a context check (free via Accessibility API)
        let capturedName = name
        appContextTimer = Timer.scheduledTimer(withTimeInterval: AppContextSettings.timerDuration, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            // Only fire if the user is still in the same app
            guard let current = NSWorkspace.shared.frontmostApplication,
                  current.localizedName == capturedName else { return }
            let content = self.getAccessibleContent()
            self.engine?.appContextAvailable(appName: capturedName, content: content)
        }
    }

    // MARK: - Layer 2: Accessibility API

    func getAccessibleContent() -> AccessibleContent {
        var result = AccessibleContent()
        guard Self.hasAccessibilityPermission else { return result }
        guard let app = NSWorkspace.shared.frontmostApplication else { return result }

        result.appName = app.localizedName ?? ""
        let axApp = AXUIElementCreateApplication(app.processIdentifier)

        // Window title — try three sources in order:
        // 1. Focused window (may be a panel with no title in complex apps like Xcode)
        // 2. Main window (the primary document window)
        // 3. First window in the windows list
        result.windowTitle = axWindowTitle(axApp, kAXFocusedWindowAttribute)
            ?? axWindowTitle(axApp, kAXMainWindowAttribute)
            ?? axWindowTitleFromList(axApp)
            ?? ""

        // Selected text in focused element
        var elementRef: CFTypeRef?
        if AXUIElementCopyAttributeValue(axApp, kAXFocusedUIElementAttribute as CFString, &elementRef) == .success,
           let elementRef = elementRef {
            let axElement = elementRef as! AXUIElement
            var selRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(axElement, kAXSelectedTextAttribute as CFString, &selRef) == .success {
                result.selectedText = (selRef as? String) ?? ""
            }
        }

        return result
    }

    func getSelectedText() -> String {
        getAccessibleContent().selectedText
    }

    // MARK: - AX Helpers

    private func axWindowTitle(_ axApp: AXUIElement, _ attribute: String) -> String? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, attribute as CFString, &ref) == .success,
              let ref = ref else { return nil }
        let axWin = ref as! AXUIElement
        var titleRef: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axWin, kAXTitleAttribute as CFString, &titleRef) == .success,
              let t = titleRef as? String, !t.isEmpty else { return nil }
        return t
    }

    private func axWindowTitleFromList(_ axApp: AXUIElement) -> String? {
        var ref: CFTypeRef?
        guard AXUIElementCopyAttributeValue(axApp, kAXWindowsAttribute as CFString, &ref) == .success,
              let arr = ref as? [AXUIElement] else { return nil }
        for win in arr {
            var titleRef: CFTypeRef?
            if AXUIElementCopyAttributeValue(win, kAXTitleAttribute as CFString, &titleRef) == .success,
               let t = titleRef as? String, !t.isEmpty {
                return t
            }
        }
        return nil
    }
}
