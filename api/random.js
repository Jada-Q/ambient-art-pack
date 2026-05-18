// Random 307 redirect to one of the ambient art pieces.
// Used as a wallpaper URL (Plash etc) — each refresh = new piece.

// ?embed=app keeps the per-piece city/region switcher dots visible inside
// wallpaper apps (Plash / Ambient.app / WVS). The bare vercel URL hides them.
const PIECES = [
  "https://tide-pixels-2026-05-06.vercel.app/?embed=app",
  "https://sky-traffic-2026-05-07.vercel.app/?embed=app",
  "https://bay-ships-2026-05-07.vercel.app/?embed=app",
  "https://subway-pulse-2026-05-07.vercel.app/?embed=app",
  "https://quake-globe-2026-05-07.vercel.app/?embed=app",
  "https://moon-phase-2026-05-16.vercel.app/?embed=app",
];

export default function handler(req, res) {
  const pick = PIECES[Math.floor(Math.random() * PIECES.length)];
  res.setHeader("Cache-Control", "no-store, no-cache, must-revalidate");
  res.redirect(307, pick);
}
