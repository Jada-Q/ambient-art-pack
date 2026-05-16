# Ambient Art Pack

Five ambient art pieces — set them as your Mac screensaver. The pieces rotate every 10 minutes; their content updates live as they evolve.

**Pieces**:
- 🌊 [Tide Pixels](https://tide-pixels-2026-05-06.vercel.app/) — ocean canvas, sun/moon/tide
- 🛬 [Sky Traffic](https://sky-traffic-2026-05-07.vercel.app/) — live aircraft trails
- 🗼 [Bay Ships](https://bay-ships-2026-05-07.vercel.app/) — bay vessel positions
- 🚇 [Subway Pulse](https://subway-pulse-2026-05-07.vercel.app/) — Tokyo metro line pulses
- 🪨 [Quake Globe](https://quake-globe-2026-05-07.vercel.app/) — rotating earth with live seismic events

---

## Install

### Easy (double-click `.pkg`)

1. Download the latest [`.pkg` from Releases](https://github.com/Jada-Q/ambient-art-pack/releases/latest)
2. Double-click the `.pkg`
3. **First time**: macOS Gatekeeper may block. Right-click the `.pkg` → **Open** → **Open** (one-time bypass)
4. macOS Installer opens → click **Continue** → enter admin password → done
5. Open **System Settings → Screen Saver** → select **WebViewScreenSaver** from the list

### One-line (developers, via Homebrew)

```bash
brew tap Jada-Q/ambient-art-pack
brew install --cask ambient-art-screensaver
```

Then proceed to **System Settings → Screen Saver** to select WebViewScreenSaver.

---

## What it installs

- [WebView Screensaver](https://github.com/liquidx/webviewscreensaver) (v2.5, MIT-licensed) at `/Library/Screen Savers/`
- Configures it to fetch its URL list from `https://ambient-art-pack.vercel.app/list.json`

That's it. The screensaver itself fetches the live list every time it fires, so updates propagate automatically — no re-install needed when new pieces or features ship.

## Architecture

```
Mac idle N minutes
  → macOS launches screensaver
  → WebView Screensaver loads its configured remote list URL
  → ambient-art-pack.vercel.app/list.json returns [piece1, piece2, ...]
  → WKWebView rotates through pieces every 10 min
  → keyboard / mouse interrupts → screensaver exits
```

The pieces themselves stay deployed at their original Vercel URLs. This repo only adds the screensaver wrapper + a switcher list.

## Uninstall

```bash
# Remove the screensaver bundle
rm -rf "/Library/Screen Savers/WebViewScreenSaver.saver"

# Clear preferences
defaults -currentHost delete net.liquidx.WebViewScreenSaver

# Or via brew
brew uninstall --cask ambient-art-screensaver
```

## Development

```bash
# Rebuild the .pkg
./scripts/build-pkg.sh

# Deploy the switcher URL endpoints
vercel --prod
```

Source: switcher endpoints in `api/`, .pkg config in `pkg-payload/` and `pkg-scripts/`.

## License

This repo is MIT-licensed. WebView Screensaver is bundled under its own Apache 2.0 license (see [liquidx/webviewscreensaver](https://github.com/liquidx/webviewscreensaver)).
