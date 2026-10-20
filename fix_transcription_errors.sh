#!/usr/bin/env bash
set -euo pipefail

REPLACEMENT="Flyxion"
LOG_FILE="corrections.log"
POLYXAN_PATTERN="Paul Exam|Polluxan|Pollack['’]s end|Polluxian|Polluxen|polyxand|polysync"
CANDIDATE_FILE="$(mktemp)"
VIM_SCRIPT="$(mktemp)"
MATCH_FILE="$(mktemp)"

PATTERN='FLECTION|FLICTION|Phlyxion|Phlyxian|Phlycaxion|Phloxen|Phleoxian|Fleichshind|Felican|Felician|Felictian|Felixian|Flexen|Fleixen|Flaccion|Flagellian|Flakirin|Flakiron|Flaxian|Flaixion|Flixnian|Flaxion|Flaxi|Flaxon|Flaxen|Flaxson|Fleckession|Fleckstown|Flection|Flectional|Fleekshin|Fleishness|Fleishon|Flisheen|Flixenian|Fluxinian|Fleixing|Fleksheen|Flekshun|Fleksian|Fleksion|Flekzion|Fletchen|Fletcher|Fleischer|Fletchian|Fletchion|Fletian|Fletuchin|Flexian|Flexion|Flexition|Flexiton|Flexivision|Flextion|Flexumian|Fleikshen|Fliccine|Flickditschian|Flickenden|Flickening|Flickession|Flickian|Flickiewen|Flickishin|Flicklian|Flickpnam|Flickrinnian|Flickshahn|Flicksham|Flickshan|Flickshane|Flickshank|Flickshanth|Flicksheen|Flicksheens|Flickshen|Flickshenman|Flickshian|Flickshin|Flickshion|Flickshon|Flicksion|Flickson|Flicksonin|Flickshorn|Flickstahn|Flickstein|Flickxion|Flickzion|Fliction|Flictionon|Fleissingen|Flijnen|Flikshun|Flikstian|Flikxion|Flikzion|Flinchin|Flipchin|Flipchian|Flippshen|Flyaction|Flyoxon|Flyaxon|Flaregon|Fladiero|Flipschen|Flischin|Flisham|Flishan|Flishen|Flitchian|Flitchin|Flitchinan|Flitian|Flitschen|Flixton|Flixenum|Fleekshian|Flickshone|Flixieman|Fliximmon|Flyon|Flyshon|FlyExxon|Flanaxon|Flyxón|Flycone|Flicksheim|Flickshinen|Flieckshien|Flixioon|Flickshim|Flitching|Flitscheon|Flywitz and|Flitschernard|Flitschian|Flixam|Flixan|Flixbyan|Flixchan|Flixchen|Fleishian|Fleissing|Fly Agassine|Flagg-Messon|Fleixchen|Flyekson|Floxquan|Flagson|Flixen|Flixgen|Flixcher|Flixheen|Flixia|flixian|Flickin|Flixidan|Flixie|Flixien|Flixim|Flixin|Flixing|Flixingen|Flixshink|Flixion|Florixian|Flixionne|Flixium|Flixjan|Flixman|Flixon|Flixson|Flixten|Flixtion|Flixuen|Flixxion|Flixxon|Flixyon|Floodioxin|Fluxian|Fluxin|Fluxion|Fluxium|Fluxunian|FlykemFlykshion|Flykshun|Flyxen|Flyxian|Flyxionn|Flyxionne|Flyxionu|Flyzion|Flickstone|Folicurian|Fouiches|Fuchin|Fugchin|Fuggeshin|Flickjino|Liction|Slikin|Klixian|Flisher|Flisker|Flyarian|Flyarion|Flick Sheenan|Flick Sheehan|Flick Sheenum|Flick Sheen|Flyluzen|Phlyoxian|Phlyoxion|Flyzon|Fligerson|Fleisinger|Flanagan|Flyxene|Flykon|Flaxodin|Flaixson|Flickshman|flictions|flitchton|Flagarian|Flaggy and|Flagg-Zion|Floxium|Flymoxon|Flyaxiom|Fly Luxon|Flickeron|Flixionet|flickshione|FlexSign|Flickon|Flickshina|Flickshind|Flinction|Flixine|Flypexun|Flyson|Flegsen|Flickshenand|Flickshinn|Flixiana|Flickshenon|Vleitchin|flickshun|Flybian|flickshent|flikshin|flaction|flicion|flickshine|flickshing|flipchon|flishon|flixikin|flexemian|fliccion|flickshinian|flickshmer|flixenium|flixirin|flexton|flickaon|flickshaneer|flickshenian|flickshinin|flickshund|flickton|flippton|flixene|flixenon|flixinet|flixingin|flixiny|flixionin|flixionit|flixixion|fluxen|flickshun|flickshent|flikshin|flaction|flicion|flickshine|flickshing|flipchon|flishon|flakshion|flixikin|flexemian|fliccion|flickshaw|flickshinian|flickshmer|flixenium|flixirin|flexine|flexton|flickaon|flickshaneer|flicksheet|flickshenian|flickshinin|flickshund|flickton|flippton|flixene|flixenon|flixinet|flixingin|flixiny|flixionin|flixionit|flixixion|fluxen|flaikshen|flakion|flaskions|flaxleon|fleifson|flexan|flexchina|flexiz|flication|flickshaman|flickshamers|flickshanine|flickshannon|flickshant|flickshawn|flickshe|flickshie|flickshemia|flickshenow|flickshien|flickshigen|flickshinkues|flickshire|flykshin|flickshound|flickshow|flickshum|flictiona|flipption|flipsion|fliption|flission|flitchorn|flitton|flixation|flixenden|floxian|flixens|flixentian|fliximian|flixinen|flixinian|flixio|flixional|flixionian|flixions|flixit|flixition|flixivision|flixn|flixorin|flixsonen|flixtreon|flotition|flushion|fluxena|fluxenia|fluxim|fluxina|fluxinan|fluxunon|flykeon|flyon|flyexon|flygon|flyorson|flison|flyosyn|flyoxing|flyseon|flyseons|flyshon|flyxi|flyxon|flyoxin|flyaxium|flyaxian|flyoxian|flayoxian|flamixion|flyjan|flycon|flybonian|flyzeon|flimixian|flexio|fleixion|floxion|fletion|flaxo|fleixian|flygeon|fleoxian|flyex|flyloxian|flyloxion|flycorn|flexon|flysion|flyoxion|flyaxion|flamaxion|flamaxian|flyskian|foxian|flyox|flyota|fliaxin|flagon|fleixson|fleisson|flyixian|flygation|flyana|flaydon|flyocean|flymicazon|lexen|flaxseed|Fleischmann'

