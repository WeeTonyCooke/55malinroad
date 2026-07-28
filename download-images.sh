#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# download-images.sh — fetch and resize placeholder images for 55 Malin Road
#
# Run this from inside ~/55malinroad/ BEFORE committing.
# Requires: curl (built-in macOS), sips (built-in macOS, resizes without deps)
#
# All images are sourced from Unsplash under the free Unsplash Licence.
# No attribution required, free for commercial use.
#
# After running, review each image in images/ visually before pushing.
# Replace any that don't suit with your own photography.
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

mkdir -p images

download_img() {
  local id="$1"
  local name="$2"
  local max_px="${3:-1600}"

  local dest="images/${name}.jpg"
  if [[ -f "$dest" ]]; then
    echo "  skipping ${name}.jpg (already exists)"
    return
  fi

  echo "  → ${name}.jpg  (unsplash:${id})"
  curl -sL \
    "https://unsplash.com/photos/${id}/download?force=true" \
    -o "$dest"

  # Verify the file is actually an image (not an HTML error/login page)
  if ! file "$dest" 2>/dev/null | grep -qiE "jpeg|image"; then
    echo "  ✗ ${name}.jpg failed (not an image — photo may require Unsplash login)"
    rm -f "$dest"
    return
  fi

  # Resize longest edge to max_px using macOS built-in sips (no ImageMagick needed)
  sips -Z "$max_px" "$dest" > /dev/null 2>&1 || true
}

echo "Downloading 11 images into images/ …"
echo ""

# ── Hero ──────────────────────────────────────────────────────────────────────
# Rugged Donegal coastline with green hills and the Atlantic
download_img "-m0t5fmOGoM"    "hero"                   2400

# ── Introduction ──────────────────────────────────────────────────────────────
# White cottage on a lush green Irish hillside
download_img "Twke63oNYM0"    "intro"                  1200

# ── The House — rooms ─────────────────────────────────────────────────────────
# Atlantic Room: rumpled white duvet and pillows on a bed, soft light
download_img "9IFbmglOszs"    "room-atlantic"          1600

# Garden Room: neatly made bed with white linen
download_img "ooDvIpnXkwo"    "room-garden"            1600

# ── Life Here — four cells ────────────────────────────────────────────────────
# Morning coffee: cup and bread on a window sill
download_img "igf2Wko-1M8"   "life-coffee"            1400

# Watching storms: powerful ocean waves crashing under a stormy sky
download_img "E7_woNgoG0k"    "life-storms"            1400

# The coast path: dramatic cliffs overlooking the Atlantic, cloudy sky
download_img "QevdTyAUa9o"    "life-coast"             1000

# By the fire: fire burning on a hearth
download_img "DI8Bf6K1134"    "life-fire"              1000

# ── Explore — three cards ─────────────────────────────────────────────────────
# Five Fingers Strand: wooden fence and dune grasses under a cloudy sky
download_img "3ct44j853ok"    "explore-five-fingers"   900

# Malin Head: rugged coastal rock formations with waves crashing
# (confirmed location: Malin Head, County Donegal, Ireland)
download_img "4IH2rRlCnKs"    "explore-malin-head"     900

# Local food: clam and vegetable chowder in a white ceramic bowl
download_img "SH8_JmrsQcw"    "explore-seafood"        900

echo ""
echo "Done. $(ls images/*.jpg 2>/dev/null | wc -l | tr -d ' ') images in images/"
echo ""
echo "Next steps:"
echo "  1. Open images/ and check each photo looks right"
echo "  2. Replace any that don't fit with your own photography"
echo "  3. git add images/ index.html && git commit -m 'Add local image assets'"
echo "  4. git push"
