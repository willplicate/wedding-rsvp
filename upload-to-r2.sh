#!/bin/bash
# Upload wedding photos and thumbnails to Cloudflare R2 bucket "lightjacket"
# Usage: ./upload-to-r2.sh
# Run from the wedding-rsvp directory

BUCKET="lightjacket"
PHOTOS_DIR="photos"
CONCURRENCY=10

cd "$(dirname "$0")"

if ! command -v wrangler &>/dev/null; then
  echo "Error: wrangler not found. Run: npm install -g wrangler"
  exit 1
fi

upload_file() {
  local local_path="$1"
  local r2_key="$2"
  wrangler r2 object put "${BUCKET}/${r2_key}" \
    --file "${local_path}" \
    --content-type "image/jpeg" \
    2>/dev/null && echo "  ✓ ${r2_key}" || echo "  ✗ FAILED: ${r2_key}"
}

export -f upload_file
export BUCKET

echo "Uploading full-size photos..."
ls "${PHOTOS_DIR}"/*.jpg | xargs -P $CONCURRENCY -I {} bash -c \
  'upload_file "$1" "photos/$(basename $1)"' _ {}

echo ""
echo "Uploading thumbnails..."
ls "${PHOTOS_DIR}/thumbs"/*.jpg | xargs -P $CONCURRENCY -I {} bash -c \
  'upload_file "$1" "photos/thumbs/$(basename $1)"' _ {}

echo ""
echo "Done! Update the BASE_URL in index.html with your R2 public URL."
