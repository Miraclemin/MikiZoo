import SwiftUI
import AppKit
import UniformTypeIdentifiers

@main
struct MikiZooApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var controller: MikiZooController?
    var statusItem: NSStatusItem?

    // Per-character submenu state items (index 0 = Miki)
    var charMenuItems:        [NSMenuItem] = []        // top-level menu items (for title sync)
    var charVisibleItems:     [NSMenuItem] = []
    var charMovingItems:      [NSMenuItem] = []
    var charRemoveImageItems: [Int: NSMenuItem] = [:]  // keyed by characterIndex

    // Dynamic agent menu items (inserted before separator before Sounds)
    var dynamicAgentMenuItems: [NSMenuItem] = []
    weak var mainMenu: NSMenu?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        controller = MikiZooController()
        controller?.start()
        setupMenuBar()
        // Rebuild dynamic agent menu items for any agents loaded from persistence
        if let extras = controller?.characters.dropFirst(2) {
            for char in extras {
                insertDynamicAgentMenuItem(for: char)
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        controller?.characters.forEach { $0.session?.terminate() }
    }

    // MARK: - Menu Bar

    func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        if let button = statusItem?.button {
            button.image = NSImage(named: "MenuBarIcon") ?? NSImage(systemSymbolName: "figure.walk", accessibilityDescription: "lil agents")
        }

        let menu = NSMenu()

        let charNames = ["Miki"]
        let charKeys  = ["1"]
        for idx in 0..<1 {
            let charItem = NSMenuItem(title: charNames[idx], action: nil, keyEquivalent: charKeys[idx])
            let charMenu = NSMenu()

            let visItem = NSMenuItem(title: "Visible", action: #selector(toggleCharVisibility(_:)), keyEquivalent: "")
            visItem.tag = idx
            let chars = controller?.characters ?? []
            let charVisible = idx < chars.count ? chars[idx].isManuallyVisible : true
            visItem.state = charVisible ? .on : .off
            charMenu.addItem(visItem)

            let movingItem = NSMenuItem(title: "Moving", action: #selector(toggleMovingMode(_:)), keyEquivalent: "")
            movingItem.tag = idx
            let isMoving = idx < chars.count ? chars[idx].isMovingMode : false
            movingItem.state = isMoving ? .on : .off
            charMenu.addItem(movingItem)
            charMovingItems.append(movingItem)

            charMenu.addItem(makeSpeedSliderItem(for: idx))

            charMenu.addItem(.separator())

            let setImgItem = NSMenuItem(title: "Set Custom Image…", action: #selector(setCustomImage(_:)), keyEquivalent: "")
            setImgItem.tag = idx
            charMenu.addItem(setImgItem)

            let removeImgItem = NSMenuItem(title: "Remove Custom Image", action: #selector(removeCustomImage(_:)), keyEquivalent: "")
            removeImgItem.tag = idx
            removeImgItem.isEnabled = false
            charMenu.addItem(removeImgItem)
            charRemoveImageItems[idx] = removeImgItem

            let mirrorItem = NSMenuItem(title: "Mirror Image (faces left by default)", action: #selector(charMirrorImage(_:)), keyEquivalent: "")
            mirrorItem.tag = idx
            mirrorItem.state = .off
            charMenu.addItem(mirrorItem)

            charMenu.addItem(.separator())

            let personaItem = NSMenuItem(title: "Configure Persona…", action: #selector(configurePersona(_:)), keyEquivalent: "")
            personaItem.tag = idx
            charMenu.addItem(personaItem)

            charItem.submenu = charMenu
            menu.addItem(charItem)
            charMenuItems.append(charItem)
        }

        menu.addItem(NSMenuItem.separator())

        // Smart Suggestions submenu
        let suggestItem = NSMenuItem(title: "Smart Suggestions", action: nil, keyEquivalent: "")
        let suggestMenu = NSMenu()

        // Context Timer sub-submenu
        let timerItem = NSMenuItem(title: "Context Timer", action: nil, keyEquivalent: "")
        let timerMenu = NSMenu()
        for option in AppContextSettings.timerOptions {
            let item = NSMenuItem(title: option.label, action: #selector(setContextTimer(_:)), keyEquivalent: "")
            item.representedObject = option.seconds as AnyObject
            item.state = AppContextSettings.timerDuration == option.seconds ? .on : .off
            timerMenu.addItem(item)
        }
        timerItem.submenu = timerMenu
        suggestMenu.addItem(timerItem)

        suggestMenu.addItem(NSMenuItem.separator())

        // App checkboxes
        let appsLabel = NSMenuItem(title: "Trigger Apps:", action: nil, keyEquivalent: "")
        appsLabel.isEnabled = false
        suggestMenu.addItem(appsLabel)
        for rule in AppContextSettings.allRules {
            let item = NSMenuItem(title: rule.displayName, action: #selector(toggleAppRule(_:)), keyEquivalent: "")
            item.representedObject = rule.id as AnyObject
            item.state = AppContextSettings.isRuleEnabled(rule.id) ? .on : .off
            suggestMenu.addItem(item)
        }

        suggestItem.submenu = suggestMenu
        menu.addItem(suggestItem)

        menu.addItem(NSMenuItem.separator())

        // "+ Add Agent…" button
        let addAgentItem = NSMenuItem(title: "+ Add Agent…", action: #selector(addAgent(_:)), keyEquivalent: "")
        menu.addItem(addAgentItem)

        menu.addItem(NSMenuItem.separator())

        let soundItem = NSMenuItem(title: "Sounds", action: #selector(toggleSounds(_:)), keyEquivalent: "")
        soundItem.state = .on
        menu.addItem(soundItem)

        // Provider submenu
        let providerItem = NSMenuItem(title: "Provider", action: nil, keyEquivalent: "")
        let providerMenu = NSMenu()
        for (i, provider) in AgentProvider.allCases.enumerated() {
            let item = NSMenuItem(title: provider.displayName, action: #selector(switchProvider(_:)), keyEquivalent: "")
            item.tag = i
            item.state = provider == AgentProvider.current ? .on : .off
            providerMenu.addItem(item)
        }
        providerMenu.addItem(.separator())
        let configOCItem = NSMenuItem(title: "Configure OpenClaw…", action: #selector(configureOpenClaw(_:)), keyEquivalent: "")
        providerMenu.addItem(configOCItem)
        providerItem.submenu = providerMenu
        menu.addItem(providerItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
        menu.addItem(quitItem)

        statusItem?.menu = menu
        mainMenu = menu
    }

    // MARK: - Menu Actions

    @objc func switchTheme(_ sender: NSMenuItem) {
        let idx = sender.tag
        guard idx < PopoverTheme.allThemes.count else { return }
        PopoverTheme.current = PopoverTheme.allThemes[idx]

        if let themeMenu = sender.menu {
            for item in themeMenu.items {
                item.state = item.tag == idx ? .on : .off
            }
        }

        controller?.characters.forEach { char in
            let wasOpen = char.isIdleForPopover
            if wasOpen { char.popoverWindow?.orderOut(nil) }
            char.popoverWindow = nil
            char.terminalView = nil
            char.thinkingBubbleWindow = nil
            if wasOpen {
                char.createPopoverWindow()
                if let session = char.session, !session.history.isEmpty {
                    char.terminalView?.replayHistory(session.history)
                }
                char.updatePopoverPosition()
                char.popoverWindow?.orderFrontRegardless()
                char.popoverWindow?.makeKey()
                if let terminal = char.terminalView {
                    char.popoverWindow?.makeFirstResponder(terminal.inputField)
                }
            }
        }
    }

    @objc func switchProvider(_ sender: NSMenuItem) {
        let idx = sender.tag
        let allProviders = AgentProvider.allCases
        guard idx < allProviders.count else { return }
        AgentProvider.current = allProviders[idx]

        if let providerMenu = sender.menu {
            for item in providerMenu.items {
                item.state = item.tag == idx ? .on : .off
            }
        }

        // Terminate existing sessions and clear UI so title/placeholder update
        controller?.characters.forEach { char in
            char.session?.terminate()
            char.session = nil
            if char.isIdleForPopover {
                char.closePopover()
            }
            // Always clear popover/bubble so they rebuild with new provider title/placeholder
            char.popoverWindow?.orderOut(nil)
            char.popoverWindow = nil
            char.terminalView = nil
            char.thinkingBubbleWindow?.orderOut(nil)
            char.thinkingBubbleWindow = nil
        }
    }

    @objc func switchDisplay(_ sender: NSMenuItem) {
        let idx = sender.tag
        controller?.pinnedScreenIndex = idx

        if let displayMenu = sender.menu {
            for item in displayMenu.items {
                item.state = item.tag == idx ? .on : .off
            }
        }
    }

    // MARK: - Per-character actions

    private func character(at index: Int) -> WalkerCharacter? {
        guard let chars = controller?.characters, index < chars.count else { return nil }
        return chars[index]
    }

    @objc func toggleCharVisibility(_ sender: NSMenuItem) {
        guard let char = character(at: sender.tag) else { return }
        let nowVisible = !char.isManuallyVisible
        char.setManuallyVisible(nowVisible)
        sender.state = nowVisible ? .on : .off
    }

    @objc func toggleMovingMode(_ sender: NSMenuItem) {
        guard let char = character(at: sender.tag) else { return }
        char.isMovingMode.toggle()
        sender.state = char.isMovingMode ? .on : .off
        char.savePreferences()
    }

    @objc func setCustomImage(_ sender: NSMenuItem) {
        let idx = sender.tag
        guard let char = character(at: idx) else { return }
        let panel = NSOpenPanel()
        panel.title = "Choose a custom character image"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [UTType.png, UTType.gif, UTType.jpeg]
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else { return }
            char.setCustomImage(url: url)
            self?.charRemoveImageItems[idx]?.isEnabled = true
        }
    }

    @objc func removeCustomImage(_ sender: NSMenuItem) {
        guard let char = character(at: sender.tag) else { return }
        char.removeCustomImage()
        sender.isEnabled = false
    }

    @objc func charMirrorImage(_ sender: NSMenuItem) {
        let idx = sender.tag
        guard let char = character(at: idx) else { return }
        char.mirrorImage.toggle()
        sender.state = char.mirrorImage ? .on : .off
        char.updateFlip()
        char.savePreferences()
    }

    @objc func toggleDebug(_ sender: NSMenuItem) {
        guard let debugWin = controller?.debugWindow else { return }
        if debugWin.isVisible {
            debugWin.orderOut(nil)
            sender.state = .off
        } else {
            debugWin.orderFrontRegardless()
            sender.state = .on
        }
    }

    @objc func toggleSounds(_ sender: NSMenuItem) {
        WalkerCharacter.soundsEnabled.toggle()
        sender.state = WalkerCharacter.soundsEnabled ? .on : .off
    }

    // MARK: - Smart Suggestions Actions

    @objc func setContextTimer(_ sender: NSMenuItem) {
        guard let seconds = sender.representedObject as? TimeInterval else { return }
        AppContextSettings.timerDuration = seconds
        if let timerMenu = sender.menu {
            for item in timerMenu.items { item.state = .off }
        }
        sender.state = .on
    }

    @objc func toggleAppRule(_ sender: NSMenuItem) {
        guard let ruleId = sender.representedObject as? String else { return }
        let newState = sender.state != .on
        AppContextSettings.setRuleEnabled(ruleId, enabled: newState)
        sender.state = newState ? .on : .off
    }

    // MARK: - Dynamic Agent Actions

    @objc func addAgent(_ sender: NSMenuItem) {
        let panel = NSOpenPanel()
        panel.title = "Choose agent image"
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.png, .gif, .jpeg]
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url, let self = self else { return }
            guard let newChar = self.controller?.addAgent(imageURL: url) else { return }
            DispatchQueue.main.async {
                self.insertDynamicAgentMenuItem(for: newChar)
            }
        }
    }

    @objc func removeDynamicAgent(_ sender: NSMenuItem) {
        let idx = sender.tag
        controller?.removeAgent(at: idx)
        rebuildDynamicAgentMenuItems()
    }

    private func rebuildDynamicAgentMenuItems() {
        guard let menu = mainMenu else { return }
        for item in dynamicAgentMenuItems {
            charRemoveImageItems.removeValue(forKey: item.tag)
            menu.removeItem(item)
        }
        dynamicAgentMenuItems.removeAll()
        if let extras = controller?.characters.dropFirst(2) {
            for char in extras { insertDynamicAgentMenuItem(for: char) }
        }
    }

    private func insertDynamicAgentMenuItem(for char: WalkerCharacter) {
        guard let menu = mainMenu else { return }
        let idx = char.characterIndex

        // Insert right after Miki and any previously added dynamic agents
        let insertPosition = charMenuItems.count + dynamicAgentMenuItems.count

        let n = char.personaName.trimmingCharacters(in: .whitespacesAndNewlines)
        let title = n.isEmpty ? char.defaultDisplayName : n
        let agentItem = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let agentMenu = NSMenu()

        // Visibility & movement
        let visItem = NSMenuItem(title: "Visible", action: #selector(toggleCharVisibility(_:)), keyEquivalent: "")
        visItem.tag = idx
        visItem.state = char.isManuallyVisible ? .on : .off
        agentMenu.addItem(visItem)

        let movingItem = NSMenuItem(title: "Moving", action: #selector(toggleMovingMode(_:)), keyEquivalent: "")
        movingItem.tag = idx
        movingItem.state = char.isMovingMode ? .on : .off
        agentMenu.addItem(movingItem)

        agentMenu.addItem(makeSpeedSliderItem(for: idx))

        agentMenu.addItem(.separator())

        // Custom image
        let setImgItem = NSMenuItem(title: "Set Custom Image…", action: #selector(setCustomImage(_:)), keyEquivalent: "")
        setImgItem.tag = idx
        agentMenu.addItem(setImgItem)

        let removeImgItem = NSMenuItem(title: "Remove Custom Image", action: #selector(removeCustomImage(_:)), keyEquivalent: "")
        removeImgItem.tag = idx
        removeImgItem.isEnabled = char.customImageURL != nil
        agentMenu.addItem(removeImgItem)
        charRemoveImageItems[idx] = removeImgItem

        let mirrorItem = NSMenuItem(title: "Mirror Image (faces left by default)", action: #selector(charMirrorImage(_:)), keyEquivalent: "")
        mirrorItem.tag = idx
        mirrorItem.state = char.mirrorImage ? .on : .off
        agentMenu.addItem(mirrorItem)

        agentMenu.addItem(.separator())

        // Persona
        let personaItem = NSMenuItem(title: "Configure Persona…", action: #selector(configurePersona(_:)), keyEquivalent: "")
        personaItem.tag = idx
        agentMenu.addItem(personaItem)

        agentMenu.addItem(.separator())

        // Remove
        let removeAgentItem = NSMenuItem(title: "Remove Agent", action: #selector(removeDynamicAgent(_:)), keyEquivalent: "")
        removeAgentItem.tag = idx
        agentMenu.addItem(removeAgentItem)

        agentItem.submenu = agentMenu
        agentItem.tag = idx

        menu.insertItem(agentItem, at: insertPosition)
        dynamicAgentMenuItems.append(agentItem)
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Persona Configuration (per-character)

    private var personaPanel: NSPanel?
    private var personaEditingIndex: Int = 0
    private weak var personaNameField: NSTextField?
    private weak var personaDescView: NSTextView?

    @objc func configurePersona(_ sender: NSMenuItem) {
        let idx = sender.tag
        guard let char = character(at: idx) else { return }

        // Reuse open panel if it's for the same character
        if let existing = personaPanel, existing.isVisible, personaEditingIndex == idx {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        personaPanel?.close()
        personaEditingIndex = idx

        let n = char.personaName.trimmingCharacters(in: .whitespacesAndNewlines)
        let charName = n.isEmpty ? char.defaultDisplayName : n
        let panelW: CGFloat = 360
        let panelH: CGFloat = 250

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelW, height: panelH),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "\(charName) — Persona"
        panel.isFloatingPanel = true
        panel.center()

        let container = NSView(frame: NSRect(x: 0, y: 0, width: panelW, height: panelH))

        // Name field
        let nameLabel = NSTextField(labelWithString: "Name")
        nameLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        nameLabel.frame = NSRect(x: 20, y: 195, width: 320, height: 16)
        container.addSubview(nameLabel)

        let nameField = NSTextField(frame: NSRect(x: 20, y: 168, width: 320, height: 22))
        nameField.placeholderString = "默认：\(charName)"
        nameField.stringValue = char.personaName
        nameField.tag = 300
        container.addSubview(nameField)
        personaNameField = nameField

        // Personality description
        let descLabel = NSTextField(labelWithString: "Personality")
        descLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        descLabel.frame = NSRect(x: 20, y: 142, width: 320, height: 16)
        container.addSubview(descLabel)

        let scrollView = NSScrollView(frame: NSRect(x: 20, y: 60, width: 320, height: 78))
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        let descField = NSTextView(frame: NSRect(x: 0, y: 0, width: 320, height: 78))
        descField.string = char.personaDescription
        descField.font = .systemFont(ofSize: 12)
        descField.isEditable = true
        descField.isRichText = false
        personaDescView = descField
        scrollView.documentView = descField
        container.addSubview(scrollView)

        let hint = NSTextField(labelWithString: "例如：直接坦率，有点毒舌但很关心我，说话轻松随意")
        hint.font = .systemFont(ofSize: 10)
        hint.textColor = .secondaryLabelColor
        hint.frame = NSRect(x: 20, y: 40, width: 320, height: 16)
        container.addSubview(hint)

        // Save button
        let saveBtn = NSButton(title: "Save", target: self, action: #selector(savePersona(_:)))
        saveBtn.bezelStyle = .rounded
        saveBtn.keyEquivalent = "\r"
        saveBtn.frame = NSRect(x: panelW - 100, y: 12, width: 80, height: 22)
        container.addSubview(saveBtn)

        panel.contentView = container
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        personaPanel = panel
    }

    @objc func savePersona(_ sender: NSButton) {
        let idx = personaEditingIndex
        guard let char = character(at: idx) else { return }

        if let nameField = personaNameField {
            char.personaName = nameField.stringValue
        }
        if let descField = personaDescView {
            char.personaDescription = descField.string
        }
        char.savePreferences()

        // Sync menu bar item title
        let n = char.personaName.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayName = n.isEmpty ? char.defaultDisplayName : n
        if idx < charMenuItems.count {
            charMenuItems[idx].title = displayName
        }
        dynamicAgentMenuItems.first { $0.tag == idx }?.title = displayName

        // Restart session so persona takes effect immediately
        char.session?.terminate()
        char.session = nil
        if char.isIdleForPopover { char.closePopover() }

        personaPanel?.close()
        personaPanel = nil
    }

    // MARK: - OpenClaw Configuration

    private var openClawPanel: NSPanel?
    private weak var ocURLField: NSTextField?
    private weak var ocTokenField: NSTextField?
    private weak var ocAgentPopup: NSPopUpButton?

    @objc func configureOpenClaw(_ sender: NSMenuItem) {
        if let existing = openClawPanel, existing.isVisible {
            existing.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }
        openClawPanel?.close()

        let panelW: CGFloat = 400
        let panelH: CGFloat = 200

        let panel = NSPanel(
            contentRect: NSRect(x: 0, y: 0, width: panelW, height: panelH),
            styleMask: [.titled, .closable, .utilityWindow],
            backing: .buffered,
            defer: false
        )
        panel.title = "OpenClaw Configuration"
        panel.isFloatingPanel = true
        panel.center()

        let container = NSView(frame: NSRect(x: 0, y: 0, width: panelW, height: panelH))

        // URL row
        let urlLabel = NSTextField(labelWithString: "Gateway URL")
        urlLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        urlLabel.frame = NSRect(x: 20, y: 155, width: 360, height: 16)
        container.addSubview(urlLabel)

        let urlField = NSTextField(frame: NSRect(x: 20, y: 130, width: 360, height: 22))
        urlField.placeholderString = "http://localhost:18789"
        urlField.stringValue = AgentProvider.openClawBaseURL
        container.addSubview(urlField)
        ocURLField = urlField

        // Agent row
        let agentLabel = NSTextField(labelWithString: "Agent")
        agentLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        agentLabel.frame = NSRect(x: 20, y: 104, width: 80, height: 16)
        container.addSubview(agentLabel)

        let agentPopup = NSPopUpButton(frame: NSRect(x: 20, y: 80, width: 250, height: 22))
        agentPopup.addItem(withTitle: AgentProvider.openClawAgentID)
        container.addSubview(agentPopup)
        ocAgentPopup = agentPopup

        let refreshBtn = NSButton(title: "↺ Fetch", target: self, action: #selector(fetchOpenClawAgents(_:)))
        refreshBtn.bezelStyle = .rounded
        refreshBtn.frame = NSRect(x: 280, y: 80, width: 100, height: 22)
        container.addSubview(refreshBtn)

        // Token row
        let tokenLabel = NSTextField(labelWithString: "Token (optional)")
        tokenLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        tokenLabel.frame = NSRect(x: 20, y: 55, width: 360, height: 16)
        container.addSubview(tokenLabel)

        let tokenField = NSTextField(frame: NSRect(x: 20, y: 32, width: 360, height: 22))
        tokenField.placeholderString = "Auto-detected from ~/.openclaw/openclaw.json"
        tokenField.stringValue = AgentProvider.openClawToken
        // Show auto-detected token as placeholder hint if not manually set
        if AgentProvider.openClawToken.isEmpty {
            let detected = OpenClawSession.resolvedToken()
            if !detected.isEmpty {
                tokenField.placeholderString = "Auto-detected: \(String(detected.prefix(12)))…"
            }
        }
        container.addSubview(tokenField)
        ocTokenField = tokenField

        // Save button
        let saveBtn = NSButton(title: "Save", target: self, action: #selector(saveOpenClawConfig(_:)))
        saveBtn.bezelStyle = .rounded
        saveBtn.keyEquivalent = "\r"
        saveBtn.frame = NSRect(x: panelW - 100, y: 6, width: 80, height: 22)
        container.addSubview(saveBtn)

        panel.contentView = container
        panel.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        openClawPanel = panel

        // Auto-fetch agents after panel opens
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.fetchOpenClawAgents(refreshBtn)
        }
    }

    @objc func fetchOpenClawAgents(_ sender: NSButton) {
        let baseURL = ocURLField?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
                      ?? AgentProvider.openClawBaseURL
        guard let url = URL(string: "\(baseURL)/v1/models") else { return }

        var request = URLRequest(url: url, timeoutInterval: 5)
        request.setValue("operator.read", forHTTPHeaderField: "x-openclaw-scopes")
        let token = ocTokenField?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let resolvedToken = token.isEmpty ? OpenClawSession.resolvedToken() : token
        if !resolvedToken.isEmpty { request.setValue("Bearer \(resolvedToken)", forHTTPHeaderField: "Authorization") }

        sender.isEnabled = false
        URLSession.shared.dataTask(with: request) { [weak self] data, _, _ in
            DispatchQueue.main.async {
                sender.isEnabled = true
                guard let self, let data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let models = json["data"] as? [[String: Any]] else { return }
                let ids = models.compactMap { $0["id"] as? String }
                guard !ids.isEmpty, let popup = self.ocAgentPopup else { return }
                let current = popup.titleOfSelectedItem ?? AgentProvider.openClawAgentID
                popup.removeAllItems()
                popup.addItems(withTitles: ids)
                if ids.contains(current) { popup.selectItem(withTitle: current) }
            }
        }.resume()
    }

    @objc func saveOpenClawConfig(_ sender: NSButton) {
        let url = ocURLField?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !url.isEmpty { AgentProvider.openClawBaseURL = url }

        if let agentID = ocAgentPopup?.titleOfSelectedItem, !agentID.isEmpty {
            AgentProvider.openClawAgentID = agentID
        }
        AgentProvider.openClawToken = ocTokenField?.stringValue.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // Restart any active openclaw sessions so new config takes effect
        if AgentProvider.current == .openclaw {
            controller?.characters.forEach { char in
                char.session?.terminate()
                char.session = nil
                if char.isIdleForPopover { char.closePopover() }
            }
        }

        openClawPanel?.close()
        openClawPanel = nil
    }
}

extension AppDelegate: NSMenuDelegate {}

// MARK: - Speed Slider Support

/// NSSlider subclass that carries its associated character index.
private class SpeedSlider: NSSlider {
    var characterIndex: Int = 0
}

extension AppDelegate {
    /// Builds an NSMenuItem containing a labelled speed slider for the given character.
    func makeSpeedSliderItem(for idx: Int) -> NSMenuItem {
        let char = controller?.characters.first { $0.characterIndex == idx }
        let initial = char?.wanderSpeedMultiplier ?? 1.0

        // Container view
        let view = NSView(frame: NSRect(x: 0, y: 0, width: 230, height: 38))

        // "Speed" label
        let label = NSTextField(labelWithString: "Speed")
        label.frame = NSRect(x: 14, y: 10, width: 40, height: 18)
        label.font = NSFont.systemFont(ofSize: 13)
        view.addSubview(label)

        // Slider (0.25x … 3x)
        let slider = SpeedSlider(frame: NSRect(x: 58, y: 10, width: 120, height: 18))
        slider.characterIndex = idx
        slider.minValue = 0.25
        slider.maxValue = 3.0
        slider.doubleValue = Double(initial)
        slider.isContinuous = true
        slider.target = self
        slider.action = #selector(speedSliderChanged(_:))
        view.addSubview(slider)

        // Value label  "1.0×"
        let valueLabel = NSTextField(labelWithString: formatSpeed(initial))
        valueLabel.frame = NSRect(x: 182, y: 10, width: 38, height: 18)
        valueLabel.font = NSFont.systemFont(ofSize: 12)
        valueLabel.alignment = .right
        valueLabel.tag = idx   // reuse tag so we can update it
        view.addSubview(valueLabel)

        // Store the value label for later updates via objc association
        objc_setAssociatedObject(slider, &AppDelegate.valueLabelKey, valueLabel, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        let item = NSMenuItem()
        item.view = view
        item.tag = idx
        return item
    }

    private static var valueLabelKey = "speedValueLabel"

    @objc func speedSliderChanged(_ sender: NSSlider) {
        guard let slider = sender as? SpeedSlider else { return }
        let multiplier = CGFloat(slider.doubleValue)
        // Update value label
        if let lbl = objc_getAssociatedObject(slider, &AppDelegate.valueLabelKey) as? NSTextField {
            lbl.stringValue = formatSpeed(multiplier)
        }
        // Apply to character
        guard let char = controller?.characters.first(where: { $0.characterIndex == slider.characterIndex }) else { return }
        char.wanderSpeedMultiplier = multiplier
        // If currently moving, rescale existing velocity immediately so change is felt right away
        if char.isMovingMode {
            let mag = sqrt(char.wanderTargetVelocity.x * char.wanderTargetVelocity.x +
                           char.wanderTargetVelocity.y * char.wanderTargetVelocity.y)
            if mag > 0 {
                let targetMag = 60.0 * multiplier  // base 60 px/s × multiplier
                let scale = targetMag / mag
                char.wanderTargetVelocity.x *= scale
                char.wanderTargetVelocity.y *= scale
                char.wanderVelocity.x *= scale
                char.wanderVelocity.y *= scale
            }
        }
        char.savePreferences()
    }

    private func formatSpeed(_ v: CGFloat) -> String {
        String(format: "%.2g×", v)
    }
}
