import AppKit

class MikiZooController {
    var characters: [WalkerCharacter] = []
    private var displayLink: CVDisplayLink?
    var debugWindow: NSWindow?
    var pinnedScreenIndex: Int = -1
    private static let onboardingKey = "hasCompletedOnboarding"
    private var isHiddenForEnvironment = false

    let screenObserver = ScreenObserver()
    let triggerEngine  = ProactiveTriggerEngine()

    // MARK: - Dynamic Agent Management

    private static let extraAgentsKey = "extraAgentImagePaths"

    /// Adds a new agent whose sprite is an image at `imageURL`.
    /// The image is copied to Application Support so it persists.
    @discardableResult
    func addAgent(imageURL: URL) -> WalkerCharacter? {
        // Copy image to app support directory so it survives the original being moved/deleted
        let fm = FileManager.default
        guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let agentsDir = appSupport.appendingPathComponent("MikiZoo/ExtraAgents", isDirectory: true)
        try? fm.createDirectory(at: agentsDir, withIntermediateDirectories: true)

        let destURL = agentsDir.appendingPathComponent("\(UUID().uuidString).\(imageURL.pathExtension)")
        try? fm.copyItem(at: imageURL, to: destURL)

        let newChar = makeExtraCharacter(imagePath: destURL.path, index: characters.count)
        characters.append(newChar)
        newChar.controller = self
        // Newly added agents should be visible immediately
        newChar.setManuallyVisible(true)
        newChar.savePreferences()
        saveExtraAgents()
        return newChar
    }

    /// Removes the agent at `index` (must be >= 2 — built-in agents cannot be removed).
    func removeAgent(at index: Int) {
        guard index >= 2, index < characters.count else { return }
        let char = characters[index]
        // Clean up persisted image
        if let saved = UserDefaults.standard.string(forKey: "walkerChar_\(index)_imagePath") {
            try? FileManager.default.removeItem(atPath: saved)
        }
        char.window.orderOut(nil)
        char.proactiveBubbleWindow?.orderOut(nil)
        characters.remove(at: index)
        // Re-index remaining extra characters
        for i in index..<characters.count {
            characters[i].characterIndex = i
        }
        saveExtraAgents()
    }

    func loadExtraAgents() {
        let paths = UserDefaults.standard.stringArray(forKey: Self.extraAgentsKey) ?? []
        for (offset, path) in paths.enumerated() {
            let index = 2 + offset
            let char = makeExtraCharacter(imagePath: path, index: index)
            characters.append(char)
            char.controller = self
        }
    }

    func saveExtraAgents() {
        let paths = characters.dropFirst(2).compactMap { char -> String? in
            UserDefaults.standard.string(forKey: "walkerChar_\(char.characterIndex)_imagePath")
        }
        UserDefaults.standard.set(paths, forKey: Self.extraAgentsKey)
    }

    private func makeExtraCharacter(imagePath: String, index: Int) -> WalkerCharacter {
        let char = WalkerCharacter(videoName: "walk-bruce-01") // fallback video; image overrides
        char.characterIndex = index
        // Assign a distinct RGB accent color (cycles through a palette) so the
        // popover theme can safely call redComponent/greenComponent/blueComponent.
        let palette: [NSColor] = [
            NSColor(red: 0.45, green: 0.55, blue: 1.00, alpha: 1.0), // lavender
            NSColor(red: 1.00, green: 0.65, blue: 0.20, alpha: 1.0), // amber
            NSColor(red: 0.25, green: 0.80, blue: 0.65, alpha: 1.0), // teal
            NSColor(red: 0.90, green: 0.40, blue: 0.60, alpha: 1.0), // rose
            NSColor(red: 0.55, green: 0.85, blue: 0.35, alpha: 1.0), // lime
        ]
        char.characterColor = palette[(index - 2) % palette.count]
        char.accelStart = 3.0
        char.fullSpeedStart = 3.75
        char.decelStart = 8.0
        char.walkStop = 8.5
        char.walkAmountRange = 0.4...0.65
        char.positionProgress = Double.random(in: 0.1...0.9)
        char.pauseEndTime = CACurrentMediaTime() + Double.random(in: 1.0...6.0)
        char.setup()
        // Override with custom image
        let url = URL(fileURLWithPath: imagePath)
        char.setCustomImage(url: url)
        // Spread agent across the central 60% of the screen from the start
        if let screen = NSScreen.main {
            let bounds = screen.frame
            let marginX = bounds.width  * 0.2
            let marginY = bounds.height * 0.2
            let rx = CGFloat.random(in: bounds.minX + marginX ... bounds.maxX - char.effectiveDisplayWidth  - marginX)
            let ry = CGFloat.random(in: bounds.minY + marginY ... bounds.maxY - char.effectiveDisplayHeight - marginY)
            char.window.setFrameOrigin(CGPoint(x: rx, y: ry))
        }
        // Start moving immediately (isMovingMode setter fires kickstartWander since window exists)
        char.isMovingMode = true
        // Persist the image path under a dedicated key so we can restore it
        UserDefaults.standard.set(imagePath, forKey: "walkerChar_\(index)_imagePath")
        return char
    }

