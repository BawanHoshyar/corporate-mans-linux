// main.swift — offline PNG renderer for design iteration.
// Renders SceneRenderer frames to PNG so the look can be reviewed without
// hijacking the display. Not shipped inside the .saver.
//
//   swiftc Sources/Scene.swift Sources/main.swift -o /tmp/preview \
//     -framework AppKit -framework CoreText
//   /tmp/preview <outputDir>

import AppKit

func renderPNG(size: NSSize, time: Double, clock: String, to path: String) {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size.width), pixelsHigh: Int(size.height),
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0) else {
        FileHandle.standardError.write("failed to make bitmap rep\n".data(using: .utf8)!)
        return
    }
    guard let gctx = NSGraphicsContext(bitmapImageRep: rep) else { return }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = gctx
    let ctx = gctx.cgContext

    SceneRenderer().render(ctx: ctx, size: size, time: time, isPreview: false, clockText: clock)

    gctx.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()

    if let data = rep.representation(using: .png, properties: [:]) {
        try? data.write(to: URL(fileURLWithPath: path))
        print("wrote \(path)")
    }
}

func renderPreviewThumb(to path: String) {
    let size = NSSize(width: 480, height: 300)
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: 480, pixelsHigh: 300,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .calibratedRGB, bytesPerRow: 0, bitsPerPixel: 0) else { return }
    guard let gctx = NSGraphicsContext(bitmapImageRep: rep) else { return }
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = gctx
    SceneRenderer().render(ctx: gctx.cgContext, size: size, time: 1.7,
                           isPreview: true, clockText: "02:14:07")
    gctx.flushGraphics()
    NSGraphicsContext.restoreGraphicsState()
    if let data = rep.representation(using: .png, properties: [:]) {
        try? data.write(to: URL(fileURLWithPath: path)); print("wrote \(path)")
    }
}

let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "./frames"
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

let full = NSSize(width: 1920, height: 1080)
renderPNG(size: full, time: 0.12, clock: "02:14:07", to: "\(outDir)/frame_glitch.png")
renderPNG(size: full, time: 1.70, clock: "02:14:08", to: "\(outDir)/frame_calm1.png")
renderPNG(size: full, time: 3.40, clock: "02:14:10", to: "\(outDir)/frame_calm2.png")
renderPreviewThumb(to: "\(outDir)/frame_thumb.png")