cleanup() {
  rm -f "$CANDIDATE_FILE" "$VIM_SCRIPT" "$MATCH_FILE"
}
trap cleanup EXIT

############################################
# Counters / timing
############################################

FILES_SCANNED=0
FILES_UPDATED=0
FILES_UNCHANGED=0
SECONDS=0

############################################
# Backup snapshot
############################################

TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_DIR="backup_$TIMESTAMP"

echo "Creating backup snapshot: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

while IFS= read -r -d '' file; do
  mkdir -p "$BACKUP_DIR/$(dirname "$file")"
  cp "$file" "$BACKUP_DIR/$file"
done < <(find . -type f \( \
  -name "*.json" -o -name "*.srt" -o -name "*.tsv" -o -name "*.txt" -o -name "*.vtt" \
\) ! -path "./backup_*/*" -print0)

echo "Backup complete."

############################################
# Logging init
############################################

{
  echo ""
  echo "================================================================"
  echo "Flyxion correction run - $(date '+%Y-%m-%d %H:%M:%S')"
  echo "Backup snapshot: $BACKUP_DIR"
  echo "================================================================"
} >> "$LOG_FILE"

############################################
# Interactive name/concept disambiguation
#
# Scanning happens on .txt only (the source transcripts). When a match
# is confirmed as the name ("n"), the same word swap is propagated by
# context match into any sibling .vtt/.srt/.json files that share the
# same basename, since those were generated together from the same text.
############################################

echo "---- Interactive disambiguation: affliction / infliction / fiction / friction (txt only, propagated to vtt/srt/json) ----"

while IFS= read -r -d '' file; do
  python3 - "$file" "$LOG_FILE" <<'PY'
import sys
import re
import os

filename = sys.argv[1]
log_file = sys.argv[2]
pattern = re.compile(r'\b(affliction|infliction|fiction|friction)\b', re.IGNORECASE)

try:
    tty = open("/dev/tty")
except Exception:
    sys.exit(0)

def ask(prompt):
    print(prompt, end='', flush=True)
    return tty.readline().strip().lower()

try:
    with open(filename, "r", encoding="utf-8", errors="ignore") as f:
        lines = f.readlines()
