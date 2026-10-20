#!/usr/bin/env bash
set -euo pipefail

OUT="${1:-media-audit.tsv}"
printf 'bytes\tMiB\ttype\tbitrate_kbps\tchannels\tduration_s\tpath\n' > "$OUT"

find . -type f \
  \( -iname '*.jpg' -o -iname '*.jpeg' \
     -o -iname '*.pdf' -o -iname '*.mp3' \) \
  -not -path './.git/*' -print0 |
while IFS= read -r -d '' file; do
    bytes=$(stat -c %s "$file")
    mib=$(awk -v n="$bytes" 'BEGIN {printf "%.2f",n/1048576}')
    ext="${file##*.}"
    ext="${ext,,}"
    bitrate="-"
    channels="-"
    duration="-"

    if [[ "$ext" == mp3 ]] && command -v ffprobe >/dev/null; then
        info=$(ffprobe -v error \
          -select_streams a:0 \
          -show_entries stream=bit_rate,channels:format=duration \
          -of default=noprint_wrappers=1 "$file" || true)
        bitrate=$(awk -F= '$1=="bit_rate" {printf "%.0f",$2/1000;exit}' <<< "$info")
        channels=$(awk -F= '$1=="channels" {print $2;exit}' <<< "$info")
        duration=$(awk -F= '$1=="duration" {printf "%.0f",$2;exit}' <<< "$info")
    fi

    printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
      "$bytes" "$mib" "$ext" \
      "${bitrate:--}" "${channels:--}" \
      "${duration:--}" "$file" >> "$OUT"
done

{
    head -n 1 "$OUT"
    tail -n +2 "$OUT" | sort -t $'\t' -k1,1nr
} > "${OUT}.sorted"

mv "${OUT}.sorted" "$OUT"

echo "Largest 30 media files:"
head -n 31 "$OUT" | column -t -s $'\t'
echo
echo "Total working-tree media size:"
awk -F'\t' 'NR>1 {sum+=$1;n++} END {
printf "%d files, %.2f GiB\n",n,sum/1073741824
}' "$OUT"
