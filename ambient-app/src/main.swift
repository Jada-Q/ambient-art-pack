import Cocoa
import WebKit

// Ambient — desktop wallpaper that loads ambient-art-pack pieces.
// Menu bar lets you pick a piece + city/region variant.
// Wallpaper mode doesn't get keyboard events (macOS limitation); use "Open in Browser" to play with sprites.

struct Variant {
    let key: String
    let label: String
}

struct Piece {
    let key: String
    let label: String
    let emoji: String
    let baseURL: String
    let variantParam: String?  // e.g. "c", "b", "l", "r" — nil if no variants
    let variants: [Variant]    // empty if no variants
}

let PIECES: [Piece] = [
    Piece(
        key: "random",
        label: "Random rotation",
        emoji: "🎲",
        baseURL: "https://ambient-art-pack.vercel.app/random",
        variantParam: nil,
        variants: []
    ),
    Piece(
        key: "tide-pixels",
        label: "Tide Pixels",
        emoji: "🌊",
        baseURL: "https://tide-pixels-2026-05-06.vercel.app/",
        variantParam: "c",
        variants: [
            Variant(key: "tokyo",     label: "Tokyo (default)"),
            Variant(key: "osaka",     label: "Osaka"),
            Variant(key: "hangzhou",  label: "Hangzhou 杭州"),
            Variant(key: "nyc",       label: "New York"),
            Variant(key: "reykjavik", label: "Reykjavík"),
            Variant(key: "sydney",    label: "Sydney"),
        ]
    ),
    Piece(
        key: "sky-traffic",
        label: "Sky Traffic",
        emoji: "🛬",
        baseURL: "https://sky-traffic-2026-05-07.vercel.app/",
        variantParam: "c",
        variants: [
            Variant(key: "tokyo",    label: "Tokyo (HND/NRT, default)"),
            Variant(key: "osaka",    label: "Osaka (ITM/KIX)"),
            Variant(key: "shanghai", label: "Shanghai (PVG/SHA)"),
            Variant(key: "hkg",      label: "Hong Kong (HKG)"),
            Variant(key: "lax",      label: "Los Angeles (LAX)"),
            Variant(key: "nyc",      label: "New York (JFK/LGA/EWR)"),
        ]
    ),
    Piece(
        key: "bay-ships",
        label: "Bay Ships",
        emoji: "🗼",
        baseURL: "https://bay-ships-2026-05-07.vercel.app/",
        variantParam: "b",
        variants: [
            Variant(key: "tokyo-bay", label: "Tokyo Bay (default)"),
            Variant(key: "osaka-bay", label: "Osaka Bay (Akashi Strait)"),
            Variant(key: "ny-harbor", label: "New York Harbor"),
        ]
    ),
    Piece(
        key: "subway-pulse",
        label: "Subway Pulse",
        emoji: "🚇",
        baseURL: "https://subway-pulse-2026-05-07.vercel.app/",
        variantParam: "l",
        variants: [
            Variant(key: "all",        label: "All 5 lines (default)"),
            Variant(key: "yamanote",   label: "Yamanote"),
            Variant(key: "marunouchi", label: "Marunouchi"),
            Variant(key: "ginza",      label: "Ginza"),
            Variant(key: "hibiya",     label: "Hibiya"),
            Variant(key: "chiyoda",    label: "Chiyoda"),
        ]
    ),
    Piece(
        key: "quake-globe",
        label: "Quake Globe",
        emoji: "🪨",
        baseURL: "https://quake-globe-2026-05-07.vercel.app/",
        variantParam: "r",
        variants: [
            Variant(key: "world",       label: "World (default)"),
            Variant(key: "japan",       label: "Japan"),
            Variant(key: "pacific-rim", label: "Pacific Rim"),
            Variant(key: "americas",    label: "Americas"),
            Variant(key: "europe",      label: "Europe"),
        ]
    ),
]

let RELOAD_INTERVAL: TimeInterval = 10 * 60
let DEFAULTS_PIECE_KEY = "selectedPieceKey"
func variantKey(for piece: String) -> String { "selectedVariant_\(piece)" }

class WallpaperWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var windows: [NSWindow] = []
    var webViews: [WKWebView] = []
    var statusItem: NSStatusItem!
    var reloadTimer: Timer?

    var currentPiece: Piece {
        let stored = UserDefaults.standard.string(forKey: DEFAULTS_PIECE_KEY) ?? "random"
        return PIECES.first { $0.key == stored } ?? PIECES[0]
    }

    func currentVariant(for piece: Piece) -> Variant? {
        guard !piece.variants.isEmpty else { return nil }
        let stored = UserDefaults.standard.string(forKey: variantKey(for: piece.key))
        return piece.variants.first { $0.key == stored } ?? piece.variants.first
    }

    func currentURL() -> URL {
        let piece = currentPiece
        guard let param = piece.variantParam,
              let variant = currentVariant(for: piece),
              variant.key != piece.variants.first?.key  // first is default, omit param
        else {
            return URL(string: piece.baseURL)!
        }
        return URL(string: "\(piece.baseURL)?\(param)=\(variant.key)")!
    }

    func currentLabel() -> String {
        let piece = currentPiece
        if let variant = currentVariant(for: piece), piece.variants.count > 1 {
            return "\(piece.label) — \(variant.label.replacingOccurrences(of: " (default)", with: ""))"
        }
        return piece.label
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupStatusBar()
        setupWallpaperWindows()
        startReloadTimer()
        NotificationCenter.default.addObserver(self, selector: #selector(screenChanged),
                                                name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }

    func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        rebuildMenu()
    }

    func rebuildMenu() {
        if let button = statusItem.button {
            button.title = currentPiece.emoji
            button.toolTip = "Ambient — \(currentLabel())"
        }

        let menu = NSMenu()

        let header = NSMenuItem(title: "Showing: \(currentPiece.emoji) \(currentLabel())", action: nil, keyEquivalent: "")
        header.isEnabled = false
        menu.addItem(header)
        menu.addItem(NSMenuItem.separator())

        for (i, piece) in PIECES.enumerated() {
            let item = NSMenuItem(
                title: "\(piece.emoji)  \(piece.label)",
                action: #selector(selectPiece(_:)),
                keyEquivalent: i < 9 ? "\(i + 1)" : ""
            )
            item.tag = i
            item.state = piece.key == currentPiece.key ? .on : .off

            // Submenu for pieces with variants
            if !piece.variants.isEmpty {
                let sub = NSMenu()
                for (vi, variant) in piece.variants.enumerated() {
                    let vitem = NSMenuItem(
                        title: variant.label,
                        action: #selector(selectVariant(_:)),
                        keyEquivalent: ""
                    )
                    vitem.tag = i * 100 + vi
                    let isCurrent = piece.key == currentPiece.key && variant.key == currentVariant(for: piece)?.key
                    vitem.state = isCurrent ? .on : .off
                    sub.addItem(vitem)
                }
                item.submenu = sub
            }
            menu.addItem(item)
        }

        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Reload Now", action: #selector(reloadNow), keyEquivalent: "r"))
        menu.addItem(NSMenuItem(title: "Hide / Show", action: #selector(toggleVisibility), keyEquivalent: "h"))
        menu.addItem(NSMenuItem(title: "Open in Browser  (play with sprite)", action: #selector(openInBrowser), keyEquivalent: "o"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "About Ambient…", action: #selector(openAbout), keyEquivalent: ""))
        menu.addItem(NSMenuItem(title: "Quit Ambient", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))

        statusItem.menu = menu
    }

    func setupWallpaperWindows() {
        for w in windows { w.close() }
        windows.removeAll()
        webViews.removeAll()

        for screen in NSScreen.screens {
            let window = WallpaperWindow(
                contentRect: screen.frame, styleMask: [.borderless],
                backing: .buffered, defer: false, screen: screen
            )
            window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
            window.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
            window.isOpaque = true
            window.backgroundColor = NSColor.black
            window.ignoresMouseEvents = true
            window.hasShadow = false

            let webView = WKWebView(frame: window.contentView!.bounds, configuration: WKWebViewConfiguration())
            webView.autoresizingMask = [.width, .height]
            webView.setValue(false, forKey: "drawsBackground")
            webView.load(URLRequest(url: currentURL()))
            window.contentView?.addSubview(webView)

            window.makeKeyAndOrderFront(nil)
            windows.append(window)
            webViews.append(webView)
        }
    }

    func startReloadTimer() {
        reloadTimer?.invalidate()
        reloadTimer = Timer.scheduledTimer(withTimeInterval: RELOAD_INTERVAL, repeats: true) { [weak self] _ in
            self?.reloadAll()
        }
    }

    func reloadAll() {
        for webView in webViews { webView.load(URLRequest(url: currentURL())) }
    }

    @objc func selectPiece(_ sender: NSMenuItem) {
        let piece = PIECES[sender.tag]
        UserDefaults.standard.set(piece.key, forKey: DEFAULTS_PIECE_KEY)
        rebuildMenu()
        reloadAll()
    }

    @objc func selectVariant(_ sender: NSMenuItem) {
        let pi = sender.tag / 100
        let vi = sender.tag % 100
        let piece = PIECES[pi]
        let variant = piece.variants[vi]
        UserDefaults.standard.set(piece.key, forKey: DEFAULTS_PIECE_KEY)
        UserDefaults.standard.set(variant.key, forKey: variantKey(for: piece.key))
        rebuildMenu()
        reloadAll()
    }

    @objc func reloadNow() { reloadAll() }

    @objc func toggleVisibility() {
        for w in windows {
            if w.isVisible { w.orderOut(nil) } else { w.makeKeyAndOrderFront(nil) }
        }
    }

    @objc func openInBrowser() {
        NSWorkspace.shared.open(currentURL())
    }

    @objc func openAbout() {
        if let url = URL(string: "https://github.com/Jada-Q/ambient-art-pack") {
            NSWorkspace.shared.open(url)
        }
    }

    @objc func screenChanged() { setupWallpaperWindows() }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
