// Scene.swift
// Matte "cyberdeck TUI" renderer for "Corporate Man's Linux".
// A fake terminal: a box-drawing frame with a shell titlebar, a fastfetch-style
// system readout, a large flat clock, and a blinking prompt cursor — drawn in a
// dimmed, desaturated violet phosphor palette. No neon glow, no glitch, no
// synthwave sun/grid; just flat matte type + faint CRT scanlines.
//
// Drawn purely with Core Graphics + AppKit so it runs identically inside the
// sandboxed screen-saver host AND inside the offline PNG preview tool.
//
// Everything is sized relative to the view height (H) so it looks right in a
// tiny System-Settings thumbnail and on a 6K display alike.

import AppKit
import CoreText

// MARK: - Palette (muted violet, matte, desaturated — no neon) ------------------

enum Pal {
    static func hex(_ h: UInt32, _ a: CGFloat = 1) -> NSColor {
        NSColor(srgbRed: CGFloat((h >> 16) & 0xff) / 255.0,
                green:   CGFloat((h >> 8)  & 0xff) / 255.0,
                blue:    CGFloat(h & 0xff)         / 255.0,
                alpha:   a)
    }
    static let bg0    = hex(0x0e0d14)   // background top (faint violet tint)
    static let bg1    = hex(0x090810)   // background bottom
    static let frame  = hex(0x554a73)   // dim violet box-drawing frame
    static let label  = hex(0x6f6690)   // readout labels (dim)
    static let value  = hex(0xb8b1cf)   // readout values (soft lavender-grey)
    static let accent = hex(0x9c8ac6)   // prompt / titlebar (muted violet)
    static let clock  = hex(0xb6a6da)   // clock digits (matte, desaturated)
    static let footer = hex(0x8b7fac)   // trademark footer
    static let scan   = hex(0x000000)   // scanline overlay
}

// MARK: - Fonts ----------------------------------------------------------------