    func start() {
        let char1 = WalkerCharacter(videoName: "walk-bruce-01")
        char1.characterIndex = 0
        char1.accelStart = 3.0
        char1.fullSpeedStart = 3.75
        char1.decelStart = 8.0
        char1.walkStop = 8.5
        char1.walkAmountRange = 0.4...0.65

        let char2 = WalkerCharacter(videoName: "walk-jazz-01")
        char2.characterIndex = 1
        char2.accelStart = 3.9
        char2.fullSpeedStart = 4.5
        char2.decelStart = 8.0
        char2.walkStop = 8.75
        char2.walkAmountRange = 0.35...0.6
        char1.yOffset = -3
        char2.yOffset = -7
        char1.characterColor = NSColor(red: 0.4, green: 0.72, blue: 0.55, alpha: 1.0)
        char2.characterColor = NSColor(red: 1.0, green: 0.4, blue: 0.0, alpha: 1.0)

        char1.flipXOffset = 0
        char2.flipXOffset = -9

        char1.positionProgress = 0.3
        char2.positionProgress = 0.7

        char1.pauseEndTime = CACurrentMediaTime() + Double.random(in: 0.5...2.0)
        char2.pauseEndTime = CACurrentMediaTime() + Double.random(in: 8.0...14.0)

        char1.setup()
        char2.setup()

        characters = [char1, char2]
        characters.forEach { $0.controller = self }

        loadExtraAgents()

        // Wire proactive engine
        triggerEngine.controller = self
        screenObserver.engine = triggerEngine
        screenObserver.start()
        ScreenObserver.requestAccessibilityPermissionIfNeeded()

        setupDebugLine()
        startDisplayLink()

        if !UserDefaults.standard.bool(forKey: Self.onboardingKey) {
            triggerOnboarding()
        }
    }

