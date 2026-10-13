---
name: d2-diagrams
description: Use when writing, editing, rendering, exporting, or debugging D2 (d2lang, Terrastruct) diagrams or .d2 files, including architecture, sequence, ERD/sql_table, UML class, and grid diagrams, layers/scenarios/steps, or converting a diagram request into D2 and rendering it to SVG, PNG, PDF, PPTX, or GIF.
---

# D2 Diagrams

## Overview

D2 is a text-to-diagram language. Write `.d2` source and render it with the `d2` CLI (verified against v0.9.0). Most syntax you already know works. What goes wrong is verification: `d2 validate` only parses, and several mistakes compile cleanly into the wrong diagram.

## Workflow

1. Write the `.d2` file. Load a reference file below for any feature you are not certain of.
2. `d2 fmt file.d2`
3. Render a check PNG into a scratch directory: `d2 file.d2 "$SCRATCH/check.png"`. This is the real compile. `d2 validate` passes bad shapes, bad colors, out-of-range values, undefined vars, engine-unsupported features, and reserved-word collisions.
4. Read the PNG and compare it to the request: every node, edge and label present, nothing duplicated, no stray shapes, readable layout. For multi-board files, check one PNG per board: `--target=''` (root only), `--target='layers.x'`, `--target='steps.2'`. Linked shapes show a numbered badge and footnote naming the target board.
5. Render the deliverable into scratch, then `cp` it to where the user wants it (see Output safety).

## Output safety

| Hazard | Rule |
|---|---|
| A multi-board file (`layers`/`scenarios`/`steps`) rendered to `NAME.svg`/`NAME.png` **deletes an existing `NAME/` folder**. Bundles replace it with `NAME/index.svg` + one file per board; `--animate-interval` writes one file and still deletes it. PDF, PPTX and single-board renders leave it alone. | Render into scratch, then copy the result into place. Run `find` on a bundle; its layout varies. |
| Multi-board export to `.txt` fails *and* deletes the target directory. ASCII output also draws `shape: text` as an empty box and drops a trailing `%` from labels. | Use `--target='<board>'`; don't rely on `.txt` for review. |
| `d2 play` uploads the diagram to the public playground | Never run it without explicit user approval. |
| `d2 -h` means `--host`, not help | Use `d2 --help`. |
| `d2 --watch` starts a server and blocks | Only on request; run in background with `--browser 0`, kill it afterwards. |

## Reserved keywords as names

These are attributes, not node names: `label shape icon style constraint tooltip link near width height top left direction class classes vars layers scenarios steps grid-rows grid-columns grid-gap vertical-gap horizontal-gap source-arrowhead target-arrowhead`, plus any style key (`fill`, `stroke`, `opacity`, `bold`, …).

Unquoted, `top: Signups` is parsed as a coordinate and `label: X` silently relabels the parent. **Quote** them everywhere they appear as keys (`"label": Docs {link: ...}`, `x -> "label"`) or pick another key with a label (`top_cell: top`).

## Silent failures (compile fine, diagram wrong)

- `#` starts a comment and `;` splits statements, so `a: C# lang` is labelled "C". Quote such labels. Double quotes still expand `${}` and reject a bare `$`; single quotes keep everything literal: `q: 'C# Worker; $5 jobs'`.
- Unquoted `#` in a `link:` URL truncates it. Quote URLs.
- Sequence diagrams: actors used inside a group must be declared at the diagram's top level **first**, or the group gets its own duplicate actors.
- `class: [a; b]` uses `;`. `[a, b]` is a single class named "a, b". Undefined class names are ignored.
- `a:b -> c` is a shape `a` labelled `b -> c`.
- Grids: `grid-columns` alone fills **column by column** (`a c e / b d f`). For reading order, set `grid-rows` before `grid-columns`. Cells cannot span; size them with `width`/`height`.
- `direction` inside a container is ignored by dagre and ELK; only TALA (bundled, `layout-engine: tala`) honors it.
- Globs: `**` reaches into steps and scenarios but **not layers**; use `***` to cover every board. Unknown filters (`&bogus`) match nothing.
- Board links are relative to the board they are written in: from inside a layer, a sibling is `_.layers.w`; `root.layers.w` is absolute. Broken links and board names containing `.` produce no error, just a dead link.

## References

Load only what the task needs. Each file opens with a table of contents and ends with gotchas.

| File | Load when |
|---|---|
| `references/basics.md` | shapes catalog, connections, arrowheads, edge indexing, containers, `_`, quoting, markdown/code/LaTeX blocks, icons, comments |
| `references/special-diagrams.md` | `sql_table`, UML `class`, `sequence_diagram`, grid diagrams |
| `references/styling.md` | every `style.*` key and range, themes and IDs, theme overrides, classes, width/height, `near`/positions, sketch, tooltips/links, fonts, legend |
| `references/layouts.md` | dagre vs ELK vs TALA feature matrix, `direction`, engine options, `vars.d2-config` |
| `references/language.md` | strings and escaping, vars and `${}`, globs and filters, `null` overrides, models, `d2 fmt` |
| `references/composition.md` | layers vs scenarios vs steps, board links, imports (`@file`, `...@file`), multi-file recipes |
| `references/cli.md` | every flag and env var, output formats and limits, stdin/stdout, `--target`, `--animate-interval`, Go API, troubleshooting |
