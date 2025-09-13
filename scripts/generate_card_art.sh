#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
SEED_FILE="$ROOT_DIR/backend/internal/repository/card_repository.go"
ART_DIR="$ROOT_DIR/assets/cards/art"
OVERLAYS_DIR="$ROOT_DIR/assets/cards/overlays"
BACKS_DIR="$ROOT_DIR/assets/cards/backs"
IMAGES_DIR="$ROOT_DIR/assets/images"

mkdir -p "$ART_DIR" "$OVERLAYS_DIR" "$BACKS_DIR" "$IMAGES_DIR"

# 1x1 transparent PNG (valid PNG data)
PNG_BASE64="iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO9H5iUAAAAASUVORK5CYII="

# Write a placeholder image to a given path
write_placeholder() {
  local out_path="$1"
  printf "%s" "$PNG_BASE64" | base64 -d > "$out_path"
}

# Parse card ids and colors from the Go seed file
# Extract card IDs by grepping ID lines; ignore colors for now
mapfile -t CARD_IDS < <(grep -oE 'ID\s*:\s*"[A-Za-z0-9_\-]+"' "$SEED_FILE" | sed -E 's/.*"([^"]+)"/\1/' | sort -u)

if [[ ${#CARD_IDS[@]} -eq 0 ]]; then
  echo "No cards found to generate art for. Exiting." >&2
  exit 1
fi

echo "Generating placeholder art for ${#CARD_IDS[@]} cards..."

for card_id in "${CARD_IDS[@]}"; do
  for res in low medium high; do
    out="$ART_DIR/${card_id}_standard_${res}.webp"
    write_placeholder "$out"
  done
done

# Overlays and backs placeholders
write_placeholder "$OVERLAYS_DIR/holographic_pattern.webp"
write_placeholder "$OVERLAYS_DIR/foil_etched_texture.webp"
write_placeholder "$BACKS_DIR/default_back.webp"
write_placeholder "$OVERLAYS_DIR/promo_stamp.png"

# Fallback UI placeholder image
write_placeholder "$IMAGES_DIR/placeholder_card_art.jpg"

echo "Done."

