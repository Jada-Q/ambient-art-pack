#!/usr/bin/env bash
# Generate 30s MusicGen demos for all 6 ambient pieces (2 prompts each).
# Usage: ./generate-all.sh [model]   (default facebook/musicgen-small)
# Output: musicgen/{piece}-{1,2}.wav (32kHz mono)
set -euo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
MLX="$HOME/Projects/mlx-examples/musicgen"
PY="$DIR/.venv/bin/python"
MODEL="${1:-facebook/musicgen-small}"
STEPS=1500  # 50 steps ≈ 1s audio → 1500 ≈ 30s

declare -a KEYS PROMPTS
KEYS=(
  tide-pixels-1 tide-pixels-2
  sky-traffic-1 sky-traffic-2
  bay-ships-1 bay-ships-2
  subway-pulse-1 subway-pulse-2
  quake-globe-1 quake-globe-2
  moon-phase-1 moon-phase-2
)
PROMPTS=(
  "calm ambient drone with soft ocean waves, warm analog pads, slow, meditative, no drums"
  "gentle underwater ambient, deep warm pads, distant whale-like tones, peaceful, no percussion"
  "airy ambient pads, high shimmering textures, floating above clouds, slow evolving, no percussion"
  "weightless atmospheric ambient, soft jet stream whoosh, glassy pads, serene, no drums"
  "foggy harbor ambient, low foghorn-like drones, gentle lapping water, peaceful, no drums"
  "maritime dawn ambient, warm brass-like drone swells, calm sea texture, no percussion"
  "minimal ambient with soft mechanical pulse, gentle ticking, hypnotic, quiet, slow"
  "subterranean ambient hum, rhythmic distant rumble, meditative transit, very quiet"
  "dark ambient deep drone, distant tectonic rumble, sparse low bell hits, cinematic, no rhythm"
  "vast planetary ambient, deep sub drone, slow seismic swells, awe, no percussion"
  "ethereal night ambient, soft glassy bells, very slow, lunar stillness, silence between notes"
  "moonlit ambient, delicate celesta-like tones over soft pad, dreamy, sparse, no drums"
)

mkdir -p "$DIR/musicgen"
cd "$MLX"

for i in "${!KEYS[@]}"; do
  out="$DIR/musicgen/${KEYS[$i]}.wav"
  if [ -f "$out" ]; then
    echo "skip ${KEYS[$i]} (exists)"
    continue
  fi
  echo "=== ${KEYS[$i]} ==="
  start=$(date +%s)
  "$PY" generate.py --model "$MODEL" --max-steps "$STEPS" \
    --text "${PROMPTS[$i]}" --output-path "$out"
  echo "    done in $(( $(date +%s) - start ))s → $out"
done

echo ""
echo "All outputs:"
ls -lh "$DIR/musicgen/"
