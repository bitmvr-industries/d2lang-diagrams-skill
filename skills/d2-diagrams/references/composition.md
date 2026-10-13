# D2 composition: boards, layers/scenarios/steps, board links, multi-board exports, imports

Source: d2 docs `tour/{composition,layers,scenarios,steps,linking,composition-formats,imports,imports-use-cases,model-view,modular-classes,nested-composition,version-visualization,imported-template}` plus their `static/d2` example files. Every `d2` block below compiles AND renders on d2 v0.9.0 (helper files for imports were created alongside). Link behavior was checked by inspecting rendered SVG hrefs.

`d2 validate` does NOT resolve imports (`a: @missing` passes) and does NOT check board-link targets or cross-board edges. Always do a real render (`d2 in.d2 out.svg`) to verify composition code.

## Contents

1. [Boards](#1-boards) (`layers` / `scenarios` / `steps`, inheritance table, declaration forms)
2. [Layers](#2-layers)
3. [Scenarios](#3-scenarios) (update / add / `null`-delete inherited items)
4. [Steps](#4-steps) (+ nesting boards)
5. [Linking between boards](#5-linking-between-boards) (`link: layers.x`, `_`, `root`, siblings)
6. [Multi-board export formats](#6-multi-board-export-formats) (SVG bundle, animated SVG/GIF, PDF, PPTX, `--animate-interval`, `--target`)
7. [Imports](#7-imports) (`@file`, `...@file`, partial, paths, into keys/boards)
8. [Recipes](#8-recipes) (model-view, modular classes, nested composition, version visualization, template)
9. [Gotchas](#9-gotchas)

## 1. Boards

A file's top level is the **root board**. Declaring a board under one of three reserved keywords adds another board. Boards are never shown together; exports handle them as pages/files/frames (see section 6).

| Keyword | Board starts from | Use for |
|---|---|---|
| `layers` | Blank. Inherits nothing. A new base. | Drill-down levels of abstraction |
| `scenarios` | Its parent (base) board. Not from sibling scenarios. | Alternate views of the same diagram (hotfix path, failure mode) |
| `steps` | The previous step, in declaration order. First step starts from the parent board. Cumulative. | Sequences / animations |

Inherited objects can be restyled, extended, or removed (`key: null`) in scenarios and steps. Boards nest arbitrarily (layers in layers, steps in scenarios, ...).

```d2
# Root board
x -> y
layers: {
  # Board "numbers": inherits nothing from root
  numbers: {
    1 -> 2
  }
}
```

Dotted declaration and board labels (label = board display name):

```d2
x
layers.detail: Detail view {   # dotted declaration + board label
  m
}
scenarios.hotfix: Hotfix {
  x.style.fill: red
}
```

## 2. Layers

Each layer is a blank board. Typical pattern: an object on the parent links into the layer (section 5).

```d2
explain: |md
  Top layer, highest abstraction.
| {near: top-center}

User data: {link: layers.dcs}

layers: {
  dcs: {
    Virginia DC <-> Hong Kong DC
    Virginia DC.link: layers.virginia
    Hong Kong DC.link: layers.hongkong

    layers: {
      virginia: {
        direction: right
        DB: {shape: cylinder; style.multiple: true}
        US residents: {shape: person}
        US residents -> DB: access
        Auditors -> DB: verify
      }
      hongkong: {
        Legacy DB: {shape: cylinder}
      }
    }
  }
}
```

## 3. Scenarios

Each scenario = base board + its own changes. Reference base objects/edges by the same key to update them, add new keys, or set `null` to delete (deleting a shape also removes its edges).

```d2
direction: right
title: Normal deployment {near: bottom-center; shape: text}

local.code -> github.dev: commit
github.dev -> github.master: merge
github.master -> aws.ec2: deploy
local.code -> aws.ec2: {style.opacity: 0}   # hidden in base, revealed later

scenarios: {
  hotfix: {
    title.label: Hotfix deployment          # update inherited object
    github.style.opacity: 0.1
    (local.code -> github.dev)[0].style.opacity: 0.1   # update inherited edge
    (local.code -> aws.ec2)[0].style: {
      opacity: 1
      stroke: "#167c3c"
      stroke-dash: 5
    }
    rollback plan                           # add new object
  }
  minimal: {
    github: null                            # delete inherited object (+ its edges)
  }
}
```

Trick from the docs: declare an edge in the base with `style.opacity: 0`, then reveal it in a scenario, so layout stays stable across boards.

## 4. Steps

Steps are ordered by declaration (not by name). Step N = step N-1 + its own changes.

```d2
Chicken's plan: {shape: text; near: top-center}

steps: {
  1: {
    Approach road
  }
  2: {
    Approach road -> Cross road        # "Approach road" inherited from step 1
  }
  3: {
    Cross road -> Make you wonder why  # has everything from 1 and 2
  }
}
```

Nesting: steps inside a scenario start from that scenario (root steps do not leak into scenarios).

```d2
x -> y
scenarios: {
  outage: {
    y.style.fill: red
    steps: {
      1: {detect}            # = root + outage + detect
      2: {detect -> fix}     # = step 1 + fix
    }
  }
}
```

## 5. Linking between boards

`link:` with a board path (instead of a URL) makes an internal link. Paths resolve **relative to the board where the link is written**.

| Link value | Target |
|---|---|
| `layers.x` / `scenarios.x` / `steps.x` | Child board of the CURRENT board |
| `_` | Parent board (in `link`, `_` means parent BOARD, not parent container) |
| `_._` | Grandparent board |
| `_.layers.x` | Sibling board `x` |
| `_.steps.1` | Sibling step (from inside a step) |
| `root` | Root board (absolute; undocumented, verified on v0.9.0) |
| `root.layers.x.layers.y` | Absolute path from root (undocumented, verified) |
| `layers."2012.06"` | Board name containing `.` must be quoted (see Gotchas: broken in SVG bundles) |

In PNG/PDF output a linked shape gets a numbered badge and a footnote naming the target board's label, which is a quick visual check that a link resolved. To check SVG bundles, grep the `href="..."` values.

```d2
how does the cat go?: {link: layers.cat}

layers: {
  cat: {
    meoowww
  }
}
```

Quoted board name:

```d2
a.link: layers."2012.06"

layers: {
  "2012.06": {
    hello
  }
}
```

Parent refs:

```d2
The shire

journey: {link: layers.rivendell}

layers: {
  rivendell: {
    elves: {
      elrond -> frodo: gives advice
    }
    take me home sam.link: _           # parent board = root
    go deeper: {link: layers.moria}    # relative: rivendell's own child

    layers: {
      moria: {
        dwarves
        take me home sam.link: _._     # grandparent = root
        back to elves.link: _          # parent = rivendell
      }
    }
  }
}
```

Siblings, root refs, steps:

```d2
home
layers: {
  a: {
    to sibling.link: _.layers.b        # NOT layers.b (that means a.layers.b)
    to scenario.link: _.scenarios.s
    to step.link: _.scenarios.s.steps.2
    deep.link: layers.inner
    layers: {
      inner: {
        abs root.link: root            # absolute ref to root board
        abs sibling.link: root.layers.b
      }
    }
  }
  b: {q}
}
scenarios: {
  s: {
    steps: {
      1: {i}
      2: {prev.link: _.steps.1}        # step -> sibling step via parent
    }
  }
}
```

Links are inherited like any other field: a link defined on a scenario's base object still resolves relative to where it was written.

## 6. Multi-board export formats

| Output | Command | Multi-board behavior |
|---|---|---|
| SVG bundle (default) | `d2 in.d2 out.svg` | **Replaces** dir `out/` with `index.svg` + one file per board. The layout varies: layers only, with no children of their own → flat (`out/x.svg`); otherwise nested (`out/layers/x/index.svg`, `out/scenarios/s.svg`, `out/steps/1.svg`). Run `find out -type f` rather than guessing. Board links rewritten to relative file paths. |
| PNG bundle | `d2 in.d2 out.png` | Same dir layout as SVG bundle |
| Animated SVG | `d2 --animate-interval=1200 in.d2 out.svg` | ONE svg cycling all boards (root, layers, scenarios, steps), 1200 ms each. Best for few steps/scenarios. |
| Animated GIF | `d2 in.d2 out.gif` | One GIF; interval defaults to 1000 ms (override with `--animate-interval`). For places SVG doesn't render. |
| PDF | `d2 in.d2 out.pdf` | One page per board; internal links jump to pages. Best for layers. |
| PowerPoint | `d2 in.d2 out.pptx` | One slide per board; works in Google Slides. |
| ASCII | `d2 in.d2 out.txt` | Fails on multi-board in v0.9.0 (see Gotchas); use `--target`. |

`--animate-interval` works only with `.svg` / `.gif` (error for png/pdf/pptx).

`--target` (default `*` = everything):

```sh
d2 --target='' in.d2 out.svg               # root board only, single file
d2 --target=layers.x in.d2 out.pdf         # just board x
d2 --target='layers.x.*' in.d2 out.svg     # x plus all its child boards
d2 --target=scenarios.s.steps.2 in.d2 out.svg
```

`--target='steps.*'` errors ("render target steps not found"); target a concrete board (`steps.1`, `steps.1.*`).

## 7. Imports

Import another `.d2` file with `@name` (path without `.d2`; `@name.d2` also works, `d2 fmt` rewrites it to `@name`).

| Form | Meaning |
|---|---|
| `a: @x` | Regular import: whole file `x.d2` becomes the map value of `a` |
| `a: {...@x}` | Spread import: insert `x.d2`'s contents into this map (can mix with other keys) |
| `...@x` (top level) | Spread into root board |
| `...@x.k` | Partial spread: only key `k` of `x.d2`, its children spread here |
| `a: @x.k.j` | Partial import into a key |
| `@"v0.1.2"` | Quote file names containing `.` (`.` means key targeting) |
| `@../dir/x`, `@sub/x` | Relative to the importing FILE, not the cwd. `@./x` is fmt'd to `@x`. |
| `@/abs/path/x` | Absolute path; Windows: `@"C:\path\to\file"` (quoted) |

Only `.d2` files can be imported.

`x.d2` (helper used below):

```d2
x: {
  shape: circle
}
```

Regular import:

```d2
a: @x
a -> b
```

Spread import (same result):

```d2
a: {
  ...@x
}
a -> b
```

Partial imports. `people.d2`:

```d2
management: {
  joe: {shape: person; label: Joe Donutlover}
  jan: {shape: person; label: Jan Donutbaker}
}
employees: {
  toby: {shape: person}
}
```

```d2
...@people.management    # only joe + jan, flattened into root; toby is not imported
joe -> donuts: loves
jan -> donuts: brings
```

```d2
mgmt: @people.management       # mgmt.joe, mgmt.jan
boss: @people.management.joe   # a single object's map
mgmt.jan -> boss
```

Dotted file name (`schema-v0.1.2.d2`):

```d2
db: @"schema-v0.1.2"   # quote names containing dots
```

Relative paths (file lives in `sub/`; `x.d2` and `lib/thing.d2` are one dir up):

```d2
y: @../x          # path is relative to THIS file, not the cwd
z: @../lib/thing  # subdirectories work too
```

Imports as boards:

```d2
overview.link: layers.detail
layers: {
  detail: @x              # whole file becomes the board
  extended: {
    ...@x                 # file contents + extra objects
    extra
  }
}
```

Board links inside an imported file resolve at the import site, so `_` reaches the importer's boards. `sib.d2`:

```d2
inside
back.link: _              # parent board at the import site
peer.link: _.layers.other # sibling board at the import site
```

```d2
home
layers: {
  imported: @sib
  other: {o}
}
```

## 8. Recipes

Why split files: compliance (frozen core file), domain ownership, smaller review diffs, reusable styles, DRY (edit one object, all importers update).

### Model-view: define models once, draw many views

`models.d2`:

```d2
postgres: {shape: cylinder}
it: IT Guy {shape: person; style.fill: maroon}
vpn: {style.shadow: true; tooltip: IP is 192.2.2.1}
```

`access-view.d2`:

```d2
...@models
it -> vpn -> postgres
```

`ssh-view.d2`:

```d2
...@models
it -> postgres: ssh, bypassing VPN
```

### Modular classes: styles file + content file (like CSS/HTML)

`classes.d2`:

```d2
classes: {
  base: {style: {border-radius: 4; shadow: true}}
  error: {style.fill: pink; style.stroke: red}
  med: {width: 200; height: 200; style.font-size: 24}
  person: {shape: person; style.stroke-dash: 3}
}
```

`main.d2`:

```d2
...@classes
user.class: person
error.class: [base; error]
modal.class: [base; med]

user -> app.signup: click
app.signup -> error: invalid fields
app.signup -> modal: continue registration
```

### Nested composition: each file flat, drill-down via imported layers

`overview.d2`:

```d2
serviceA -> serviceB
serviceB.link: layers.serviceB
layers: {
  serviceB: @serviceB
}
```

`serviceB.d2`:

```d2
aws vault: {key; token}
stripe: {customer id}
aws vault.key -> data
stripe.customer id -> data
data.link: layers.data      # resolves relative to the board this file lands in
layers: {
  data: @data
}
```

`data.d2` (can keep nesting with its own `layers`):

```d2
users: {
  shape: sql_table
  id: int
  token: string
}
```

Render `overview.d2` to PDF/SVG bundle: `index` -> `serviceB/index` -> `serviceB/data`.

### Version visualization: import old and new copies of the same file

Get old version: `cp users.d2 users-current.d2; git checkout tags/v0.1 users.d2; mv users.d2 users-v0.1.d2`.

`history.d2`:

```d2
direction: right
Users 1: Users Table (v0.1) {
  ...@"users-v0.1"
}
Users 2: Users Table (current) {
  ...@users-current
}
Users 1 -> Users 2
```

`users-v0.1.d2`:

```d2
users: {
  shape: sql_table
  id: int {constraint: primary_key}
  email: string
}
```

`users-current.d2`:

```d2
users: {
  shape: sql_table
  id: int {constraint: primary_key}
  email: int {constraint: foreign_key}
}
emails: {
  shape: sql_table
  id: int {constraint: primary_key}
  domain: string
}
users.email -> emails.id
```

Compare variant: spread files copied from different repos side by side (`alpha-schema.d2`, `charlie-api.d2`, ... must exist):

```d2
Team Alpha: {
  Quick facts: |md
    - 3 L6 engineers
  |
  Schema: {...@alpha-schema}
  API: {...@alpha-api}
}
Team Charlie: {
  Schema: {...@charlie-schema}
  API: {...@charlie-api}
}
```

### Template: spread a styling-only file into a wrapper container

`wrapper-template.d2` (fields only, no shapes):

```d2
style: {
  fill: "#E3EDE6"
  fill-pattern: dots
  stroke: "#820758"
  stroke-width: 3
  shadow: true
}
label: ""
```

`diagram.d2`:

```d2
template: {
  ...@wrapper-template     # container styling/label come from the template file
  synergy: {
    our firm -> yours: value add
  }
  stakeholders: {
    george.shape: person
  }
}
```

## 9. Gotchas

- `d2 validate` is not enough: it passes missing import files (`a: @nope`), non-`.d2` imports, links to nonexistent boards, and cross-board edges. Render to catch these.
- Broken board links are silently dropped (no error, no href). Includes: `link: layers.w` written inside another layer when `w` is a sibling (needs `_.layers.w`), `_` on the root board, `_._` past root, `_.1` for a sibling step (needs `_.steps.1`).
- Board link paths are relative to the board containing the `link`, not absolute. Use `_`, `_._`, or `root...` to go up.
- `_` in a `link` value means parent BOARD; elsewhere `_` means parent container.
- Board names containing `.` (`layers."2012.06"`): the docs' syntax compiles, but in v0.9.0 SVG bundles the href is left unrewritten (`root.layers."2012.06"`), i.e. a dead link. Prefer names without dots (`v2012_06`).
- No edges between boards: `layers.L.a -> b` at root fails ("cannot create edges between boards"); write `layers.L: {a -> b}`. Board keywords can't be edge endpoints (`layers -> x` fails).
- Scenarios inherit only from their parent board, never from sibling scenarios. Root-level `steps` do not flow into `scenarios`.
- Steps order = declaration order, not name order.
- `key: null` in a scenario/step deletes the inherited object and its connections.
- `a: ...@x` is invalid (spread only inside a map: `a: {...@x}`). Bare `@x` on its own line is invalid (use `...@x`).
- `@x.txt` is parsed as "key `txt` inside `x.d2`" (error "doesn't exist inside import"); only `.d2` files import. `@schema-v0.1.2` unquoted looks for `schema-v0.d2`.
- Relative imports resolve from the importing file's directory, not the cwd.
- Globs: `**` applies to the current board and boards that inherit from it (scenarios/steps), not to `layers`; `***` also reaches layers and persists across imports.
- `d2 fmt` removes empty board keywords (`layers: {}`) and rewrites `@x.d2`/`@./x` to `@x`.
- Multi-board output to `.txt` (ASCII) fails in v0.9.0 ("no such file or directory" for `layers/...txt`); use `--target` to pick one board.
- `--animate-interval` with `.png`/`.pdf`/`.pptx` is a usage error. Animated output includes every board (layers too), so keep animated compositions small.
- Output path for a multi-board SVG/PNG is treated as a directory name: `out.svg` -> `out/index.svg`, etc.
- Never use `d2 play` (uploads to a public site).
