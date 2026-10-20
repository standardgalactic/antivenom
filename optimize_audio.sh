#!/usr/bin/env bash
set -euo pipefail

MODE="${1:---dry-run}"
TARGET_KBPS="${TARGET_KBPS:-64}"
MIN_KBPS="${MIN_KBPS:-120}"
MIN_SAVING="${MIN_SAVING:-15}"
OUT=".audio-optimization"
REPORT="$OUT/report.tsv"

case "$MODE" in
  --dry-run|--encode|--apply) ;;
  *)
    echo "Usage: $0 [--dry-run|--encode|--apply]"
    exit 1
    ;;
esac

command -v ffmpeg >/dev/null
command -v ffprobe >/dev/null
mkdir -p "$OUT"

if [[ "$MODE" == --apply ]] &&
   [[ -n "$(git status --porcelain)" ]]; then
  echo "Refusing to apply with a dirty Git working tree."
  exit 1
fi

printf 'original_bytes\toptimized_bytes\tsaving_pct\tpath\n' > "$REPORT"

while IFS= read -r -d '' file; do
  bitrate=$(ffprobe -v error \
    -select_streams a:0 \
    -show_entries stream=bit_rate \
    -of default=nw=1:nk=1 "$file" | head -1)

  [[ "$bitrate" =~ ^[0-9]+$ ]] || continue
  (( bitrate >= MIN_KBPS * 1000 )) || continue

  original=$(stat -c %s "$file")
  dest="$OUT/${file#./}"
  mkdir -p "$(dirname "$dest")"

  if [[ "$MODE" == --dry-run ]]; then
    echo "Candidate: $file (${bitrate} bps)"
    continue
  fi

  if [[ "$MODE" == --encode ]] || [[ ! -f "$dest" ]]; then
    ffmpeg -nostdin -hide_banner -loglevel error \
      -y -i "$file" -map 0:a:0 -vn \
      -ac 1 -ar 44100 \
      -codec:a libmp3lame -b:a "${TARGET_KBPS}k" \
      -map_metadata 0 \
      "$dest"
  fi

  ffmpeg -v error -i "$dest" -f null - </dev/null
  optimized=$(stat -c %s "$dest")

  saving=$(awk -v a="$original" -v b="$optimized" \
    'BEGIN {printf "%.2f",100*(a-b)/a}')

  printf '%s\t%s\t%s\t%s\n' \
    "$original" "$optimized" "$saving" "$file" >> "$REPORT"

  echo "$saving% saving: $file"

  if [[ "$MODE" == --apply ]]; then
    if awk -v s="$saving" -v m="$MIN_SAVING" \
      'BEGIN {exit !(s>=m)}'; then
      mv -f -- "$dest" "$file"
    fi
  fi
done < <(
  find . -type f -iname '*.mp3' \
    -not -path './.git/*' \
    -not -path "./$OUT/*" -print0
)

echo "Report: $REPORT"