except Exception:
    sys.exit(0)

modified = False
log_entries = []
quit_requested = False

base, _ = os.path.splitext(filename)
sibling_exts = (".vtt", ".srt", ".json")
sibling_files = [base + ext for ext in sibling_exts if os.path.exists(base + ext)]

# Tracks how far into each sibling file we've already consumed, so that
# repeated identical context phrases don't all collapse onto the first hit.
sibling_cursor = {}

def propagate(matched_word, context_words, replacement_word):
    if not sibling_files or not context_words:
        return
    ctx_pattern = re.compile(r'\s+'.join(re.escape(w) for w in context_words), re.IGNORECASE)
    word_pattern = re.compile(re.escape(matched_word), re.IGNORECASE)

    for sib in sibling_files:
        try:
            with open(sib, "r", encoding="utf-8", errors="ignore") as sf:
                content = sf.read()
        except Exception:
            continue

        start = sibling_cursor.get(sib, 0)
        m = ctx_pattern.search(content, start)
        if not m:
            m = ctx_pattern.search(content)  # fall back to a full-file search
        if not m:
            log_entries.append(f"  [propagate] no match in {sib} for context: {' '.join(context_words)}")
            continue

        span_text = m.group(0)
        new_span = word_pattern.sub(replacement_word, span_text, count=1)
        if new_span == span_text:
            continue

        new_content = content[:m.start()] + new_span + content[m.end():]
        sibling_cursor[sib] = m.start() + len(new_span)

        with open(sib, "w", encoding="utf-8") as sf:
            sf.write(new_content)
        log_entries.append(f"  [propagate] {sib}: \"{span_text}\" -> \"{new_span}\"")

for i, line in enumerate(lines):
    if pattern.search(line):
        print("\n---")
        print(f"{filename}:{i+1}")
        print(line.strip())

        while True:
            resp = ask("Is this the name (n) or the concept (c)? [n/c/skip/quit]: ")
            if resp in ("n", "c", "skip", "quit"):
                break

        if resp == "quit":
            quit_requested = True
            break

        if resp == "n":
            original = line.strip()
            match = pattern.search(line)
            matched_word = match.group(0)

            words = line.split()
            target_idx = None
            for idx, w in enumerate(words):
                if matched_word.lower() in w.lower():
                    target_idx = idx
                    break

            if target_idx is not None:
                context_before = words[max(0, target_idx - 3):target_idx]
                context_after = words[target_idx + 1:target_idx + 4]
                context_words = context_before + [words[target_idx]] + context_after
            else:
                context_words = [matched_word]

            lines[i] = line[:match.start()] + "Flyxion" + line[match.end():]
            modified = True
            log_entries.append(f"  L{i+1}: {original}")
            log_entries.append(f"        -> {lines[i].strip()}")

            propagate(matched_word, context_words, "Flyxion")
        else:
            log_entries.append(f"  L{i+1}: kept as-is [{resp}]: {line.strip()}")

if modified:
    with open(filename, "w", encoding="utf-8") as f:
        f.writelines(lines)
    print(f"Updated (name/concept pass): {filename}")

if log_entries:
    with open(log_file, "a", encoding="utf-8") as lf:
        lf.write(f"\n[name/concept] {filename}\n")
        lf.write("\n".join(log_entries) + "\n")

if quit_requested:
    print("Disambiguation stopped early for this file (quit).")
PY
done < <(find . -type f -name "*.txt" ! -path "./backup_*/*" -print0)

############################################
# Vim script
############################################

cat > "$VIM_SCRIPT" <<EOF
let g:flyxion_matches = []
g/\\v\\c(^|[^A-Za-z])(${PATTERN})([^A-Za-z]|$)/call add(g:flyxion_matches, line('.') . "\\x01" . getline('.'))
g/\\v\\cMediaCoins/call add(g:flyxion_matches, line('.') . "\\x01" . getline('.'))
g/\\v\\coblocosm/call add(g:flyxion_matches, line('.') . "\\x01" . getline('.'))
call writefile(g:flyxion_matches, '${MATCH_FILE}')
%s/\\v\\c(^|[^A-Za-z])(${PATTERN})([^A-Za-z]|$)/\\1${REPLACEMENT}\\3/g
%s/\\v\\c(in|of|af|am|an|at|to)(flyxion)/\\1 Flyxion/g
%s/\\v\\coblocosm/oblicosm/g
%s/\\v\\cMediaCoins/Media Quines/g
%s/\\v\\bsphere[ ]+pop\\b/spherepop/g
%s/\v\c<Zeem's scaled>/zoom-scaled/g
%s/\v\c<Happo Praxis>/Haplopraxis/g
%s/\v\c<haphopraxis>/Haplopraxis/g
g/\v\c<Pollack Sandpaper>/call add(g:flyxion_matches, line('.') . "\x01" . getline('.'))
%s/\v\c<Pollack Sandpaper>/Polyxan paper/g
g/\v\c<(${POLYXAN_PATTERN})>/call add(g:flyxion_matches, line('.') . "\x01" . getline('.'))
%s/\v\c<(${POLYXAN_PATTERN})>/Polyxan/g
wq!
EOF

