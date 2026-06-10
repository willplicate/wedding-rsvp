#!/bin/bash
# Resize and add missing lowercase .jpg photos to the gallery, sorted by capture time
# Run from the wedding-rsvp directory

set -e
cd "$(dirname "$0")"

SRC="/Users/williamford/Documents/Wedding Photos B&W/Website"
PHOTOS_DIR="photos"
THUMBS_DIR="photos/thumbs"
BUCKET="lightjacket"

# Build list of all lowercase .jpg files sorted by EXIF capture time
SORTED_FILES=$(
  for f in "$SRC"/*.jpg; do
    [ -f "$f" ] || continue
    capture=$(mdls "$f" 2>/dev/null | grep "kMDItemContentCreationDate " | awk '{print $3, $4}')
    echo "$capture|$f"
  done | sort | awk -F'|' '{print $2}'
)

COUNT=$(echo "$SORTED_FILES" | wc -l | tr -d ' ')
echo "Found $COUNT lowercase .jpg files to add (sorted by capture time)."
echo ""

# Find next available sequential number
NEXT=$(ls "$PHOTOS_DIR"/*.jpg 2>/dev/null | grep -oE '[0-9]+\.jpg$' | sort -n | tail -1 | grep -oE '^[0-9]+')
NEXT=$((10#$NEXT + 1))
echo "Starting from: $(printf '%03d' $NEXT)"
echo ""

ADDED=0
while IFS= read -r SRC_FILE; do
  [ -z "$SRC_FILE" ] && continue
  PADDED=$(printf "%03d" $NEXT)
  DEST_FULL="$PHOTOS_DIR/${PADDED}.jpg"
  DEST_THUMB="$THUMBS_DIR/${PADDED}.jpg"

  BASENAME=$(basename "$SRC_FILE")
  CAPTURE=$(mdls "$SRC_FILE" 2>/dev/null | grep "kMDItemContentCreationDate " | awk '{print $3, $4}')
  echo "  $BASENAME ($CAPTURE) → ${PADDED}.jpg"

  # Resize full-size: max 1800px on long edge
  sips --resampleHeightWidthMax 1800 "$SRC_FILE" --out "$DEST_FULL" \
    -s format jpeg -s formatOptions 85 &>/dev/null

  # Resize thumbnail: max 600px on long edge
  sips --resampleHeightWidthMax 600 "$SRC_FILE" --out "$DEST_THUMB" \
    -s format jpeg -s formatOptions 80 &>/dev/null

  wrangler r2 object put "${BUCKET}/photos/${PADDED}.jpg" \
    --file "$DEST_FULL" --content-type "image/jpeg" --remote &>/dev/null \
    && echo "    ✓ uploaded photos/${PADDED}.jpg" \
    || echo "    ✗ FAILED: photos/${PADDED}.jpg"

  wrangler r2 object put "${BUCKET}/photos/thumbs/${PADDED}.jpg" \
    --file "$DEST_THUMB" --content-type "image/jpeg" --remote &>/dev/null \
    && echo "    ✓ uploaded photos/thumbs/${PADDED}.jpg" \
    || echo "    ✗ FAILED: photos/thumbs/${PADDED}.jpg"

  NEXT=$((NEXT + 1))
  ADDED=$((ADDED + 1))
done <<< "$SORTED_FILES"

NEW_TOTAL=$(ls "$PHOTOS_DIR"/*.jpg | grep -oE '[0-9]+\.jpg$' | sort -n | tail -1 | grep -oE '^[0-9]+' | sed 's/^0*//')
echo ""
echo "Done! Added $ADDED photos."
echo "New total: $NEW_TOTAL"
echo ""
echo "Update index.html: change  const TOTAL = 179  to  const TOTAL = $NEW_TOTAL"
