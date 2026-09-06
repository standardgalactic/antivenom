from pathlib import Path

root = Path('/home/bonobo/antivenom/philosophy')

replacements = {
    'chapters/ch047.tex': [(
        "\\operatorname{Continue}.\n\\]\nEach term has its own formal role.",
        "\\operatorname{Continue}.\n\\]\n\\Definition\\ where each operator names a distinct institutional stage rather than an entailment.\nEach term has its own formal role."
    )],
    'chapters/ch048.tex': [(
        "\\mathsf B\\circ\\mathsf C.\n\\]\nIn most legal settings they do not.",
        "\\mathsf B\\circ\\mathsf C.\n\\]\n\\ProposedTheorem\\ the chapter's load-bearing claim is that these compositions generally fail to commute in legal settings.\nIn most legal settings they do not."
    )],
    'chapters/ch050.tex': [(
        "\\partial\\mathcal D_c,\n\\]\nwhich contains claims whose status is contested, incomplete, or dependent on further evidence.",
        "\\partial\\mathcal D_c,\n\\]\n\\Definition\\ where \\Omega is the claim-space and \\(c\\) the forum context.\nwhich contains claims whose status is contested, incomplete, or dependent on further evidence."
    )],
    'chapters/ch051.tex': [(
        "T_{\\gamma}:\\mathcal J_x\\to\\mathcal J_y,\n\\]\nwhere \\gamma is a procedural path and \\mathcal J_x is the space of judgments available at state \\(x\\).",
        "T_{\\gamma}:\\mathcal J_x\\to\\mathcal J_y,\n\\]\n\\ToyModel\\ where \\gamma is a procedural path and \\mathcal J_x is the space of judgments available at state \\(x\\)."
    )],
    'chapters/ch052.tex': [(
        "T_\\gamma(J)\\neq J,\n\\]\nthe system exhibits \\textbf{distinction holonomy}.",
        "T_\\gamma(J)\\neq J,\n\\]\n\\Definition\\ where \\(J\\) is the claim carried around the loop, the system exhibits \\textbf{distinction holonomy}."
    )],
    'chapters/ch054.tex': [(
        "Keeping the two distinct preserves a productive tension between exposure and sanction rather than forcing either institution to counterfeit the other's task.",
        "Keeping the two distinct preserves a productive tension between exposure and sanction rather than forcing either institution to counterfeit the other's task. The same restraint, however, flips from evidentiary rigor into unmeetable burden when procedural thresholds become a way of withholding sanction from harms that journalism has already made publicly legible."
    )],
    'chapters/ch056.tex': [(
        "\\{\\text{questions answerable at }t+\\Delta\\}.\n\\]\nWhat is kept, discarded, misfiled, or allowed to decay changes the set of questions that later investigators, courts, journalists, or citizens can responsibly answer.",
        "\\{\\text{questions answerable at }t+\\Delta\\}.\n\\]\n\\ToyModel\\ where \\mathcal A_t is the archive at time \\(t\\) and \\(\\Delta\\) the look-ahead interval.\nWhat is kept, discarded, misfiled, or allowed to decay changes the set of questions that later investigators, courts, journalists, or citizens can responsibly answer."
    )],
}

