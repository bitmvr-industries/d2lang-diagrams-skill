# D2 CLI reference (v0.9.0)

Distilled from d2lang docs (tour/install, man, exports, api, troubleshoot, faq, extensions) and
reconciled against the installed `d2 v0.9.0` (`d2 --help`, `d2 themes`, `d2 layout`). Where they
disagree, the installed CLI wins; observed behavior is marked **(verified)**.

## Contents
1. [Quick commands](#quick-commands)
2. [Subcommands](#subcommands)
3. [Flags and env vars](#flags-and-env-vars)
4. [Stdin / stdout](#stdin--stdout)
5. [Output formats](#output-formats)
6. [Multi-board output](#multi-board-output)
7. [Watch mode](#watch-mode)
8. [Themes and layouts](#themes-and-layouts)
9. [Exit codes and logs](#exit-codes-and-logs)
10. [Go API (d2oracle)](#go-api-d2oracle)
11. [Troubleshooting / FAQ](#troubleshooting--faq)
12. [Install and editor integrations](#install-and-editor-integrations)
13. [Gotchas](#gotchas)

## Quick commands

```sh
d2 in.d2                      # -> in.svg (default format/name)
d2 in.d2 out.png              # format chosen by output extension
d2 validate in.d2             # syntax/compile check, no output file
d2 fmt --check in.d2          # CI check; exit 1 if unformatted
d2 fmt in.d2                  # format in place
d2 -l elk -t 200 in.d2 out.svg
echo 'x -> y' | d2 - -        # stdin -> SVG on stdout
d2 --version                  # or: d2 version
```

## Subcommands

| Command | Does | Notes (verified) |
|---|---|---|
| `d2 [flags] in.d2 [out]` | compile + render | out ext: `.svg .png .pdf .pptx .gif .txt`; default `in.svg` |
| `d2 validate in.d2` | compile only | exit 0 + `Success! [...] is valid D2.`; exit 1 + `err: L:C: msg` per error. `d2 validate -` reads stdin |
| `d2 fmt a.d2 b.d2 ...` | rewrite files in place, canonical style | exit 1 on parse error (file untouched). `d2 fmt -` reads stdin, writes formatted to stdout |
| `d2 fmt --check a.d2 ...` | no write; WARN lists each unformatted file, `err: found N unformatted file(s)`, exit 1 | `D2_CHECK=1 d2 fmt ...` works the same |
| `d2 layout` | list layout engines | v0.9.0: dagre, elk, tala all **bundled** |
| `d2 layout <name>` | engine long help + engine-specific flags | see [Themes and layouts](#themes-and-layouts) |
| `d2 themes` | list theme IDs | |
| `d2 play [--theme N] [--sketch] in.d2` | **UPLOADS the diagram source to the public playground https://play.d2lang.com and opens it in a browser.** | Never run on private/confidential content. Agents should not run it unless the user explicitly asks. |

## Flags and env vars

Source: `d2 --help` (v0.9.0). Env var applies when the flag is not given.

| Flag | Env var | Default | Purpose |
|---|---|---|---|
| `-w, --watch` | `D2_WATCH` | false | watch input, live-reload server |
| `-h, --host` | `HOST` | localhost | watch server host. **`-h` is NOT help; use `--help`** |
| `-p, --port` | `PORT` | 0 (random) | watch server port |
| `--browser` | `BROWSER` | "" | browser watch opens; `0` = open none |
| `--img-cache` | `IMG_CACHE` | true | watch mode: cache icon images; disable if images change |
| `-b, --bundle` | `D2_BUNDLE` | true | SVG: inline all assets/layers |
| `--force-appendix` | `D2_FORCE_APPENDIX` | false | add tooltip/link appendix to SVG too (PNG always gets it) |
| `-d, --debug` | `DEBUG` | false | debug logs |
| `-l, --layout` | `D2_LAYOUT` | dagre | layout engine (`dagre`, `elk`, `tala`, or plugin on `$PATH`) |
| `-t, --theme` | `D2_THEME` | 0 | theme ID |
| `--dark-theme` | `D2_DARK_THEME` | -1 (unset) | theme when viewer is in dark mode (SVG); explicit D2 styles still override |
| `--pad` | `D2_PAD` | 100 | px padding around diagram |
| `--animate-interval` | `D2_ANIMATE_INTERVAL` | 0 | ms per board; packs boards into 1 animated SVG/GIF. SVG/GIF only (else exit 1). GIF defaults 1000 |
| `--timeout` | `D2_TIMEOUT` | 120 | max seconds; raise for big diagrams |
| `-s, --sketch` | `D2_SKETCH` | false | hand-drawn look |
| `-c, --center` | `D2_CENTER` | false | center SVG in viewbox |
| `--scale` | `SCALE` | -1 | -1: SVG fits screen, others natural size; `1` disables SVG fit; `0.5` halves |
| `--target` | (none) | `*` | board to render: `''` root only; `layers.x` just x; `layers.x.*` x + children |
| `--stdout-format` | (none; see Gotchas) | "" | format when output is `-`: `svg png pdf pptx gif ascii txt` |
| `--ascii-mode` | `D2_ASCII_MODE` | extended | `.txt` output: `extended` (Unicode box chars) or `standard` (`+-|>`) |
| `--check` | `D2_CHECK` | false | with `fmt`: check only |
| `--no-xml-tag` | `D2_NO_XML_TAG` | false | omit `<?xml ...?>` (for inline HTML embedding) |
| `--salt` | (none) | "" | change generated SVG IDs so identical diagrams can coexist in one HTML page |
| `--omit-version` | `OMIT_VERSION` | false | drop `data-d2-version` from output |
| `--font-regular` | `D2_FONT_REGULAR` | Source Sans Pro | .ttf path |
| `--font-italic` | `D2_FONT_ITALIC` | Source Sans Pro Italic | .ttf path |
| `--font-bold` | `D2_FONT_BOLD` | Source Sans Pro Bold | .ttf path |
| `--font-semibold` | `D2_FONT_SEMIBOLD` | Source Sans Pro Semibold | .ttf path |
| `--font-mono` | `D2_FONT_MONO` | Source Code Pro | .ttf path |
| `--font-mono-bold` | `D2_FONT_MONO_BOLD` | Source Code Pro Bold | .ttf path |
| `--font-mono-italic` | `D2_FONT_MONO_ITALIC` | Source Code Pro Italic | .ttf path |
| `--font-mono-semibold` | `D2_FONT_MONO_SEMIBOLD` | Source Code Pro Semibold | .ttf path |
| `-v, --version` | | | print version |
| `--help` | | | usage |

Engine-specific flags (from `d2 layout <name>`): `--dagre-nodesep 60`, `--dagre-edgesep 20`;
`--elk-algorithm layered`, `--elk-nodeNodeBetweenLayers 70`, `--elk-padding "[top=50,left=50,bottom=50,right=50]"`,
`--elk-edgeNodeBetweenLayers 40`, `--elk-nodeSelfLoop 50`; `--tala-seeds 1,2,3` (in-file `tala-seeds` wins).

## Stdin / stdout

`-` as input = read stdin; `-` as output = write stdout. Logs go to stderr, so stdout is clean.

```sh
echo 'x -> y' | d2 - - > out.svg                     # SVG default on stdout
echo 'x -> y' | d2 --stdout-format png - - > out.png
echo 'x -> y' | d2 --stdout-format ascii - -         # text art to terminal (txt also accepted)
echo 'x -> y' | d2 - out.png                         # stdin -> file
d2 in.d2 - | ...                                     # file -> SVG on stdout
echo 'x -> y' | d2 -                                 # no output arg + stdin -> SVG on stdout (verified)
```

## Output formats

All rendered locally by the Go binary. **(verified)** v0.9.0 needs no headless browser and
downloads nothing for PNG/PDF/PPTX/GIF: the binary contains no Playwright/Chromium code, renders
took 20-45 ms (GIF ~0.5 s) on first run, and `~/Library/Caches/ms-playwright` was untouched.
(Older D2 releases used Playwright + Chromium for PNG and downloaded it on first PNG export;
current docs say "PNG exports have no external dependencies".)

| Ext | Content | Notes |
|---|---|---|
| `.svg` | default; CSS + fonts embedded (`--bundle`) | interactive: links, tooltips, `animate`. Shape class = base64 of ID (`my-shape` -> `bXktc2hhcGU`); hashed `d2-<n>` prefix on IDs |
| `.png` | raster, 2x SVG pixel size by default | max 32768 px per side. Tooltips/links get an appendix (non-interactive). `--scale 0.5` -> 1x. Observed: `--scale` ignored when an appendix is added |
| `.pdf` | PNG renders on PDF pages + headers/fonts | 1 page per board; links stay clickable; no animation |
| `.pptx` | 1 slide per board | for presentations with layers/scenarios/steps |
| `.gif` | animated loop through boards | default 1000 ms/board; good for short compositions |
| `.txt` | ASCII/Unicode art (**beta**, since 0.7.1) | only ELK/TALA; dagre silently uses ELK. Complex shapes show a corner icon; styles mostly ignored. `--ascii-mode standard` for plain ASCII. Multi-board fails (see Gotchas) |

Interactivity: `<img>` and CSS background lose links/tooltips; inline `<svg>`, `<object>`,
`<iframe>`, `<embed>` keep them.

## Multi-board output

Diagrams with `layers`/`scenarios`/`steps` **(verified)**:

| Output | Result |
|---|---|
| `d2 in.d2 out.svg` / `out.png` | creates **directory** `out/` with `index.svg` (root) + `<board>.svg` |
| `d2 --animate-interval 1000 in.d2 out.svg` | single animated SVG (still deletes an existing `out/` dir, see Gotchas) |
| `.pdf` / `.pptx` / `.gif` | single file, one page/slide/frame per board |
| `.txt` | **fails** (exit 1) |
| `--target=''` or `--target='layers.x'` | single board -> single file of the given name |

## Watch mode

```sh
d2 -w --browser 0 in.d2 out.svg            # serve + rebuild, don't open a browser
HOST=0.0.0.0 PORT=8080 d2 -w in.d2         # fixed address
```

Prints `success: listening on http://127.0.0.1:<port>`, rewrites the output file on every save,
pushes reloads to connected browsers. Runs until killed (SIGTERM/Ctrl-C -> clean shutdown).
**Agents: always run in background and kill it when done; never leave the server running.** For
one-shot renders just run `d2` without `-w`.

## Themes and layouts

`d2 themes` (v0.9.0):

| Light | ID | Light | ID |
|---|---|---|---|
| Neutral Default | 0 | Orange Creamsicle | 101 |
| Neutral Grey | 1 | Shirley Temple | 102 |
| Flagship Terrastruct | 3 | Earth Tones | 103 |
| Cool Classics | 4 | Everglade Green | 104 |
| Mixed Berry Blue | 5 | Buttered Toast | 105 |
| Grape Soda | 6 | Terminal | 300 |
| Aubergine | 7 | Terminal Grayscale | 301 |
| Colorblind Clear | 8 | Origami | 302 |
| Vanilla Nitro Cola | 100 | C4 | 303 |

Dark: Dark Mauve 200, Dark Flagship Terrastruct 201. Unknown ID -> exit 1 with the list.

`d2 layout` (v0.9.0): `dagre` (default; native Go port "Dagro"), `elk` (Go port of ELK.js 0.12,
layered), `tala` (D2's own engine, now bundled). Unknown engine -> exit 1; D2 also looks for an
external plugin binary on `$PATH`.

## Exit codes and logs

- 0 success, 1 any error (bad usage, compile error, render error, fmt --check failure).
- Messages on stderr prefixed `success:`, `info:`, `warn:`, `err:`. Errors carry `path:line:col: msg`.
- Man page: **use the exit status, not the output file's existence**: d2 may write a partial
  render on some render errors. (Compile/syntax errors wrote no file in tests.)

## Go API (d2oracle)

Package `github.com/d2lang/d2/d2oracle`: programmatic editing of a compiled `*d2graph.Graph`.
Pure functions: each returns a **new** graph; chain the result. `boardPath` is `nil` for the root
board, e.g. `[]string{"y"}` for layer `y`.

```go
Create(g, boardPath, key)                 (newG, newKey, err) // "a.b -> x.y" creates missing parents; dup shape -> "a 2"; edges get "(a -> b)[i]"
Set(g, boardPath, key, tag, value *string) (newG, err)        // "a.style.fill"; value nil = unset; tag = language (e.g. "md")
Delete(g, boardPath, key)                 (newG, err)         // deletes children too
Rename(g, boardPath, key, newName)        (newG, err)         // ID, not label; updates references
Move(g, boardPath, key, newKey)           (newG, err)         // into/out of/across containers
MoveIDDeltas / DeleteIDDeltas / RenameIDDeltas -> map[string]string of old->new IDs
```

Docs examples omit `boardPath` in places; the signatures above are authoritative. Browser/JS:
`npm install @d2lang/d2` (D2.js, WebAssembly).

## Troubleshooting / FAQ

| Symptom | Fix |
|---|---|
| Label/value won't compile | quote it: `"x(int y)": "[]int"`, `'$dollarbills$'` |
| Reserved keyword wanted as a key | quote it: `"width": width` |
| Text too wide | insert `\n` in the label |
| Cluttered connections on hub shapes | set explicit `width`/`height` to give edges room |
| HTML inside Markdown breaks render | use XML-valid HTML: `<br/>` not `<br>` |
| SVG links/tooltips dead when embedded | don't use `<img>`/CSS background; inline or `<object>`/`<iframe>`/`<embed>` |
| Non-ASCII text acts weird | full-width `：` etc. are not syntax; use ASCII `: ; .` |
| Identical diagrams clash in one HTML page | `--salt <unique>` per diagram |
| Large diagram times out | `--timeout 600` |
| `d2 -h` errors "flag needs an argument" | `-h` is `--host`; use `--help` |

FAQ facts: no telemetry (only periodic GitHub version check); runs fully server-side, no browser
needed; not designed/tested for thousands of nodes; an object cannot belong to 2 containers; no
explicit ports. Online: https://play.d2lang.com (public).

## Install and editor integrations

Install: `brew install d2` | `curl -fsSL https://d2lang.com/install.sh | sh -s -- --dry-run`
(then without `--dry-run`; `--uninstall` to remove) | `go install github.com/d2lang/d2@latest` |
binaries at github.com/d2lang/d2/releases. Check: `d2 --version`.

Editors / integrations (official first):
- VS Code: `d2lang/d2-vscode` (marketplace; syntax + indent)
- Vim: `Plug 'd2lang/d2-vim'`
- Obsidian: `d2lang/d2-obsidian` (render only)
- Community: tree-sitter grammars (pleshevskiy, ravsii), Emacs `d2-mode`, Zed `zed-d2`, MkDocs
  `mkdocs-d2-plugin`, mdBook `mdbook-d2`, Pandoc `d2-filter`, remark-d2, goldmark-d2, Org `ob-d2`,
  Hexo, Python `py-d2`, JS `d2lang-js`, C# `d2lang-cs`, DB->D2 importers (Postgres, MySQL, MongoDB),
  Structurizr exporter.

## Gotchas

- **`d2 play` publishes your source to a public website.** Don't use it for anything private.
- **Multi-board `.txt` export fails AND deletes the output directory** (`out/` for `out.txt`),
  including a pre-existing directory and unrelated files in it **(verified)**. Use
  `--target=''` (or `--target='layers.x'`) for ASCII, and never point a multi-board `.txt` export
  at a name whose sibling directory matters.
- Multi-board SVG/PNG produce a **directory**, not a file: check `out/index.svg`.
- `-h` = `--host`. Help is `--help` only.
- Format is picked from the output extension; for stdout use `--stdout-format`. The man page's
  `D2_STDOUT_FORMAT` env var is **ignored** in v0.9.0 (verified: still emitted SVG).
- `--animate-interval` with PNG/PDF/PPTX/TXT -> exit 1.
- ASCII silently swaps dagre for ELK; layout may differ from the SVG.
- PNG is 2x the SVG pixel size by default; `--scale` had no effect once a tooltip/link appendix was added.
- Rely on exit status, not file presence (partial renders possible).
- `d2 fmt` rewrites in place; use `--check` in CI or `d2 fmt -` for a dry run via stdin.
- Watch mode never exits on its own; pass `--browser 0` in headless/agent contexts and kill it.
- `--dark-theme` only affects SVG viewed in dark mode; explicit `style` values ignore it.
- Docs pages for older versions mention a Playwright/Chromium download for PNG; not true for v0.9.0.
- **Any multi-board render to `NAME.svg` / `NAME.png` deletes an existing `NAME/` directory**, including `--animate-interval` renders that output a single file. PDF, PPTX and single-board renders leave it alone (verified v0.9.0). Render into scratch and `cp` the result into place.
- ASCII output draws `shape: text` as an empty box and drops a trailing `%` from labels (`100%` -> `100`). Use PNG for visual review.