############################################
# Main normalization pass
############################################

while IFS= read -r -d '' file; do
  case "$file" in
    *.json|*.srt|*.tsv|*.txt|*.vtt)

      FILES_SCANNED=$((FILES_SCANNED + 1))

      before_hash="$(sha256sum "$file" | awk '{print $1}')"

      : > "$MATCH_FILE"
      vim -Es "$file" -S "$VIM_SCRIPT" >/dev/null 2>&1 || true

      after_hash="$(sha256sum "$file" | awk '{print $1}')"

      if [ "$before_hash" != "$after_hash" ]; then
        FILES_UPDATED=$((FILES_UPDATED + 1))
        match_count=0

        {
          echo ""
          echo "[substitution] $file"
        } >> "$LOG_FILE"

        if [ -s "$MATCH_FILE" ]; then
          while IFS=$'\x01' read -r lineno before_text; do
            [ -z "$lineno" ] && continue
            if [[ "$file" == *.json ]]; then
              printf '  L%s: [JSON content omitted]\n' "$lineno" >> "$LOG_FILE"
            else
              printf '  L%s: %s\n' "$lineno" "$before_text" >> "$LOG_FILE"
            fi
            match_count=$((match_count + 1))
          done < "$MATCH_FILE"
        fi

        echo "  ($match_count line(s) changed)" >> "$LOG_FILE"
        echo "Updated: $file"
      else
        FILES_UNCHANGED=$((FILES_UNCHANGED + 1))
      fi

      python3 -c '
import sys, difflib, re

target = "flyxion"
threshold = 0.60
filename = sys.argv[1]

prefixes = (
    "fl", "fly", "fli", "fle", "flu",
    "flek", "flex", "flix", "flux",
    "flyk", "flet", "flic", "flit"
)

try:
    with open(filename, "r", encoding="utf-8", errors="ignore") as fh:
        for line in fh:
            for w in re.findall(r"[A-Za-z]{5,18}", line):
                lw = w.lower()

                if lw == target:
                    continue

                if not lw.startswith(prefixes):
                    continue

                score = difflib.SequenceMatcher(None, lw, target).ratio()

                if score >= threshold or any(x in lw for x in ("xion", "xian", "xen", "zion", "ksh", "shun", "shion")):
                    print(lw)
except Exception:
    pass
' "$file" >> "$CANDIDATE_FILE"

      ;;
  esac
done < <(find . -type f ! -path "./backup_*/*" -print0)

############################################
# Candidate aggregation
############################################

if [ -s "$CANDIDATE_FILE" ]; then
  CANDIDATE_COUNT="$(sort -u "$CANDIDATE_FILE" | wc -l | tr -d ' ')"
  {
    echo ""
    echo "==== Candidate Variants (aggregated, $CANDIDATE_COUNT unique) ===="
    sort "$CANDIDATE_FILE" | uniq -c | sort -nr
  } >> "$LOG_FILE"
else
  CANDIDATE_COUNT=0
  echo "" >> "$LOG_FILE"
  echo "==== Candidate Variants (none found) ====" >> "$LOG_FILE"
fi

############################################
# Summary
############################################

{
  echo ""
  echo "==== Summary ===="
  echo "Files scanned        : $FILES_SCANNED"
  echo "Files updated        : $FILES_UPDATED"
  echo "Files unchanged      : $FILES_UNCHANGED"
  echo "Unique candidates    : $CANDIDATE_COUNT"
  echo "Elapsed time         : ${SECONDS}s"
  echo ""
  echo "================================================================"
  echo "Run complete at $(date '+%Y-%m-%d %H:%M:%S')"
  echo "================================================================"
} >> "$LOG_FILE"

echo "Done. Log written to: $LOG_FILE"
echo "Backup saved to: $BACKUP_DIR"