    private func triggerOnboarding() {
        guard let primary = characters.first else { return }
        primary.isOnboarding = true
        // Show "hi!" bubble after a short delay so the character is visible first
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            primary.currentPhrase = "hi!"
            primary.showingCompletion = true
            primary.completionBubbleExpiry = CACurrentMediaTime() + 600 // stays until clicked
            primary.showBubble(text: "hi!", isCompletion: true)
            primary.playCompletionSound()
        }
    }

    func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: Self.onboardingKey)
        characters.forEach { $0.isOnboarding = false }
    }

    // MARK: - Debug

    private func setupDebugLine() {
        let win = NSWindow(contentRect: CGRect(x: 0, y: 0, width: 100, height: 2),
                           styleMask: .borderless, backing: .buffered, defer: false)
        win.isOpaque = false
        win.backgroundColor = NSColor.red
        win.hasShadow = false
        win.level = NSWindow.Level(rawValue: NSWindow.Level.statusBar.rawValue + 10)
        win.ignoresMouseEvents = true
        win.collectionBehavior = [.moveToActiveSpace, .stationary]
        win.orderOut(nil)
        debugWindow = win
    }

    private func updateDebugLine(dockX: CGFloat, dockWidth: CGFloat, dockTopY: CGFloat) {
        guard let win = debugWindow, win.isVisible else { return }
        win.setFrame(CGRect(x: dockX, y: dockTopY, width: dockWidth, height: 2), display: true)
    }

    // MARK: - Dock Geometry

    private func getDockIconArea(screenWidth: CGFloat) -> (x: CGFloat, width: CGFloat) {
        let dockDefaults = UserDefaults(suiteName: "com.apple.dock")
        let tileSize = CGFloat(dockDefaults?.double(forKey: "tilesize") ?? 48)
        // Each dock slot is the icon + padding. The padding scales with tile size.
        // At default 48pt: slot ≈ 58pt. At 37pt: slot ≈ 47pt. Roughly tileSize * 1.25.
        let slotWidth = tileSize * 1.25

        let persistentApps = dockDefaults?.array(forKey: "persistent-apps")?.count ?? 0
        let persistentOthers = dockDefaults?.array(forKey: "persistent-others")?.count ?? 0

        // Only count recent apps if show-recents is enabled
        let showRecents = dockDefaults?.bool(forKey: "show-recents") ?? true
        let recentApps = showRecents ? (dockDefaults?.array(forKey: "recent-apps")?.count ?? 0) : 0
        let totalIcons = persistentApps + persistentOthers + recentApps

        var dividers = 0
        if persistentApps > 0 && (persistentOthers > 0 || recentApps > 0) { dividers += 1 }
        if persistentOthers > 0 && recentApps > 0 { dividers += 1 }
        // show-recents adds its own divider
        if showRecents && recentApps > 0 { dividers += 1 }

        let dividerWidth: CGFloat = 12.0
        var dockWidth = slotWidth * CGFloat(totalIcons) + CGFloat(dividers) * dividerWidth

        let magnificationEnabled = dockDefaults?.bool(forKey: "magnification") ?? false
        if magnificationEnabled,
           let largeSize = dockDefaults?.object(forKey: "largesize") as? CGFloat {
            // Magnification only affects the hovered area; at rest the dock is normal size.
            // Don't inflate the width — characters should stay within the at-rest bounds.
            _ = largeSize
        }

        // Small fudge factor for dock edge padding
        dockWidth *= 1.1
        let dockX = (screenWidth - dockWidth) / 2.0
        return (dockX, dockWidth)
    }

    private func dockAutohideEnabled() -> Bool {
        let dockDefaults = UserDefaults(suiteName: "com.apple.dock")
        return dockDefaults?.bool(forKey: "autohide") ?? false
    }

    // MARK: - Display Link

    private func startDisplayLink() {
        CVDisplayLinkCreateWithActiveCGDisplays(&displayLink)
        guard let displayLink = displayLink else { return }

        let callback: CVDisplayLinkOutputCallback = { _, _, _, _, _, userInfo -> CVReturn in
            let controller = Unmanaged<MikiZooController>.fromOpaque(userInfo!).takeUnretainedValue()
            DispatchQueue.main.async {
                controller.tick()
            }
            return kCVReturnSuccess
        }

        CVDisplayLinkSetOutputCallback(displayLink, callback,
                                       Unmanaged.passUnretained(self).toOpaque())
        CVDisplayLinkStart(displayLink)
    }

    var activeScreen: NSScreen? {
        if pinnedScreenIndex >= 0, pinnedScreenIndex < NSScreen.screens.count {
            return NSScreen.screens[pinnedScreenIndex]
        }
        // Prefer the screen that currently shows the dock (bottom inset in visibleFrame).
        // NSScreen.main changes with keyboard focus and must NOT be used here — clicking a
        // secondary display switches NSScreen.main to that display, causing characters on
        // the dock screen to be incorrectly hidden.
        if let dockScreen = NSScreen.screens.first(where: { screenHasDock($0) }) {
            return dockScreen
        }
        // Dock is auto-hidden: fall back to the primary display, identified as the screen
        // whose menu bar reserves space at the top (visibleFrame.maxY < frame.maxY).
        if let primaryScreen = NSScreen.screens.first(where: { $0.visibleFrame.maxY < $0.frame.maxY }) {
            return primaryScreen
        }
        return NSScreen.screens.first
    }

    /// The dock lives on the screen where visibleFrame.origin.y > frame.origin.y (bottom dock)
    /// On screens without the dock, visibleFrame.origin.y == frame.origin.y
    private func screenHasDock(_ screen: NSScreen) -> Bool {
        return screen.visibleFrame.origin.y > screen.frame.origin.y
    }

    private func shouldShowCharacters(on screen: NSScreen) -> Bool {
        if screenHasDock(screen) {
            return true
        }

        // With dock auto-hide enabled on the active desktop, the dock can still be
        // present even though visibleFrame starts at the screen origin. In fullscreen
        // spaces, both the dock and menu bar are absent, so visibleFrame matches frame.
        let menuBarVisible = screen.visibleFrame.maxY < screen.frame.maxY
        return dockAutohideEnabled() && menuBarVisible
    }

    @discardableResult
    private func updateEnvironmentVisibility(for screen: NSScreen) -> Bool {
        let shouldShow = shouldShowCharacters(on: screen)
        guard shouldShow != !isHiddenForEnvironment else { return shouldShow }

        isHiddenForEnvironment = !shouldShow

        if shouldShow {
            characters.forEach { $0.showForEnvironmentIfNeeded() }
        } else {
            debugWindow?.orderOut(nil)
            characters.forEach { $0.hideForEnvironment() }
        }

        return shouldShow
    }

    func tick() {
        guard let screen = activeScreen else { return }
        guard updateEnvironmentVisibility(for: screen) else { return }

        let activeChars = characters.filter { $0.window.isVisible && $0.isManuallyVisible }

        for char in activeChars {
            char.update(screenBounds: screen.frame)
        }

        let sorted = activeChars.sorted { $0.window.frame.origin.x < $1.window.frame.origin.x }
        for (i, char) in sorted.enumerated() {
            char.window.level = NSWindow.Level(rawValue: NSWindow.Level.floating.rawValue + i)
        }
    }

    deinit {
        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
        }
        screenObserver.stop()
    }
}
