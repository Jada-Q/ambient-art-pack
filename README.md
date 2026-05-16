# Ambient Art Pack

Six ambient art pieces — set them as your Mac desktop wallpaper or screensaver. Pieces rotate automatically; their content updates live as they evolve.

**Pieces** (each has 3-6 city/region variants):
- 🌊 [Tide Pixels](https://tide-pixels-2026-05-06.vercel.app/) — ocean canvas with sun, moon, tide direction, and a pixel 海女 holding a fish basket
- 🛬 [Sky Traffic](https://sky-traffic-2026-05-07.vercel.app/) — live aircraft trails over major airports, with a 1950s tower controller ghost
- 🗼 [Bay Ships](https://bay-ships-2026-05-07.vercel.app/) — bay vessel positions, with a 91-year-old lighthouse keeper
- 🚇 [Subway Pulse](https://subway-pulse-2026-05-07.vercel.app/) — Tokyo metro line pulses, with a Yamanote loop rider
- 🪨 [Quake Globe](https://quake-globe-2026-05-07.vercel.app/) — rotating earth with live seismic events
- 🌙 [Moon Phase](https://moon-phase-2026-05-16.vercel.app/) — tonight's moon (phase, position, rise/set) over your chosen city, with a moon rabbit Tsuki

---

## Install (Mac only, macOS 13+)

### Recommended — Ambient.app (always-on wallpaper)

**Download path (no Terminal needed)**:
1. Download [latest **Ambient.app.zip**](https://github.com/Jada-Q/ambient-art-pack/releases/latest)
2. Double-click the zip → `Ambient.app` appears
3. Drag `Ambient.app` to `/Applications/`
4. Double-click `Ambient.app` → macOS will warn: "Apple could not verify…"
   - Click **Done / 完了** (do NOT click "Move to Trash / ゴミ箱に入れる")
5. Open **System Settings → Privacy & Security** (システム設定 → プライバシーとセキュリティ)
6. Scroll to the **Security** section at the bottom → see "Ambient was blocked"
7. Click **Open Anyway / このまま開く** → enter your Mac password
8. Double-click `Ambient.app` again → opens normally
9. Menu bar shows 🌊 icon → click → pick a piece + city
10. Your desktop becomes the ambient art

(macOS 15 Sequoia hardened Gatekeeper — ad-hoc signed apps need this one-time approval. After that, normal double-click works forever.)

**Or via Terminal (fastest)**:
```bash
# After dragging Ambient.app to /Applications/:
xattr -dr com.apple.quarantine /Applications/Ambient.app
open -a Ambient
```

**Or via Homebrew**:
```bash
brew tap Jada-Q/ambient-art-pack
brew install --cask ambient
open -a Ambient
```

### Alternative — Screensaver mode (idle-triggered)

If you want the art to appear only when your Mac goes idle (not always-on wallpaper):

```bash
brew tap Jada-Q/ambient-art-pack
brew install --cask ambient-art-screensaver
```

Then **System Settings → Screen Saver → WebViewScreenSaver**.

⚠️ macOS 15+ Sequoia may block third-party screensavers due to stricter signing requirements. The Ambient.app wallpaper path is more reliable.

---

## Using Ambient.app

Menu bar 🌊 → submenu:

| Menu | What it does |
|---|---|
| 🎲 Random rotation | Cycles through all 5 pieces randomly every 10 min |
| 🌊 Tide Pixels ▶ | Pick city: Tokyo / Osaka / Hangzhou / NYC / Reykjavík / Sydney |
| 🛬 Sky Traffic ▶ | Pick airport: Tokyo / Osaka / Shanghai / HKG / LAX / NYC |
| 🗼 Bay Ships ▶ | Pick bay: Tokyo / Osaka / NY Harbor |
| 🚇 Subway Pulse ▶ | Pick line: All / Yamanote / Marunouchi / Ginza / Hibiya / Chiyoda |
| 🪨 Quake Globe ▶ | Pick region: World / Japan / Pacific Rim / Americas / Europe |
| Reload Now (⌘R) | Force re-fetch |
| Hide / Show (⌘H) | Toggle wallpaper visibility (Ambient stays running) |
| Open in Browser (⌘O) | Open current piece in browser — for playing with sprites via arrow keys |
| Quit Ambient (⌘Q) | Exit |

Each piece has a small pixel character (海女 / tower ghost / lighthouse keeper / loop rider / lava). They animate autonomously on the wallpaper. For arrow-key control (move them around), use **Open in Browser** — wallpaper mode doesn't receive keyboard events (macOS limitation).

## Auto-start on login

System Settings → General → Login Items → click **+** → add `/Applications/Ambient.app`.

## Updates

Pieces update automatically — the wallpaper fetches from live URLs every 10 minutes, so new sprites / data / content show up without re-installing anything.

To update Ambient.app itself: `brew upgrade --cask ambient` or download the latest zip and replace `/Applications/Ambient.app`.

## Architecture

```
Ambient.app (menu bar)
  └→ borderless WKWebView at desktop window level
      └→ loads piece URL (with selected city/region param)
          └→ on 10-min timer: reload
              └→ if Random: re-fetches /random → 307 to a new piece
```

Source: `ambient-app/src/main.swift` · about 200 lines AppKit + WebKit.

## Uninstall

```bash
brew uninstall --cask ambient
# or
rm -rf /Applications/Ambient.app
defaults delete net.jada.ambient
```

## Development

```bash
cd ambient-app
./build-app.sh        # builds build/Ambient.app
open build/Ambient.app
```

Switcher URL endpoints in `api/` (Vercel). To deploy: `vercel --prod`.

## License

MIT. WebView Screensaver is bundled under Apache 2.0 (see [liquidx/webviewscreensaver](https://github.com/liquidx/webviewscreensaver)).