enum Fonts {
    // Register TTFs bundled inside the .saver (needed in the sandbox). No-op if
    // the fonts are already resolvable (e.g. offline tool on a machine that has
    // them installed in ~/Library/Fonts).
    static func registerBundled(in bundle: Bundle) {
        for name in ["JetBrainsMono-ExtraBold", "JetBrainsMono-Bold",
                     "JetBrainsMono-Medium", "JetBrainsMono-Regular"] {
            if let url = bundle.url(forResource: name, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }

    static func mono(_ size: CGFloat, _ ps: String, weight: NSFont.Weight) -> NSFont {
        NSFont(name: ps, size: size)
            ?? NSFont(name: "JetBrains Mono", size: size)
            ?? NSFont.monospacedSystemFont(ofSize: size, weight: weight)
    }
    static func extraBold(_ s: CGFloat) -> NSFont { mono(s, "JetBrainsMono-ExtraBold", weight: .heavy) }
    static func bold(_ s: CGFloat)      -> NSFont { mono(s, "JetBrainsMono-Bold",      weight: .bold) }
    static func medium(_ s: CGFloat)    -> NSFont { mono(s, "JetBrainsMono-Medium",    weight: .medium) }
    static func regular(_ s: CGFloat)   -> NSFont { mono(s, "JetBrainsMono-Regular",   weight: .regular) }
}

// MARK: - Renderer -------------------------------------------------------------

final class SceneRenderer {
    let trademark = "Bawan A. Dawood"   // matches the fastfetch signature footer
    let titlebar  = " bawan@mans-linux:~ "

    // fastfetch-style system readout (label, value).
    private let readout: [(String, String)] = [
        ("host",  "bawan@corporate-mans-linux"),
        ("os",    "macOS 26 \u{00B7} arm64"),
        ("wm",    "AeroSpace \u{00B7} sketchybar \u{00B7} borders"),
        ("shell", "zsh \u{00B7} starship \u{00B7} tmux"),
        ("term",  "Ghostty \u{00B7} JetBrains Mono"),
    ]

    /// Draw one frame. `clockText` is injected so the saver can show wall-clock
    /// time while the offline tool can pass a fixed sample.
    func render(ctx: CGContext, size: NSSize, time: Double, isPreview: Bool, clockText: String) {
        let W = size.width, H = size.height

        background(ctx, W: W, H: H)
        terminal(ctx, W: W, H: H, time: time, clockText: clockText)
        scanlines(ctx, W: W, H: H)
        vignette(ctx, W: W, H: H)
    }

    // MARK: Background (flat matte, whisper of a gradient for depth)

    private func background(_ ctx: CGContext, W: CGFloat, H: CGFloat) {
        let g = NSGradient(colors: [Pal.bg0, Pal.bg1], atLocations: [0.0, 1.0], colorSpace: .sRGB)
        g?.draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: 90)
    }

    // MARK: The terminal window

    private func terminal(_ ctx: CGContext, W: CGFloat, H: CGFloat, time: Double, clockText: String) {
        // Frame geometry — centered box.
        let bx0 = W * 0.20, bx1 = W * 0.80
        let by0 = H * 0.20, by1 = H * 0.80
        let pad = min(W, H) * 0.032
        let lw  = max(1.5, H * 0.0018)

        let bodySize = max(8.0, H * 0.024)
        let bodyF = Fonts.medium(bodySize)
        let boldF = Fonts.bold(bodySize)
        let adv   = advance(bodyF)

        // ── Frame ────────────────────────────────────────────────────────────
        Pal.frame.setStroke()
        let box = NSBezierPath(rect: NSRect(x: bx0, y: by0, width: bx1 - bx0, height: by1 - by0))
        box.lineWidth = lw
        box.stroke()

        // Titlebar text cut into the top border (leading/trailing spaces make the gap).
        cutLabel(titlebar, leftX: bx0 + pad * 1.2, centerY: by1,
                 font: boldF, color: Pal.accent, bg: Pal.bg0)
        // Trademark cut into the bottom border, centered.
        cutLabelCentered("  " + trademark + "  ", cx: W / 2, centerY: by0,
                         font: Fonts.medium(bodySize * 0.92), color: Pal.footer, bg: Pal.bg1)

        // ── Inner content ────────────────────────────────────────────────────
        let innerL = bx0 + pad
        let innerR = bx1 - pad
        let innerB = by0 + pad
        let lh = bodySize * 1.7
        let labelCol = adv * 8            // 8-char label column

        var y = by1 - pad - bodySize * 0.7   // vertical center of the first line

        // Command echo: `❯ fastfetch`
        draw("\u{276F}", leftX: innerL, centerY: y, font: boldF, color: Pal.accent)
        draw("fastfetch", leftX: innerL + adv * 2, centerY: y, font: bodyF, color: Pal.value)
        y -= lh * 1.35

        // Readout rows.
        for (k, v) in readout {
            draw(k, leftX: innerL, centerY: y, font: bodyF, color: Pal.label)
            draw(v, leftX: innerL + labelCol, centerY: y, font: bodyF, color: Pal.value)
            y -= lh
        }

        // Separator rule.
        y -= lh * 0.35
        let rule = NSBezierPath()
        rule.move(to: NSPoint(x: innerL, y: y))
        rule.line(to: NSPoint(x: innerR, y: y))
        rule.lineWidth = max(1.0, H * 0.0012)
        Pal.frame.withAlphaComponent(0.7).setStroke()
        rule.stroke()

        // Bottom prompt line with a blinking block cursor.
        let promptY = innerB + bodySize * 0.7
        draw("\u{276F}", leftX: innerL, centerY: promptY, font: boldF, color: Pal.accent)
        let cursorOn = time.truncatingRemainder(dividingBy: 1.0) < 0.5
        if cursorOn {
            let cw = adv * 0.85, ch = bodySize * 1.05
            Pal.accent.withAlphaComponent(0.9).setFill()
            NSRect(x: innerL + adv * 2, y: promptY - ch / 2, width: cw, height: ch).fill()
        }

        // Big flat clock, centered in the space between the rule and the prompt.
        let clockCenterY = (y + promptY) / 2 + lh * 0.15
        var clockSize = H * 0.09
        var kern = clockSize * 0.10
        let maxW = innerR - innerL
        for _ in 0..<40 {
            if measure(clockText, font: Fonts.extraBold(clockSize), kern: kern).width <= maxW { break }
            clockSize *= 0.95; kern = clockSize * 0.10
        }
        drawCentered(clockText, cx: W / 2, centerY: clockCenterY,
                     font: Fonts.extraBold(clockSize), color: Pal.clock, kern: kern)
    }

    // MARK: Faint flat scanlines (no sweep, no glow)

    private func scanlines(_ ctx: CGContext, W: CGFloat, H: CGFloat) {
        ctx.saveGState()
        Pal.scan.withAlphaComponent(0.14).setFill()
        var y: CGFloat = 0
        let spacing: CGFloat = 3
        while y < H {
            NSRect(x: 0, y: y, width: W, height: spacing * 0.5).fill()
            y += spacing
        }
        ctx.restoreGState()
    }

    // MARK: Subtle matte vignette

    private func vignette(_ ctx: CGContext, W: CGFloat, H: CGFloat) {
        let c = NSPoint(x: W / 2, y: H / 2)
        let g = NSGradient(colors: [NSColor.clear, Pal.bg1.withAlphaComponent(0.5)],
                           atLocations: [0.55, 1.0], colorSpace: .sRGB)
        let maxR = sqrt(W * W + H * H) / 2
        g?.draw(fromCenter: c, radius: min(W, H) * 0.20, toCenter: c, radius: maxR, options: [])
    }

    // MARK: - Text helpers ------------------------------------------------------

    private func measure(_ s: String, font: NSFont, kern: CGFloat) -> NSSize {
        NSAttributedString(string: s, attributes: [.font: font, .kern: kern]).size()
    }

    private func advance(_ font: NSFont) -> CGFloat { measure("M", font: font, kern: 0).width }

    /// Left-aligned single line; `centerY` is the vertical center of the glyphs.
    private func draw(_ s: String, leftX: CGFloat, centerY: CGFloat,
                      font: NSFont, color: NSColor, kern: CGFloat = 0) {
        let attrs: [NSAttributedString.Key: Any] = [.font: font, .foregroundColor: color, .kern: kern]
        let str = NSAttributedString(string: s, attributes: attrs)
        let sz = str.size()
        str.draw(with: NSRect(x: leftX, y: centerY - sz.height / 2, width: sz.width + kern, height: sz.height),
                 options: [.usesLineFragmentOrigin])
    }

    /// Centered single line about `cx`.
    private func drawCentered(_ s: String, cx: CGFloat, centerY: CGFloat,
                              font: NSFont, color: NSColor, kern: CGFloat = 0) {
        let sz = measure(s, font: font, kern: kern)
        draw(s, leftX: cx - sz.width / 2 - kern / 2, centerY: centerY, font: font, color: color, kern: kern)
    }

    /// Draw a label sitting on a border line, punching a bg-colored gap so the
    /// border reads as broken by the text (left-anchored).
    private func cutLabel(_ s: String, leftX: CGFloat, centerY: CGFloat,
                          font: NSFont, color: NSColor, bg: NSColor) {
        let sz = measure(s, font: font, kern: 0)
        bg.setFill()
        NSRect(x: leftX, y: centerY - sz.height / 2, width: sz.width, height: sz.height).fill()
        draw(s, leftX: leftX, centerY: centerY, font: font, color: color)
    }

    /// Centered variant of `cutLabel`.
    private func cutLabelCentered(_ s: String, cx: CGFloat, centerY: CGFloat,
                                  font: NSFont, color: NSColor, bg: NSColor) {
        let sz = measure(s, font: font, kern: 0)
        bg.setFill()
        NSRect(x: cx - sz.width / 2, y: centerY - sz.height / 2, width: sz.width, height: sz.height).fill()
        drawCentered(s, cx: cx, centerY: centerY, font: font, color: color)
    }
}
