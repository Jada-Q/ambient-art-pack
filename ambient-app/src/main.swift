import Cocoa
import WebKit

// Ambient — desktop wallpaper that loads ambient-art-pack pieces.
// Menu bar lets you pick a piece + city/region variant.
// Wallpaper mode doesn't get keyboard events (macOS limitation); use "Open in Browser" to play with sprites.
//
// Piece catalog is fetched from https://ambient-art-pack.vercel.app/pieces.json
// at startup, cached locally, and falls back to a bundled Resources/pieces.json.
// Adding a new piece: edit /pieces.json in the repo + git push. App auto-picks
// up on next launch, or instantly via "Refresh Pieces" menu item.

struct Variant: Codable {
    let key: String
    let label: String
}

struct Piece: Codable {
    let key: String
    let label: String
    let emoji: String
    let baseURL: String
    let variantParam: String?  // e.g. "c", "b", "l", "r" — nil if no variants
    let variants: [Variant]
}

let MINIMAL_FALLBACK: [Piece] = [
    Piece(
        key: "random",
        label: "Random rotation",
        emoji: "🎲",
        baseURL: "https://ambient-art-pack.vercel.app/random",
        variantParam: nil,
        variants: []
    )
]

let REMOTE_PIECES_URL = URL(string: "https://ambient-art-pack.vercel.app/pieces.json")!
let RELOAD_INTERVAL: TimeInterval = 10 * 60
let DEFAULTS_PIECE_KEY = "selectedPieceKey"

func variantKey(for piece: String) -> String { "selectedVariant_\(piece)" }

let CACHE_PATH: URL = {
    let fm = FileManager.default
    let caches = fm.urls(for: .cachesDirectory, in: .userDomainMask).first!
    let dir = caches.appendingPathComponent("net.jada.ambient")
    try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
    return dir.appendingPathComponent("pieces.json")
}()

func loadBundledPieces() -> [Piece]? {
    guard let url = Bundle.main.url(forResource: "pieces", withExtension: "json"),
          let data = try? Data(contentsOf: url),
          let pieces = try? JSONDecoder().decode([Piece].self, from: data),
          !pieces.isEmpty
    else { return nil }
    return pieces
}

func loadCachedPieces() -> [Piece]? {
    guard let data = try? Data(contentsOf: CACHE_PATH),
          let pieces = try? JSONDecoder().decode([Piece].self, from: data),
          !pieces.isEmpty
    else { return nil }
    return pieces
}

func initialPieces() -> [Piece] {
    // Priority: cache (most recent successful fetch) > bundle (ships with app) > minimal hardcoded.
    if let cached = loadCachedPieces() { return cached }
    if let bundled = loadBundledPieces() { return bundled }
    return MINIMAL_FALLBACK
}

class WallpaperWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var pieces: [Piece] = initialPieces()
    var windows: [NSWindow] = []
    var webViews: [WKWebView] = []
    var statusItem: NSStatusItem!
    var reloadTimer: Timer?
    var isFetching = false

    var currentPiece: Piece {
        let stored = UserDefaults.standard.string(forKey: DEFAULTS_PIECE_KEY) ?? "random"
        return pieces.first { $0.key == stored } ?? pieces.first ?? MINIMAL_FALLBACK[0]
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
        // Kick off background fetch — replaces `pieces` and rebuilds menu when it completes.
        fetchRemotePieces()
    }

    func fetchRemotePieces() {
        guard !isFetching else { return }
        isFetching = true

        let config = URLSessionConfiguration.ephemeral
        config.timeoutIntervalForRequest = 10
        let session = URLSession(configuration: config)

        var req = URLRequest(url: REMOTE_PIECES_URL)
        req.cachePolicy = .reloadIgnoringLocalCacheData

        session.dataTask(with: req) { [weak self] data, response, error in
            defer { self?.isFetching = false }
            guard let self = self else { return }
            guard let data = data, error == nil,
                  let http = response as? HTTPURLResponse, http.statusCode == 200,
                  let fetched = try? JSONDecoder().decode([Piece].self, from: data),
                  !fetched.isEmpty
            else {
                NSLog("Ambient: fetchRemotePieces failed, keeping existing %d pieces", self.pieces.count)
                return
            }
            // Cache to disk for next cold start.
            try? data.write(to: CACHE_PATH, options: .atomic)
            DispatchQueue.main.async {
                let oldKey = self.currentPiece.key
                self.pieces = fetched
                NSLog("Ambient: fetched %d pieces from remote", fetched.count)
                self.rebuildMenu()
                // If the currently-selected piece survived in the new list, reload its URL.
                // If it disappeared, currentPiece falls back to first piece — reload that.
                if self.pieces.first(where: { $0.key == oldKey }) == nil {
                    self.reloadAll()
                }
            }
        }.resume()
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

        for (i, piece) in pieces.enumerated() {
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
        menu.addItem(NSMenuItem(title: "Refresh Pieces from Remote", action: #selector(refreshPieces), keyEquivalent: "R"))
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
        let piece = pieces[sender.tag]
        UserDefaults.standard.set(piece.key, forKey: DEFAULTS_PIECE_KEY)
        rebuildMenu()
        reloadAll()
    }

    @objc func selectVariant(_ sender: NSMenuItem) {
        let pi = sender.tag / 100
        let vi = sender.tag % 100
        let piece = pieces[pi]
        let variant = piece.variants[vi]
        UserDefaults.standard.set(piece.key, forKey: DEFAULTS_PIECE_KEY)
        UserDefaults.standard.set(variant.key, forKey: variantKey(for: piece.key))
        rebuildMenu()
        reloadAll()
    }

    @objc func reloadNow() { reloadAll() }

    @objc func refreshPieces() { fetchRemotePieces() }

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
