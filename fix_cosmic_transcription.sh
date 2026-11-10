#!/usr/bin/env bash
# Correct transcription errors without rewriting the spoken discussion.
# Requires Python 3. Run beside the transcripts, or supply their paths.
# Usage: bash fix_cosmic_transcription.sh [--dry-run] [FILE ...]
set -euo pipefail
command -v python3 >/dev/null 2>&1 || { printf 'Python 3 is required.\n' >&2; exit 1; }
python3 - "$@" <<'PY'
import argparse
import difflib
import os
from pathlib import Path
import re
import shutil
import tempfile

parser = argparse.ArgumentParser(description='Fix known TXT/VTT transcription errors; preserve timestamps and create .bak backups.')
parser.add_argument('--dry-run', action='store_true', help='show changes without writing files')
parser.add_argument('files', nargs='*', help='defaults to the two How_Cosmic_Memory_Could_Replace_Inflation files')
args = parser.parse_args()
paths = [Path(p) for p in (args.files or [
    'How_Cosmic_Memory_Could_Replace_Inflation.txt',
    'How_Cosmic_Memory_Could_Replace_Inflation.vtt',
])]
if len({p.resolve() for p in paths}) != len(paths):
    parser.error('The same file was supplied more than once.')
for path in paths:
    if not path.is_file() or path.suffix.lower() not in {'.txt', '.vtt'}:
        parser.error(f'Expected an existing .txt or .vtt file: {path}')

# Vocabulary checked against expyrotic_cosmology.pdf. Correct the K-spelled
# theory in context BEFORE normalizing the X-spelled theory's other variants.
# Scientific assertions, analogies and numerical results remain as spoken.
rules = [
    (r'\ban expirotic model, spelled with a K\b', 'an ekpyrotic model, spelled with a K'),
    (r'\bThose expirotic models\b', 'Those ekpyrotic models'),
    (r'\bExporotic\b', 'Expyrotic'),
    (r'\bExpirotic\b', 'Expyrotic'),
    (r'\bexpirotic\b', 'expyrotic'),
    (r'\bA powerotic cosmology\b', 'Expyrotic cosmology'),
    (r'\bthe sporadic model\b', 'the expyrotic model'),
    (r'\bexpirative cosmology\b', 'expyrotic cosmology'),
    (r'\bEx-prodict cosmology\b', 'Expyrotic cosmology'),
    (r'\bEkbrotic cosmology\b', 'Expyrotic cosmology'),
    (r'\bExpriorotic cosmology\b', 'Expyrotic cosmology'),
    (r'\ba product cosmology\b', 'expyrotic cosmology'),
    (r'\bekpilonic cosmology\b', 'expyrotic cosmology'),
    (r'\bFlightian\b', 'Flyxion'),
    (r'\bAndres Albrecht\b', 'Andreas Albrecht'),
    (r'\bStorobinsky\b', 'Starobinsky'),
    (r'\bChypysov\b', 'Chibisov'),
    (r'\bAndré Poincaré\b', 'Henri Poincaré'),
    (r"\bCax's lemma\b", "Kac's lemma"),
    (r'\bhigher dimensional brains\b', 'higher dimensional branes'),
    (r'\bRelativistic Scalar Vector Planum\b', 'Relativistic Scalar Vector Plenum'),
    (r'\bthe PMP\b', 'the CMB'),
    (r'\bthe lowest multiples\b', 'the lowest multipoles'),
    (r'\bthey devise standard predictions\b', 'they defy standard predictions'),
    (r'\bepics of reintegration\b', 'epochs of reintegration'),
    (r'\bthe EPIC structure\b', 'the epoch structure'),
    (r'\bthese EPICs\b', 'these epochs'),
    (r'\bThere is a counterfeit on\b', 'There is a counterpart on'),
    (r'\bCOBE-FUROS\b', 'COBE-FIRAS'),
    (r'\bsqueezed-by-spectrum\b', 'squeezed-bispectrum'),
    (r'\bLightbird\b', 'LiteBIRD'),
    (r'\bReproduce Ichpyrosis StopPy\b', 'reproduce_expyrosis.py'),
    (r'\bhomogenous source\b', 'homogeneous source'),
    (r'\bstandard scale invariants\b', 'standard scale invariance'),
    (r'\bwhich is why a Flyxion\b', 'which is why Flyxion'),
    (r'\bThe physics only survive the natural damping\b', 'The physics only survive if the natural damping'),
]

plans = []
for path in paths:
    original_bytes = path.read_bytes()
    original = original_bytes.decode('utf-8')
    lines = original.splitlines(keepends=True)
    counts = [0] * len(rules)
    for index, line in enumerate(lines):
        # Do not touch VTT timing, cue identifiers, headers or metadata blocks.
        if path.suffix.lower() == '.vtt':
            continue  # VTT text is handled block by block below.
        for rule_index, (pattern, replacement) in enumerate(rules):
            line, count = re.subn(pattern, replacement, line)
            counts[rule_index] += count
        lines[index] = line
    if path.suffix.lower() == '.vtt':
        in_cue = False
        metadata = False
        for index, line in enumerate(lines):
            stripped = line.strip()
            if not stripped:
                in_cue = False
                metadata = False
                continue
            if metadata:
                continue
            if stripped == 'NOTE' or stripped.startswith('NOTE ') or stripped in {'STYLE', 'REGION'}:
                metadata = True
                continue
            if '-->' in line:
                in_cue = True
                continue
            if not in_cue:
                continue
            for rule_index, (pattern, replacement) in enumerate(rules):
                line, count = re.subn(pattern, replacement, line)
                counts[rule_index] += count
            lines[index] = line
    corrected = ''.join(lines)
    if len(original.splitlines()) != len(corrected.splitlines()):
        raise RuntimeError(f'Line count changed: {path}')
    if path.suffix.lower() == '.vtt':
        assert [s for s in original.splitlines() if '-->' in s] == [s for s in corrected.splitlines() if '-->' in s]
    plans.append((path, original_bytes, original, corrected, counts))

for path, original_bytes, original, corrected, counts in plans:
    if corrected == original:
        print(f'{path}: no changes needed')
        continue
    print(f'{path}: {sum(counts)} corrections')
    if args.dry_run:
        print(''.join(difflib.unified_diff(original.splitlines(keepends=True), corrected.splitlines(keepends=True), fromfile=str(path), tofile=str(path) + ' (corrected)')), end='')
        continue
    backup = Path(str(path) + '.bak')
    # Keep the first backup forever; refuse to overwrite it on subsequent runs.
    try:
        with backup.open('xb') as handle:
            handle.write(original_bytes)
        shutil.copystat(path, backup)
    except FileExistsError:
        pass
    descriptor, temporary = tempfile.mkstemp(prefix='.' + path.name + '.', dir=path.parent)
    try:
        with os.fdopen(descriptor, 'wb') as handle:
            handle.write(corrected.encode('utf-8'))
        os.chmod(temporary, path.stat().st_mode & 0o777)
        os.replace(temporary, path)
    finally:
        if os.path.exists(temporary):
            os.unlink(temporary)
    print(f'  Updated; original backup: {backup}')
PY
