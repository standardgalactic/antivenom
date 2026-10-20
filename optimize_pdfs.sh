#!/usr/bin/env bash
set -euo pipefail

OUT=".pdf-optimization"
REPORT="$OUT/report.tsv"
mkdir -p "$OUT"

printf 'original_MiB\toptimized_MiB\tsaving_pct\tstatus\tpath\n' > "$REPORT"

while IFS= read -r -d '' pdf; do
    # Select PDFs with substantial non-JPEG raster images.
    if ! pdfimages -list "$pdf" 2>/dev/null |
        awk 'NR>2 && $3=="image" && $9!="jpeg" {
            if ($4>=500 && $5>=500) found=1
        } END {exit !found}'; then
        continue
    fi

    dest="$OUT/${pdf#./}"
    mkdir -p "$(dirname "$dest")"

    original=$(stat -c %s "$pdf")

    if ! gs -sDEVICE=pdfwrite \
        -dCompatibilityLevel=1.6 \
        -dNOPAUSE -dBATCH -dQUIET \
        -dAutoRotatePages=/None \
        -dDetectDuplicateImages=true \
        -dDownsampleColorImages=false \
        -dDownsampleGrayImages=false \
        -dAutoFilterColorImages=false \
        -dColorImageFilter=/DCTEncode \
        -dJPEGQ=85 \
        -sOutputFile="$dest" "$pdf"; then
        echo "FAILED: $pdf"
        rm -f "$dest"
        continue
    fi

    pages_before=$(pdfinfo "$pdf" | awk '/^Pages:/ {print $2}')
    pages_after=$(pdfinfo "$dest" | awk '/^Pages:/ {print $2}')

    if [[ "$pages_before" != "$pages_after" ]]; then
        echo "PAGE MISMATCH: $pdf"
        rm -f "$dest"
        continue
    fi

    optimized=$(stat -c %s "$dest")
    saving=$(awk -v a="$original" -v b="$optimized" \
        'BEGIN {printf "%.2f",100*(a-b)/a}')

    status="REVIEW"
    if awk -v s="$saving" 'BEGIN {exit !(s>=20)}'; then
        status="CANDIDATE"
    fi

    printf '%.2f\t%.2f\t%s\t%s\t%s\n' \
        "$(awk -v n="$original" 'BEGIN {print n/1048576}')" \
        "$(awk -v n="$optimized" 'BEGIN {print n/1048576}')" \
        "$saving" "$status" "$pdf" >> "$REPORT"

    echo "$saving%: $pdf"
done < <(
    find . -type f -iname '*.pdf' \
        -not -path './.git/*' \
        -not -path "./$OUT/*" -print0
)

echo
echo "Optimization report:"
column -t -s $'\t' "$REPORT"
