import Cocoa
import WebKit

// One-off harness: does Web Audio start WITHOUT any user gesture inside a
// wallpaper-style WKWebView configured like Ambient.app?
// Usage: swiftc -o /tmp/bgm-test bgm-autoplay-test.swift -framework Cocoa -framework WebKit
//        /tmp/bgm-test "http://localhost:3011/?embed=app&bgm=1"
// Prints PASS/FAIL JSON to stdout and exits.

let urlString = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "http://localhost:3011/?embed=app&bgm=1"

class TestDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var webView: WKWebView!

    func applicationDidFinishLaunching(_ notification: Notification) {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.borderless], backing: .buffered, defer: false
        )
        // same level + mouse config as the real wallpaper window
        window.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)))
        window.ignoresMouseEvents = true

        let wkConfig = WKWebViewConfiguration()
        wkConfig.mediaTypesRequiringUserActionForPlayback = []

        webView = WKWebView(frame: window.contentView!.bounds, configuration: wkConfig)
        window.contentView?.addSubview(webView)
        window.makeKeyAndOrderFront(nil)
        webView.load(URLRequest(url: URL(string: urlString)!))

        // generous wait: page load + autostart attempt + 5s fade-in + first chord
        DispatchQueue.main.asyncAfter(deadline: .now() + 12) { [weak self] in
            self?.check()
        }
    }

    func check() {
        let js = "JSON.stringify(window.__bgmStatus ? window.__bgmStatus() : {hookMissing:true})"
        webView.evaluateJavaScript(js) { result, error in
            if let error = error {
                print("RESULT: FAIL — evaluateJavaScript error: \(error.localizedDescription)")
            } else if let s = result as? String {
                let running = s.contains("\"contextState\":\"running\"")
                let audible = !s.contains("meterDb\":null") && !s.contains("-Infinity")
                print("RESULT: \(running && audible ? "PASS" : "FAIL") — \(s)")
            } else {
                print("RESULT: FAIL — unexpected result \(String(describing: result))")
            }
            NSApplication.shared.terminate(nil)
        }
    }
}

let app = NSApplication.shared
let delegate = TestDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
