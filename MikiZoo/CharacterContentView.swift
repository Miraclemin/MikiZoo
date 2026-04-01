import AppKit

class KeyableWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

class CharacterContentView: NSView {
    weak var character: WalkerCharacter?

    // Long-press / drag state
    private var mouseDownDate: Date?
    private var longPressTimer: Timer?
    private var isInDragMode = false
    private var dragStartMousePos: CGPoint = .zero
    private var dragStartWindowPos: CGPoint = .zero

    override func hitTest(_ point: NSPoint) -> NSView? {
        let localPoint = convert(point, from: superview)
        guard bounds.contains(localPoint) else { return nil }

        // For custom image characters (static PNG/GIF), skip screen capture.
        // CGWindowListCreateImage can return transparent pixels for newly-shown
        // windows before the compositor has rendered the first frame, causing all
        // clicks to be rejected. Instead use a generous center-80% hit region.
        if character?.imageDisplayLayer != nil {
            let insetX = bounds.width * 0.1
            let insetY = bounds.height * 0.1
            let hitRect = bounds.insetBy(dx: insetX, dy: insetY)
            return hitRect.contains(localPoint) ? self : nil
        }

        // AVPlayerLayer is GPU-rendered so layer.render(in:) won't capture video pixels.
        // Use CGWindowListCreateImage to sample actual on-screen alpha at click point.
        let screenPoint = window?.convertPoint(toScreen: convert(localPoint, to: nil)) ?? .zero
        guard let primaryScreen = NSScreen.screens.first else { return nil }
        let flippedY = primaryScreen.frame.height - screenPoint.y

        let captureRect = CGRect(x: screenPoint.x - 0.5, y: flippedY - 0.5, width: 1, height: 1)
        guard let windowID = window?.windowNumber, windowID > 0 else { return nil }

        if let image = CGWindowListCreateImage(
            captureRect,
            .optionIncludingWindow,
            CGWindowID(windowID),
            [.boundsIgnoreFraming, .bestResolution]
        ) {
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            var pixel: [UInt8] = [0, 0, 0, 0]
            if let ctx = CGContext(
                data: &pixel, width: 1, height: 1,
                bitsPerComponent: 8, bytesPerRow: 4,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ) {
                ctx.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))
                if pixel[3] > 30 { return self }
                return nil
            }
        }

        // Fallback: accept click if within center 60% of the view
        let insetX = bounds.width * 0.2
        let insetY = bounds.height * 0.15
        let hitRect = bounds.insetBy(dx: insetX, dy: insetY)
        return hitRect.contains(localPoint) ? self : nil
    }

    // MARK: - Mouse Events

    override func mouseDown(with event: NSEvent) {
        mouseDownDate = Date()
        isInDragMode = false
        dragStartMousePos = NSEvent.mouseLocation
        dragStartWindowPos = window?.frame.origin ?? .zero

        longPressTimer?.invalidate()
        longPressTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { [weak self] _ in
            guard let self = self, self.mouseDownDate != nil else { return }
            self.isInDragMode = true
            NSCursor.closedHand.push()
        }
    }

    override func mouseDragged(with event: NSEvent) {
        guard isInDragMode, let win = window else { return }
        let current = NSEvent.mouseLocation
        let newOrigin = CGPoint(
            x: dragStartWindowPos.x + current.x - dragStartMousePos.x,
            y: dragStartWindowPos.y + current.y - dragStartMousePos.y
        )
        win.setFrameOrigin(newOrigin)
        character?.isDragMode = true
    }

    override func mouseUp(with event: NSEvent) {
        longPressTimer?.invalidate()
        longPressTimer = nil

        if isInDragMode {
            NSCursor.pop()
            isInDragMode = false
            character?.isDragMode = false
            character?.savePreferences()  // save new position
        } else if mouseDownDate != nil {
            character?.handleClick()
        }
        mouseDownDate = nil
    }
}
