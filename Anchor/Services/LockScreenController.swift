import AVFoundation
import AVKit
import AppKit

struct BlockOverlayContentModel {
    let blockedName: String
    let quote: BlockQuote
    let sessionSubtitle: String
}

@MainActor
final class LockScreenController {
    static let shared = LockScreenController()

    private var window: NSWindow?
    private var player: AVQueuePlayer?
    private var looper: AVPlayerLooper?
    private var onDismiss: (() -> Void)?
    private var targetBundleID: String?
    private var frameTimer: Timer?
    private(set) var isVisible = false

    private init() {}

    func show(
        model: BlockOverlayContentModel,
        targetBundleID: String,
        onDismiss: @escaping () -> Void
    ) {
        self.onDismiss = onDismiss
        self.targetBundleID = targetBundleID

        let frame = BrowserWindowTracker.frontWindowFrame(forBundleID: targetBundleID)
            ?? defaultFallbackFrame()

        if isVisible {
            window?.setFrame(frame, display: true)
            window?.orderFrontRegardless()
            return
        }

        isVisible = true
        let overlay = makeWindow(frame: frame, model: model)
        window = overlay
        overlay.orderFrontRegardless()
        startFrameTracking()
    }

    func hide() {
        guard isVisible else { return }
        isVisible = false
        onDismiss = nil
        targetBundleID = nil
        frameTimer?.invalidate()
        frameTimer = nil
        player?.pause()
        player = nil
        looper = nil
        window?.orderOut(nil)
        window = nil
    }

    @objc private func dismissTapped() {
        onDismiss?()
    }

    private func startFrameTracking() {
        frameTimer?.invalidate()
        frameTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.syncFrame()
            }
        }
        if let frameTimer {
            RunLoop.main.add(frameTimer, forMode: .common)
        }
    }

    func syncToBrowser(_ bundleID: String) {
        targetBundleID = bundleID
        syncFrame()
        window?.orderFrontRegardless()
    }

    private func syncFrame() {
        guard isVisible, let bundleID = targetBundleID else { return }

        guard NSRunningApplication.runningApplications(withBundleIdentifier: bundleID).first != nil else {
            hide()
            return
        }

        if let frame = BrowserWindowTracker.frontWindowFrame(forBundleID: bundleID) {
            window?.setFrame(frame, display: true)
            window?.orderFrontRegardless()
        }
    }

    private func defaultFallbackFrame() -> CGRect {
        let screen = NSScreen.main ?? NSScreen.screens.first!
        let f = screen.visibleFrame
        return CGRect(x: f.midX - 420, y: f.midY - 280, width: 840, height: 560)
    }

    private func makeWindow(frame: CGRect, model: BlockOverlayContentModel) -> NSWindow {
        let overlay = NSWindow(
            contentRect: frame,
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        overlay.isOpaque = true
        overlay.backgroundColor = .black
        overlay.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.floatingWindow)) + 3)
        overlay.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        overlay.ignoresMouseEvents = false
        overlay.hasShadow = true
        overlay.contentView = buildContentView(model: model, size: frame.size)
        return overlay
    }

    private func buildContentView(model: BlockOverlayContentModel, size: CGSize) -> NSView {
        let root = NSView(frame: NSRect(origin: .zero, size: size))
        root.wantsLayer = true
        root.layer?.backgroundColor = NSColor.black.cgColor

        if let url = lockedVideoURL {
            let queue = AVQueuePlayer()
            let item = AVPlayerItem(url: url)
            looper = AVPlayerLooper(player: queue, templateItem: item)
            queue.isMuted = true
            queue.play()
            player = queue

            let playerView = AVPlayerView()
            playerView.player = queue
            playerView.controlsStyle = .none
            playerView.videoGravity = .resizeAspectFill
            playerView.frame = root.bounds
            playerView.autoresizingMask = [.width, .height]
            root.addSubview(playerView)
        }

        let gradient = CAGradientLayer()
        gradient.colors = [
            NSColor.clear.cgColor,
            NSColor(red: 0.008, green: 0.024, blue: 0.045, alpha: 0.75).cgColor,
            NSColor(red: 0.008, green: 0.024, blue: 0.045, alpha: 0.92).cgColor,
        ]
        gradient.locations = [0, 0.45, 1]
        gradient.frame = root.bounds
        let gradientHost = NSView(frame: root.bounds)
        gradientHost.wantsLayer = true
        gradientHost.layer?.addSublayer(gradient)
        gradientHost.autoresizingMask = [.width, .height]
        root.addSubview(gradientHost)

        let quoteStack = NSStackView()
        quoteStack.orientation = .vertical
        quoteStack.alignment = .centerX
        quoteStack.spacing = 10
        quoteStack.translatesAutoresizingMaskIntoConstraints = false

        quoteStack.addArrangedSubview(makeLabel("BLOCKED APP", size: 9, color: .secondaryLabelColor))
        quoteStack.addArrangedSubview(makeLabel(model.blockedName, size: min(22, size.width / 14), color: .white, weight: .semibold))
        quoteStack.addArrangedSubview(makeLabel("\"\(model.quote.text)\"", size: min(18, size.width / 18), color: .white, maxWidth: size.width * 0.85))
        quoteStack.addArrangedSubview(makeLabel("— \(model.quote.attribution.uppercased())", size: 10, color: .secondaryLabelColor))
        quoteStack.addArrangedSubview(makeLabel(model.sessionSubtitle, size: 12, color: .tertiaryLabelColor))

        root.addSubview(quoteStack)

        let button = NSButton(title: "Return to what matters", target: self, action: #selector(dismissTapped))
        button.bezelStyle = .rounded
        button.controlSize = .regular
        button.font = NSFont.systemFont(ofSize: 14, weight: .semibold)
        button.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(button)

        let hint = makeLabel("Press Esc · or switch tabs", size: 10, color: .tertiaryLabelColor)
        hint.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(hint)

        NSLayoutConstraint.activate([
            quoteStack.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            quoteStack.centerYAnchor.constraint(equalTo: root.centerYAnchor, constant: -20),
            quoteStack.widthAnchor.constraint(lessThanOrEqualTo: root.widthAnchor, multiplier: 0.9),
            button.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            button.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -48),
            hint.centerXAnchor.constraint(equalTo: root.centerXAnchor),
            hint.topAnchor.constraint(equalTo: button.bottomAnchor, constant: 8),
        ])

        return root
    }

    private func makeLabel(
        _ text: String,
        size: CGFloat,
        color: NSColor,
        weight: NSFont.Weight = .regular,
        maxWidth: CGFloat? = nil
    ) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = NSFont.systemFont(ofSize: size, weight: weight)
        field.textColor = color
        field.alignment = .center
        field.lineBreakMode = .byWordWrapping
        field.maximumNumberOfLines = 0
        if let maxWidth {
            field.preferredMaxLayoutWidth = maxWidth
            field.widthAnchor.constraint(lessThanOrEqualToConstant: maxWidth).isActive = true
        }
        return field
    }

    private var lockedVideoURL: URL? {
        Bundle.main.url(forResource: "Lockedvid", withExtension: "mp4")
    }
}
