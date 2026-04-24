// LINESSViewBrown.swift
// Replacement for the original LINE Brown screen saver (2017 x86_64 binary).
// Rebuilt to support Apple Silicon (arm64) and macOS 13+.
//
// This ScreenSaverView subclass loads video.mp4 from its bundle Resources
// and plays it looped using AVPlayerLayer — exactly what the original did.

import ScreenSaver
import AVFoundation

@objc(LINESSViewBrown)
final class LINESSViewBrown: ScreenSaverView {

    // MARK: – Private state

    private var playerLayer: AVPlayerLayer?
    private var player: AVPlayer?
    private var loopObserver: NSObjectProtocol?

    // MARK: – Init

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        wantsLayer = true
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        wantsLayer = true
    }

    deinit {
        tearDownPlayer()
    }

    // MARK: – ScreenSaverView lifecycle

    override func startAnimation() {
        super.startAnimation()
        setUpPlayer()
        player?.play()
    }

    override func stopAnimation() {
        super.stopAnimation()
        player?.pause()
        tearDownPlayer()
    }

    /// animateOneFrame is called by the ScreenSaver framework on a timer.
    /// AVPlayer drives itself, so nothing extra is needed here.
    override func animateOneFrame() {}

    override func hasConfigureSheet() -> Bool { false }
    override var configureSheet: NSWindow? { nil }

    // MARK: – Layout

    override func layout() {
        super.layout()
        playerLayer?.frame = bounds
    }

    // MARK: – Private helpers

    private func setUpPlayer() {
        guard playerLayer == nil else { return }

        // Locate video.mp4 inside this bundle's Resources folder.
        guard
            let bundle = Bundle(for: type(of: self)),
            let url = bundle.url(forResource: "video", withExtension: "mp4")
        else {
            NSLog("[LINEScreenSaver] Could not find video.mp4 in bundle resources.")
            return
        }

        NSLog("[LINEScreenSaver] Loading video from %@", url.path)

        let item = AVPlayerItem(url: url)
        let avPlayer = AVPlayer(playerItem: item)
        avPlayer.actionAtItemEnd = .none   // we handle looping ourselves
        avPlayer.isMuted = true            // screen savers are silent by default

        let layer = AVPlayerLayer(player: avPlayer)
        layer.frame = bounds
        layer.videoGravity = .resizeAspectFill
        layer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]

        self.layer?.addSublayer(layer)
        self.playerLayer = layer
        self.player = avPlayer

        // Loop: when playback reaches the end, seek back to zero.
        loopObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak avPlayer] _ in
            avPlayer?.seek(to: .zero)
            avPlayer?.play()
        }
    }

    private func tearDownPlayer() {
        if let obs = loopObserver {
            NotificationCenter.default.removeObserver(obs)
            loopObserver = nil
        }
        playerLayer?.removeFromSuperlayer()
        playerLayer = nil
        player = nil
    }
}
