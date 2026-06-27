import AVFoundation
import AppKit
import SwiftUI

struct LockedVideoBackground: NSViewRepresentable {
    final class PlayerView: NSView {
        let playerLayer = AVPlayerLayer()

        override init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            wantsLayer = true
            layer = playerLayer
            playerLayer.videoGravity = .resizeAspectFill
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) { nil }

        override func layout() {
            super.layout()
            playerLayer.frame = bounds
        }

        override func hitTest(_ point: NSPoint) -> NSView? { nil }
    }

    final class Coordinator {
        var looper: AVPlayerLooper?
        var player: AVQueuePlayer?
    }

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeNSView(context: Context) -> PlayerView {
        let view = PlayerView()
        guard let url = Bundle.main.url(forResource: "Lockedvid", withExtension: "mp4") else {
            return view
        }

        let player = AVQueuePlayer()
        let item = AVPlayerItem(url: url)
        context.coordinator.player = player
        context.coordinator.looper = AVPlayerLooper(player: player, templateItem: item)
        view.playerLayer.player = player
        player.isMuted = true
        player.play()
        return view
    }

    func updateNSView(_ nsView: PlayerView, context: Context) {}
}