formal_sections = {
    'proof-spines/ch047-spine.md': "## Formal result labels\n- `\\operatorname{Record}\\centernot\\Rightarrow\\operatorname{Verify}\\centernot\\Rightarrow\\operatorname{Recognize}\\centernot\\Rightarrow\\operatorname{Authorize}\\centernot\\Rightarrow\\operatorname{Continue}` — `\\Definition`\n\n",
    'proof-spines/ch048-spine.md': "## Formal result labels\n- `\\mathsf C\\circ\\mathsf B \\stackrel{?}{=} \\mathsf B\\circ\\mathsf C` — `\\ProposedTheorem`\n\n",
    'proof-spines/ch049-spine.md': "## Formal result labels\n- None added in this audit pass.\n\n",
    'proof-spines/ch050-spine.md': "## Formal result labels\n- `\\partial\\mathcal D_c` — `\\Definition`\n\n",
    'proof-spines/ch051-spine.md': "## Formal result labels\n- `T_\\gamma:\\mathcal J_x\\to\\mathcal J_y` — `\\ToyModel`\n\n",
    'proof-spines/ch052-spine.md': "## Formal result labels\n- `T_\\gamma(J)\\neq J` — `\\Definition`\n\n",
    'proof-spines/ch053-spine.md': "## Formal result labels\n- None added in this audit pass.\n\n",
    'proof-spines/ch054-spine.md': "## Formal result labels\n- None added in this audit pass.\n\n",
    'proof-spines/ch055-spine.md': "## Formal result labels\n- None added in this audit pass.\n\n",
    'proof-spines/ch056-spine.md': "## Formal result labels\n- `\\mathcal A_t\\longrightarrow\\{\\text{questions answerable at }t+\\Delta\\}` — `\\ToyModel`\n\n",
    'proof-spines/ch057-spine.md': "## Formal result labels\n- None added in this audit pass.\n\n",
    'proof-spines/ch058-spine.md': "## Formal result labels\n- None added in this audit pass.\n\n",
}

for rel, pairs in replacements.items():
    path = root / rel
    text = path.read_text()
    for old, new in pairs:
        if old not in text:
            raise SystemExit(f'Missing replacement target in {rel}: {old!r}')
        text = text.replace(old, new, 1)
    path.write_text(text)

for rel, section in formal_sections.items():
    path = root / rel
    text = path.read_text()
    marker = '## Cut candidates\n'
    if marker not in text:
        raise SystemExit(f'Marker not found in {rel}')
    if '## Formal result labels\n' in text:
        raise SystemExit(f'Formal result labels already present in {rel}')
    text = text.replace(marker, section + marker, 1)
    path.write_text(text)

notation_path = root / 'notation-vol5.md'
notation_lines = [
    '| Symbol | Meaning | First chapter |',
    '|---|---|---|',
    '| `\\(\\operatorname{Record}\\)` | stores a trace persistently | ch047 |',
    '| `\\(\\operatorname{Verify}\\)` | checks claim-trace relation | ch047 |',
    '| `\\(\\operatorname{Recognize}\\)` | assigns institutional category | ch047 |',
    '| `\\(\\operatorname{Authorize}\\)` | licenses institutional action | ch047 |',
    '| `\\(\\operatorname{Continue}\\)` | carries authorization forward | ch047 |',
    '| `\\(\\mathsf P\\)` | introduces live distinction | ch048 |',
    '| `\\(\\mathsf R\\)` | blocks proposed transition | ch048 |',
    '| `\\(\\mathsf B\\)` | binds evidence or responsibility | ch048 |',
    '| `\\(\\mathsf C\\)` | collapses alternatives to determination | ch048 |',
    '| `merge` | fuses files into one object | ch049 |',
    '| `link` | relates records without fusion | ch049 |',
    '| `unlink` | withdraws relation without deletion | ch049 |',
    '| `\\(\\Omega\\)` | space of conceivable claims | ch050 |',
    '| `\\(\\mathcal D_c\\)` | claims admissible in context `c` | ch050 |',
    '| `\\(\\partial\\mathcal D_c\\)` | admissibility boundary | ch050 |',
    '| `\\(c\\)` | forum context | ch050 |',
    '| `\\(T_\\gamma\\)` | transport along procedural path | ch051 |',
    '| `\\(\\mathcal J_x\\)` | judgments available at state `x` | ch051 |',
    '| `\\(\\mathcal J_y\\)` | judgments available at state `y` | ch051 |',
    '| `\\(\\gamma\\)` | procedural path | ch051 |',
    '| `\\(x\\)` | source institutional state | ch051 |',
    '| `\\(y\\)` | destination institutional state | ch051 |',
    '| `\\(J\\)` | transported claim or judgment | ch052 |',
    '| `\\(\\mathcal A_t\\)` | archive at time `t` | ch056 |',
    '| `\\(t\\)` | present archival time | ch056 |',
    '| `\\(\\Delta\\)` | future interval | ch056 |',
]
notation_path.write_text('\n'.join(notation_lines) + '\n')
