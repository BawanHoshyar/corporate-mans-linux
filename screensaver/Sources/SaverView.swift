// SaverView.swift — the ScreenSaverView the system loads.
// All the visual work lives in SceneRenderer (Scene.swift); this file just
// wires it to the screen-saver lifecycle and feeds it the wall clock.
//
// NSPrincipalClass in Info.plist points at the @objc runtime name below, so it
// MUST stay "CorporateMansLinuxView".

import ScreenSaver
import AppKit

@objc(CorporateMansLinuxView)
final class CorporateMansLinuxView: ScreenSaverView {

    private let scene = SceneRenderer()
    private let startDate = Date()
    private let clockFmt: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    override init?(frame: NSRect, isPreview: Bool) {
        super.init(frame: frame, isPreview: isPreview)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        animationTimeInterval = 1.0 / 30.0
        Fonts.registerBundled(in: Bundle(for: type(of: self)))
        wantsLayer = true
    }

    override func startAnimation() { super.startAnimation() }
    override func stopAnimation()  { super.stopAnimation() }

    override func draw(_ rect: NSRect) {
        guard let ctx = NSGraphicsContext.current?.cgContext else { return }
        let now = Date()
        let elapsed = -startDate.timeIntervalSinceNow          // seconds since load
        scene.render(ctx: ctx,
                     size: bounds.size,
                     time: elapsed,
                     isPreview: isPreview,
                     clockText: clockFmt.string(from: now))
    }

    override func animateOneFrame() {
        super.animateOneFrame()
        setNeedsDisplay(bounds)
    }

    override var hasConfigureSheet: Bool { false }
    override var configureSheet: NSWindow? { nil }
}
