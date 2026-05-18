// WebView Screensaver remote URL list format.
// Each entry: { kScreenSaverURL: "...", kScreenSaverTime: <seconds> }
// See: https://github.com/liquidx/webviewscreensaver — WVSSAddress.m

// ?embed=app keeps the per-piece city/region switcher dots visible inside
// the screensaver. The bare vercel URL hides them.
const PIECES = [
  { kScreenSaverURL: "https://tide-pixels-2026-05-06.vercel.app/?embed=app", kScreenSaverTime: 600 },
  { kScreenSaverURL: "https://sky-traffic-2026-05-07.vercel.app/?embed=app", kScreenSaverTime: 600 },
  { kScreenSaverURL: "https://bay-ships-2026-05-07.vercel.app/?embed=app", kScreenSaverTime: 600 },
  { kScreenSaverURL: "https://subway-pulse-2026-05-07.vercel.app/?embed=app", kScreenSaverTime: 600 },
  { kScreenSaverURL: "https://quake-globe-2026-05-07.vercel.app/?embed=app", kScreenSaverTime: 600 },
  { kScreenSaverURL: "https://moon-phase-2026-05-16.vercel.app/?embed=app", kScreenSaverTime: 600 },
];

export default function handler(req, res) {
  // shuffle so the cycle order varies per fetch
  const shuffled = [...PIECES].sort(() => Math.random() - 0.5);
  res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
  res.setHeader("Content-Type", "application/json; charset=utf-8");
  res.status(200).send(JSON.stringify(shuffled, null, 2));
}
