// HUD.swift — a transient centered message chip ("Already on today",
// "No more motion"): fades in over the host view, holds a moment, fades out
// and removes itself. One at a time per host — a new flash replaces the old.
// Purely informational: it never intercepts mouse events.

import AppKit

final class HUDView: NSView {
    static func flash(_ text: String, in host: NSView) {
        host.subviews.compactMap { $0 as? HUDView }.forEach { $0.removeFromSuperview() }
        let hud = HUDView(text: text)
        hud.frame.origin = NSPoint(x: ((host.bounds.width - hud.frame.width) / 2).rounded(),
                                   y: ((host.bounds.height - hud.frame.height) / 2).rounded())
        hud.autoresizingMask = [.minXMargin, .maxXMargin, .minYMargin, .maxYMargin]
        hud.alphaValue = 0
        host.addSubview(hud)
        NSAnimationContext.runAnimationGroup { ctx in
            ctx.duration = 0.15
            hud.animator().alphaValue = 1
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.1) { [weak hud] in
            guard let hud, hud.superview != nil else { return }   // already replaced
            NSAnimationContext.runAnimationGroup({ ctx in
                ctx.duration = 0.35
                hud.animator().alphaValue = 0
            }, completionHandler: { hud.removeFromSuperview() })
        }
    }

    private init(text: String) {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: 14, weight: .semibold)
        label.textColor = .white
        label.sizeToFit()
        let padX: CGFloat = 14, padY: CGFloat = 9
        super.init(frame: NSRect(x: 0, y: 0,
                                 width: label.frame.width + padX * 2,
                                 height: label.frame.height + padY * 2))
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.withAlphaComponent(0.7).cgColor
        layer?.cornerRadius = 9
        label.frame.origin = NSPoint(x: padX, y: padY)
        addSubview(label)
    }

    required init?(coder: NSCoder) { fatalError("unused") }

    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}
