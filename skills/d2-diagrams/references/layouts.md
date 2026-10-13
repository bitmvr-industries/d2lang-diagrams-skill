# D2 layouts: engines, direction, engine options, `d2-config`

Source: d2 docs `tour/{layouts,dagre,elk,tala,vars,positions,themes}`, `releases/0.9.0`, plus `d2 layout [engine]` output. Verified against d2 v0.9.0 by rendering (not just `d2 validate`). Blocks marked `# TALA only` / `# fails on dagre` were rendered on every engine to confirm.

## Contents

1. [Engines at a glance](#1-engines-at-a-glance)
2. [Feature support matrix](#2-feature-support-matrix)
3. [Choosing an engine](#3-choosing-an-engine)
4. [Selecting the engine](#4-selecting-the-engine) (flag, env, `d2-config`)
5. [Engine options](#5-engine-options) (dagre, elk, tala flags)
6. [`direction`](#6-direction) (global, per-container)
7. [`vars.d2-config` reference](#7-varsd2-config-reference) (all valid keys)
8. [Precedence: CLI vs file](#8-precedence-cli-vs-file)
9. [Gotchas](#9-gotchas)

`d2 validate` only parses. It does NOT catch engine-incompatible features, bad `direction` values, or unknown/mistyped `d2-config` keys. Always do a real compile (`d2 [--layout=X] in.d2 out.svg`) to verify.

## 1. Engines at a glance

| Engine | Name | Default? | Style | Notes |
|---|---|---|---|---|
| dagre | `dagre` | yes | layered/hierarchical, curved multi-segment edges | Fast. Strictly hierarchical. Container-to-container edges via D2 shim. |
| ELK | `elk` | no | layered, orthogonal edges | Better container routing than dagre; SQL table edges hit exact columns. Has alternate algorithms (`--elk-algorithm`). |
| TALA | `tala` | no | general orthogonal, not strictly hierarchical | Built for software architecture. Only engine with `near: <object>`, `top`/`left`, per-container `direction`. Has randomness (seeded). |

TALA licensing: older docs/guides describe TALA as proprietary, separately installed, needing a license (unlicensed renders watermarked). **As of v0.9.0 TALA is open source and bundled**: no plugin, no license key, no watermark. `d2 layout` lists `tala (bundled)`. The installer's old `--tala` flag is rejected. If a user is on d2 < 0.9.0, TALA may be missing; check with `d2 layout`.

```sh
d2 layout          # list engines on this machine
d2 layout dagre    # long help + engine flags
d2 layout elk
d2 layout tala
```

## 2. Feature support matrix

Verified on v0.9.0. "error" = compile fails with a clear message (good: you'll notice). "ignored" = compiles silently but has no effect (bad: easy to miss).

| Feature | dagre | elk | tala |
|---|---|---|---|
| `near: top-center` etc. (constant, root-level shapes only) | yes | yes | yes |
| `near: other_object` | error | error | yes |
| `width`/`height` on non-containers | yes | yes | yes |
| `width`/`height` on containers | error | yes | yes |
| `top`/`left` (lock position) | error | error | yes |
| Root `direction` | yes | yes | yes |
| Per-container `direction` | **ignored** (uses root) | **ignored** (uses root) | yes |
| Connection container -> own descendant (`c -> c.x`) | error | yes | yes |
| Container-to-container / cross-container edges | yes (shim) | yes (native) | yes |
| `grid-rows`/`grid-columns` | yes | yes | yes (grid-cell edges use TALA routing; others draw straight lines) |
| `shape: sequence_diagram` | yes | yes | yes (sequence diagrams use their own layout regardless of engine) |
| `sql_table` edges point to exact column/row | no (per docs) | yes | yes |
| `style.border-radius` on connections (rounded bends) | compiles, no visible effect (curved edges) | yes | yes |

Error text example: `Object "note" has "near" set to another object, but layout engine "dagre" only supports constant values for "near".`

## 3. Choosing an engine

| Need | Use |
|---|---|
| Default, simple flow / hierarchy, fastest | dagre |
| Clean orthogonal (right-angle) edges, many containers, edges into nested shapes, SQL ERDs | elk |
| `c -> c.child` connections | elk or tala |
| Sized containers (`width`/`height` on a container) | elk or tala |
| Annotation placed next to a specific shape (`near: shape`) | tala |
| Pinned coordinates (`top`/`left`) | tala |
| Different flow directions in different containers | tala |
| Non-hierarchical / "whiteboard" architecture layout, symmetry | tala |
| Tree drawn radially / force-directed graph | elk with `--elk-algorithm=radial` / `force` / `stress` / `mrtree` |
| Reproducible output across tiny edits | dagre or elk (TALA's small label changes can cascade into a different layout) |

## 4. Selecting the engine

| Method | Syntax |
|---|---|
| CLI flag | `d2 --layout=elk in.d2 out.svg` (short: `-l elk`) |
| Env var | `D2_LAYOUT=elk d2 in.d2 out.svg` |
| In file | `vars: { d2-config: { layout-engine: elk } }` |

```d2
vars: {
  d2-config: {
    layout-engine: elk
  }
}
a -> b -> c
```

Unknown engine name -> `D2_LAYOUT "foo" is not bundled and could not be found in your $PATH. The available options are: dagre, elk, tala.` (Non-bundled engines are looked up as `d2plugin-<name>` binaries on `$PATH`.)

Confirm which engine actually ran: `d2 -d in.d2 out.svg 2>&1 | grep "using layout"` -> `debug: using layout plugin elk (bundled)`.

## 5. Engine options

Engine options are **CLI flags only**: no `d2-config` key, and (verified) no env vars for the dagre/elk ones (`D2_ELK_ALGORITHM`, `D2_DAGRE_NODESEP` are ignored). Flags for an engine that isn't selected are silently ignored. Flags DO apply when the engine is chosen via `d2-config.layout-engine`.

### dagre

| Flag | Default | Meaning |
|---|---|---|
| `--dagre-nodesep int` | 60 | px between nodes horizontally |
| `--dagre-edgesep int` | 20 | px between edges horizontally |

v0.9.0 dagre is a native Go port ("Dagro") of Dagre 3.1.1 behavior.

### elk

| Flag | Default | Meaning |
|---|---|---|
| `--elk-algorithm string` | `layered` | `layered`, `force`, `stress`, `mrtree`, `radial` |
| `--elk-nodeNodeBetweenLayers int` | 70 | spacing between nodes of adjacent layers |
| `--elk-padding string` | `[top=50,left=50,bottom=50,right=50]` | padding inside parent containers |
| `--elk-edgeNodeBetweenLayers int` | 40 | spacing between nodes and edges routed next to the layer |
| `--elk-nodeSelfLoop int` | 50 | spacing between a node and its self loops |

| `--elk-algorithm` | Layout |
|---|---|
| `layered` (default) | layers, orthogonal edges |
| `force` | simulated attraction/repulsion |
| `stress` | closer shapes = shorter graph paths |
| `mrtree` | tree in levels |
| `radial` | tree in circles around root (expects a tree) |

```sh
d2 --layout=elk --elk-algorithm=radial tree.d2 radial.svg
d2 --layout=elk --elk-padding="[top=10,left=10,bottom=10,right=10]" in.d2 out.svg
```

Only use the 5 algorithms above. `disco` was removed (error: algorithm not found); `box`, `rectpacking`, `fixed` **panic** in v0.9.0; others are untested/unsupported. Feature support in section 2 is for `layered`.

### tala

| Flag | Default | Meaning |
|---|---|---|
| `--tala-seeds int64Slice` | `[1,2,3]` | seeds for deterministic layout attempts; best complete result wins. E.g. `--tala-seeds=9` or `--tala-seeds=1,2,3,4` |

In-file alternative: `vars.d2-config.data.tala-seeds` (must be a **list**; scalar `9` or `"9"` errors). It **overrides** `--tala-seeds` (exception to the usual flags-win rule).

```d2
vars: {
  d2-config: {
    layout-engine: tala
    data: {
      tala-seeds: [9; 42]
    }
  }
}
a -> b -> c
a -> c
```

Same seeds + same source = identical layout across runs. Try other seeds if a TALA layout looks bad.

## 6. `direction`

Values: `up`, `down` (default), `right`, `left`. Anything else -> compile error `direction must be one of up, down, right, left`.

```d2
direction: right
x -> y -> z: hello
```

```d2
direction: up
x -> y -> z: hello
```

### Per-container direction (TALA only)

On dagre/elk a container's `direction` compiles but is **silently ignored**; the whole diagram follows the root `direction`.

```d2
# TALA only (direction inside a/b ignored on dagre/elk)
vars: {
  d2-config: {
    layout-engine: tala
  }
}
direction: down
a -> b -> c

b: {
  direction: right
  1 -> 2 -> 3
}

a: {
  direction: left
  foo -> bar
}
```

Workaround on dagre/elk: put the differently-flowing part in a separate board (layer/scenario/step) or use `grid-rows`/`grid-columns` on the container to force a row/column arrangement.

```d2
# dagre/elk-friendly: force a horizontal row inside a vertical diagram
a -> b -> c
b: {
  grid-rows: 1
  1; 2; 3
}
```

## 7. `vars.d2-config` reference

Must be in the **root** `vars` (inside a container -> error `"d2-config" can only appear at root vars`). Inside a layer/scenario it compiles but is ignored. Any other key -> compile error `"<key>" is not a valid config` (but `d2 validate` passes).

Complete list of valid keys (probed on v0.9.0):

| Key | Type | CLI flag / env equivalent | Notes |
|---|---|---|---|
| `layout-engine` | string | `--layout` / `D2_LAYOUT` | `dagre`, `elk`, `tala` |
| `theme-id` | int | `--theme` / `D2_THEME` | see `d2 themes` |
| `dark-theme-id` | int | `--dark-theme` / `D2_DARK_THEME` | used when viewer is in dark mode |
| `pad` | int | `--pad` / `D2_PAD` | px around diagram (default 100) |
| `center` | bool | `--center` / `D2_CENTER` | center SVG in viewbox |
| `sketch` | bool | `--sketch` / `D2_SKETCH` | hand-drawn look; must be `true`/`false` |
| `theme-overrides` | map | none | color codes (`N1`..`N7`, `B1`..`B6`, `AA2`, `AA4`, `AA5`, `AB4`, `AB5`) -> colors; unknown code errors (`"ZZ9" is not a valid theme code`) |
| `dark-theme-overrides` | map | none | same, for dark theme |
| `data` | map | none | free-form key/values for plugins/library users; `tala-seeds` is read from here |

NOT valid in `d2-config` (CLI only): `scale`, `animate-interval`, `target`, fonts, `omit-version`, `direction` (use the top-level `direction` keyword), any engine option (`elk-algorithm`, `dagre-nodesep`, `tala-seeds` at top level, ...).

Full example (equivalent to `d2 --layout=elk --theme=4 --dark-theme=200 --pad=0 --sketch --center in.d2`):

```d2
vars: {
  d2-config: {
    theme-id: 4
    dark-theme-id: 200
    pad: 0
    center: true
    sketch: true
    layout-engine: elk
  }
}

direction: right
x -> y
```

Theme overrides:

```d2
vars: {
  d2-config: {
    theme-overrides: {
      B1: "#2E7D32"
      B2: "#66BB6A"
      AA4: "#42A5F5"
    }
    dark-theme-overrides: {
      B1: "#A5D6A7"
    }
  }
}
a -> b
```

`data` (arbitrary, read by plugins/library callers):

```d2
vars: {
  d2-config: {
    data: {
      power-level: 9000
    }
  }
}
a
```

`d2-config` can sit alongside ordinary vars in the same `vars` block:

```d2
vars: {
  d2-config: {
    layout-engine: elk
  }
  primary: "#C7F1FF"
}
a.style.fill: ${primary}
```

## 8. Precedence: CLI vs file

Order (highest first): **CLI flag = env var > `vars.d2-config` > built-in default**.

- Any flag or env var that is set wins, even if set to the default value (`--pad=100` overrides `pad: 0` in file).
- `D2_PAD=2 d2 --theme=1 in.d2` ignores the file's `pad` and `theme-id`; the file's other keys still apply.
- Exception: `data.tala-seeds` in the file beats `--tala-seeds`.
- Engine flags (`--elk-*`, `--dagre-*`, `--tala-seeds`) combine with a file-selected engine.

## 9. Gotchas

- `d2 validate` passes on: `near: <object>` under dagre/elk, container `width`/`height` under dagre, `top`/`left` under dagre/elk, `c -> c.x` under dagre, bad `direction` values, unknown `d2-config` keys, wrong types (`sketch: "yes"`). Always render to check.
- Per-container `direction` on dagre/elk is ignored with no warning. Only TALA honors it.
- Constant `near` (`top-center`, `bottom-right`, ...) is only allowed on root-level shapes (`constant near keys can only be set on root level shapes`). Different from label/icon `near` (`label.near`, `icon.near`), which works anywhere.
- Default engine is dagre. If you use an ELK/TALA-only feature, set `layout-engine` in the file so the diagram renders without needing the user to pass `--layout`.
- `d2 --elk-algorithm=force in.d2` without `--layout=elk` (or `layout-engine: elk`) silently uses dagre.
- Engine option env vars don't exist for dagre/elk; `D2_TALA_SEEDS` (mentioned in v0.9.0 release notes) is ignored by the v0.9.0 CLI. Use flags or `data.tala-seeds`.
- `tala-seeds` must be a list: `[9]` or `[1; 2; 3]`.
- `--elk-algorithm` values `box`, `rectpacking`, `fixed` panic; `disco` is gone.
- dagre cannot do container -> descendant edges (`c -> c.x`); use elk/tala or restructure.
- TALA output changes a lot from small edits (randomness); pin seeds and expect re-layouts.
- dagre draws curved multi-segment edges, so `style.border-radius` on connections has no visible effect; use elk/tala for orthogonal, rounded-corner routes.
- `d2-config` only at root `vars`; in a container it errors, in a layer it is silently ignored.
- Docs say TALA is proprietary/separately installed; v0.9.0 bundles it (open source). On older d2, `--layout=tala` fails unless the TALA plugin is installed.
- Never use `d2 play` to preview: it uploads the diagram to a public site.
