#!/usr/bin/env bash
# Vendor the canonical bgm-engine into each ambient piece's lib/bgm/engine/.
# Canonical source: ~/Projects/ambient-art-pack/bgm-engine/ (this directory).
# Per-project files (lib/bgm/preset.ts, lib/bgm/signals.ts) are never touched.
set -euo pipefail

SRC="$(cd "$(dirname "$0")" && pwd)"
PROJECTS=(
  "$HOME/Projects/tide-pixels-2026-05-06"
  "$HOME/Projects/sky-traffic-2026-05-07"
  "$HOME/Projects/bay-ships-2026-05-07"
  "$HOME/Projects/subway-pulse-2026-05-07"
  "$HOME/Projects/quake-globe-2026-05-07"
  "$HOME/Projects/moon-phase-2026-05-16"
)
FILES=(types.ts theory.ts layers.ts engine.ts useBgm.ts BgmToggle.tsx index.ts)

for proj in "${PROJECTS[@]}"; do
  dest="${proj}/lib/bgm/engine"
  # only sync into projects that already adopted bgm (engine dir exists)
  if [ ! -d "$dest" ]; then
    echo "skip   ${proj##*/} (no lib/bgm/engine — not adopted yet; mkdir it to opt in)"
    continue
  fi
  for f in "${FILES[@]}"; do
    rsync -a "${SRC}/${f}" "${dest}/${f}"
  done
  # drift check: vendored copy must now match canonical exactly
  drift=0
  for f in "${FILES[@]}"; do
    if ! diff -q "${SRC}/${f}" "${dest}/${f}" >/dev/null 2>&1; then
      echo "DRIFT  ${proj##*/}/${f}"
      drift=1
    fi
  done
  [ "$drift" -eq 0 ] && echo "synced ${proj##*/}"
done
