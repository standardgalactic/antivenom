#!/usr/bin/env bash

REPORT="report.txt"

{
echo "============================================================"
echo "GIT REPOSITORY ARCHAEOLOGY REPORT"
echo "Generated: $(date)"
echo "Repository: $(basename "$(git rev-parse --show-toplevel)")"
echo "============================================================"
echo

echo "=== OVERVIEW ==="

echo "Total commits:"
git rev-list --count HEAD
echo

echo "First commit:"
git log --reverse --oneline | head -1
echo

echo "Latest commit:"
git log -1 --oneline
echo

echo "Repository age:"
first_date=$(git log --reverse --format=%ad --date=short | head -1)
last_date=$(git log -1 --format=%ad --date=short)
echo "First commit date : $first_date"
echo "Latest commit date: $last_date"
echo

echo "=== AUTHORS ==="
git shortlog -sne
echo

echo "=== COMMITS PER MONTH ==="
git log --date=format:'%Y-%m' --format='%ad' |
sort |
uniq -c
echo

echo "=== MOST PRODUCTIVE DAYS ==="
git log --date=short --format='%ad' |
sort |
uniq -c |
sort -nr |
head -20
echo

echo "=== TOTAL LINE CHANGES ==="
git log --numstat --format='' |
awk '
{
if ($1 ~ /^[0-9]+$/) add += $1;
if ($2 ~ /^[0-9]+$/) del += $2;
}
END {
print "Insertions:", add;
print "Deletions :", del;
print "Net       :", add-del;
}'
echo

echo "=== COMMIT MESSAGE FREQUENCY ==="
git log --format="%s" |
sort |
uniq -c |
sort -nr |
head -50
echo

echo "=== ARTIFACT TAXONOMY ==="
git log --format="%s" |
grep '^Add ' |
sed 's/:.*//' |
sort |
uniq -c |
sort -nr
echo

echo "=== PUBLICATION INVENTORY ==="
for ext in tex pdf mp3 wav flac txt srt vtt tsv json aux log toc idx out xdv fls fdb_latexmk
do
    count=$(git log --name-only --format='' | grep -i "\.${ext}$" | sort -u | wc -l)
    printf "%-15s %8d\n" "$ext" "$count"
done

echo

echo "=== PUBLICATION PIPELINE RATIOS ==="

echo -n "Source Artifacts      : "
git log --format="%s" | grep -c "^Add source artifact"

echo -n "Publication Artifacts : "
git log --format="%s" | grep -c "^Add publication artifact"

echo -n "Build Artifacts       : "
git log --format="%s" | grep -c "^Add build state artifact"

echo -n "Trace Artifacts       : "
git log --format="%s" | grep -c "^Add process trace artifact"

echo -n "Transcript Artifacts  : "
git log --format="%s" | grep -c "^Add transcript artifact"

echo -n "Audio Artifacts       : "
git log --format="%s" | grep -c "^Add audio artifact"

echo -n "Metadata Artifacts    : "
git log --format="%s" | grep -c "^Add metadata artifact"

echo -n "Subtitle Artifacts    : "
git log --format="%s" | grep -c "^Add subtitle artifact"

echo -n "Alignment Artifacts   : "
git log --format="%s" | grep -c "^Add alignment artifact"

echo
echo

echo "=== PUBLICATION PROJECTS DISCOVERED ==="

git log --name-only --format='' |
grep '.' |
sed 's/.[^.]*$//' |
sort |
uniq -c |
sort -nr |
head -100

echo

echo "=== DIGITAL PRESERVATION INDEX ==="

sources=$(git log --name-only --format='' |
grep -i '.tex$' |
sort -u |
wc -l)

pdfs=$(git log --name-only --format='' |
grep -i '.pdf$' |
sort -u |
wc -l)

transcripts=$(git log --name-only --format='' |
grep -i '.txt$' |
sort -u |
wc -l)

captions=$(git log --name-only --format='' |
grep -Ei '.(srt|vtt)$' |
sort -u |
wc -l)

metadata=$(git log --name-only --format='' |
grep -i '.json$' |
sort -u |
wc -l)

alignments=$(git log --name-only --format='' |
grep -i '.tsv$' |
sort -u |
wc -l)

echo "Source files       : $sources"
echo "PDF publications   : $pdfs"
echo "Transcripts        : $transcripts"
echo "Captions/Subtitles : $captions"
echo "Metadata files     : $metadata"
echo "Alignment files    : $alignments"

if [ "$pdfs" -gt 0 ]; then
ratio=$(awk "BEGIN { printf "%.2f", $sources / $pdfs }")
echo "Source/PDF ratio   : $ratio"
fi

echo

echo "=== FILE EXTENSIONS ==="

git log --name-only --format='' |
grep '.' |
sed 's/.*.//' |
sort |
uniq -c |
sort -nr |
head -100

echo

echo "=== MOST MODIFIED FILES ==="

git log --name-only --format='' |
grep . |
sort |
uniq -c |
sort -nr |
head -100

echo

echo "=== TOP 25 LARGEST COMMITS ==="

git log --shortstat --format="%H|%ad|%s" --date=short |
awk -F'|' '
BEGIN { OFS="|" }

/^[0-9a-f]{40}\|/ {
    commit=$1
    date=$2
    subject=$3
}

/files changed/ {
    ins=0
    del=0

    if (match($0,/([0-9]+) insertion/,m))
        ins=m[1]

    if (match($0,/([0-9]+) deletion/,m))
        del=m[1]

    print ins,del,date,commit,subject
}
' |
sort -nr |
head -25

echo

echo "=== COMMIT TIMELINE ==="

git log --reverse --format='%ad %h %s' --date=short

echo

echo "=== CONCEPT VS ARTIFACT COMMITS ==="

git log --format="%s" |
awk '
/artifact/ {artifact++}
!/artifact/ {other++}
END {
print "Artifact commits:", artifact
print "Other commits   :", other
}'

echo

echo "============================================================"
echo "END OF REPORT"
echo "============================================================"

} | tee "$REPORT"

