#!/usr/bin/env python3
"""
repair_wrap.py: undo the "repeated fragment at line break" artifact.

The artifact: a hard wrapper cut each long line at ~75 characters, then
restarted the next line at the beginning of the word it had cut, without
removing the fragment from the end of the previous line:

    hiring pr            <- fragment "pr" left behind
    processes—particularly ...

    such as a
    adaptability, imagination ...

    "...realities" by
    by
    by piecing together ...

Repair rule: if the last space-delimited token of line N is a prefix of
(or equal to) the first space-delimited token of line N+1, drop that token
from line N. If that empties line N, the line is deleted outright.

Details that matter:
  * Tokens are split on the ASCII space only. The corpus contains U+202F
    (narrow no-break space) inside tokens; str.split() would break there.
  * Comparisons use the ORIGINAL next line, so chains like by / by / by
    collapse correctly.
  * Blank lines are never touched (they are paragraph breaks).
  * Fragments made only of pipes or box-drawing characters are ignored,
    since table rows ending in "|" followed by rows starting with "|" are
    coincidences, not wrap damage.

Confidence tiers:
  A (certain)  the line is at least 74 characters long, i.e. it was really
               cut at the wrap width.
  B (likely)   a shorter line where the fragment is 4+ characters with a
               letter or digit in it, or a one-token line that exactly
               repeats the next line's first token. These occur in the
               narrower-wrapped stretches. Use --strict to skip them.

Usage:
    python3 repair_wrap.py INPUT.md [-o OUTPUT.md] [--strict] [--report REPORT.tsv]

Run it once on the raw file. Running it again on repaired output can remove
legitimate short words that happen to prefix the next line.
"""
import argparse
import sys

WRAP_MIN = 74  # lines this long were cut at the wrap width


def is_structural(tok: str) -> bool:
    """True for tokens made only of pipes / box-drawing characters."""
    return bool(tok) and all(
        c in "|│┃¦" or 0x2500 <= ord(c) <= 0x257F for c in tok
    )


def classify(a: str, b: str):
    """Return 'A', 'B' or None for the pair (line, next line)."""
    if not a.strip() or not b.strip():
        return None
    frag = a.split(" ")[-1]
    head = b.split(" ")[0]
    if not frag or not head or is_structural(frag):
        return None
    if not head.startswith(frag):
        return None
    if len(a) >= WRAP_MIN:
        return "A"
    has_alnum = any(c.isalnum() for c in frag)
    if has_alnum and len(frag) >= 4:
        return "B"
    if has_alnum and a.strip() == frag and head == frag:
        return "B"
    return None


def repair(lines, strict=False):
    out, report = [], []
    stats = {"A": 0, "B": 0, "dropped": 0}
    n = len(lines)
    for i, a in enumerate(lines):
        tier = classify(a, lines[i + 1]) if i + 1 < n else None
        if tier is None or (strict and tier == "B"):
            out.append(a)
            continue
        stats[tier] += 1
        frag = a.split(" ")[-1]
        fixed = a[: len(a) - len(frag)].rstrip(" ")
        if fixed.strip() == "":
            stats["dropped"] += 1
            report.append((i + 1, tier, "DROPPED", a, lines[i + 1]))
            continue
        out.append(fixed)
        if tier == "B":
            report.append((i + 1, tier, "trimmed", a, lines[i + 1]))
    return out, stats, report


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    ap.add_argument("input")
    ap.add_argument("-o", "--output")
    ap.add_argument("--strict", action="store_true",
                    help="only apply tier A (certain) repairs")
    ap.add_argument("--report", help="write tier B / dropped-line changes to a TSV")
    args = ap.parse_args()

    out_path = args.output or args.input.rsplit(".", 1)[0] + ".repaired.md"
    with open(args.input, encoding="utf-8", newline="") as f:
        text = f.read()
    lines = text.split("\n")

    fixed, stats, report = repair(lines, strict=args.strict)

    with open(out_path, "w", encoding="utf-8", newline="") as f:
        f.write("\n".join(fixed))

    print(f"lines in:        {len(lines)}")
    print(f"lines out:       {len(fixed)}")
    print(f"tier A repairs:  {stats['A']}")
    print(f"tier B repairs:  {stats['B']}" + (" (skipped, --strict)" if args.strict else ""))
    print(f"lines dropped:   {stats['dropped']}")
    print(f"wrote:           {out_path}")

    if args.report:
        with open(args.report, "w", encoding="utf-8") as f:
            f.write("line\ttier\taction\tbefore\tnext_line\n")
            for ln, tier, action, a, b in report:
                f.write(f"{ln}\t{tier}\t{action}\t{a!r}\t{b[:60]!r}\n")
        print(f"report:          {args.report} ({len(report)} rows)")


if __name__ == "__main__":
    sys.exit(main())

