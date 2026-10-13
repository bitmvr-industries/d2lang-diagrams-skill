# D2 language reference: strings, vars, globs, overrides, models, fmt

Verified against d2 v0.9.0. Every `d2` block below passes `d2 validate` and compiles.

## Contents
1. [Strings](#strings): unquoted, quoted, escaping, block strings
2. [Variables](#variables): `vars`, `${}`, nesting, scope, spread, `d2-config`, `d2-legend`
3. [Globs](#globs): `*`, `**`, `***`, connection globs, filters `&` / `!&`
4. [Overrides and null](#overrides-and-null)
5. [Models](#models): `suspend` / `unsuspend`
6. [Autoformat](#autoformat): `d2 fmt`
7. [Gotchas](#gotchas)

---

## Strings

### Unquoted (default)
Leading and trailing whitespace is trimmed. Most labels and keys need no quotes.
```d2
   Office Bulb   :     Philips
            Switch   ->   Office Bulb
```

Unquoted text cannot contain reserved characters. Quote it when it contains any of these:

| Char | Meaning when unquoted |
|---|---|
| `#` | starts a comment (`a: C# lang` gives label `C`) |
| `;` | statement separator (`a; b`) |
| `:` `.` `{` `}` `[` `]` | key/label, path, map, array syntax |
| `-` `<` `>` sequences | connection operators |
| `$` | substitution start. A bare `$` not followed by `{` is a **compile error** (`substitutions must begin on {`). Escape it as `\$`. |
| `\|` | block string start (at value start) |

### Quoted
```d2
'$$$' -> "###"
a: "C# & semicolons; ok"
b: "say \"hi\", it's fine"
c: 'it''s single quoted'
d: "line one\nline two"
e: cost \$5
```

| Form | Escaping | `${var}` substituted? |
|---|---|---|
| unquoted | `\$`, `\#`, and so on | yes |
| `"double"` | `\"`, `\\`, `\n`, `\$` | yes |
| `'single'` | `''` for a literal `'`. **`\'` fails.** `$` and `${...}` are literal. | **no** |

Rule of thumb: use double quotes if the text contains `'`, and single quotes if it contains `"`. If it contains both, use double quotes and escape with `\"`.

### Block strings
`|lang ... |` holds multi-line text, markdown, code or LaTeX. Nothing inside is parsed as D2.
```d2
md: |md
  # Title
  - item
|
code: |go
  func x() {}
|
```

If the content contains `|`, use more pipes or any other symbol after the first pipe. Letters, digits, space and `_` are not allowed. The closing delimiter mirrors the opening one.
```d2
ts2: ||ts
  type T = Fish | Bird;
||
ts3: |||ts
  const works = (a > 1) || (b < 2)
|||
tsb: |`ts
  const works = (a > 1) || (b < 2)
`|
```

Indentation: content may sit at column 0, and `d2 fmt` re-indents it under the key while keeping the relative indent. Tabs after the base indent are fine, and tabs in the base indent become 2 spaces.
```d2
parent: {
example_code: |go
package fs
type FS interface {
  Open(name string) (File, error)
}
|
}
```

---

## Variables

`vars` is a reserved map. Reference its entries with `${name}`.
```d2
direction: right
vars: {
  server-name: Cat
}
server1: ${server-name}-1
server2: ${server-name}-2
server1 <-> server2
```

### Where substitution works
| Location | Works? |
|---|---|
| labels (`a: ${x}`, `a: pre-${x}-post`, `label: ${x}`) | yes |
| connection labels (`a -> b: ${x}`) | yes |
| attribute values (`style.fill: ${c}`, `width: ${w}`, `tooltip`) | yes |
| double-quoted strings (`"hi ${x}"`) | yes |
| block strings (`\|md ... ${x} ... \|`) | yes |
| whole map as value (`a: ${m}` where `m` is a map) | yes, the map is applied |
| single-quoted strings | **no**. Use them to print a literal `${x}`, or write `"\${x}"`. |
| keys / IDs (`${x} -> b`, `"${x}": ...`) | **no**. Unquoted is a parse error, and quoted becomes the literal key `${x}`. |

### Nested vars: use `.`
```d2
vars: {
  primaryColors: {
    button: {
      active: "#4baae5"
      border: black
    }
  }
}
button: {
  width: 100
  height: 40
  style: {
    border-radius: 5
    fill: ${primaryColors.button.active}
    stroke: ${primaryColors.button.border}
  }
}
```

### Vars in styles
```d2
vars: {
  brand: "#0d32b2"
  w: 3
}
a.style: {
  stroke: ${brand}
  stroke-width: ${w}
}
b -> a: {style.stroke: ${brand}}
```

### Scope
Vars are lexically scoped. A substitution can see vars from its own map and enclosing maps, never from inner maps. The nearest definition wins.
```d2
vars: {
  region: Global
}
lb: ${region} load balancer
zone1: {
  vars: {
    region: us-east-1
  }
  server: ${region} API
}
```
Here `lb` is labelled "Global load balancer" and `zone1.server` is labelled "us-east-1 API".

### Literal `${...}` (bypass substitution)
```d2
direction: right
vars: {
  names: John and Joyce
}
a -> b: 'Send field ${names}'
c: "also literal \${names}"
```

### Spread `...${x}`
If `x` is a map or an array, `...${x}` spreads its contents into the surrounding map or array. Spreading a scalar is a compile error (`cannot spread non-composite`).
```d2
vars: {
  base-constraints: [NOT NULL; UNQ]
  disclaimer: DISCLAIMER {
    I am not a lawyer
    near: top-center
  }
}
data: {
  shape: sql_table
  a: int {constraint: [PK; ...${base-constraints}]}
}
custom-disclaimer: DRAFT DISCLAIMER {
  ...${disclaimer}
}
```

### `d2-config` (render options in the file)
```d2
vars: {
  d2-config: {
    theme-id: 4
    dark-theme-id: 200
    pad: 0
    center: true
    sketch: true
    layout-engine: elk
    theme-overrides: {
      B1: "#000000"
    }
    dark-theme-overrides: {
      B1: "#ffffff"
    }
    data: {
      power-level: 9000
    }
  }
}
direction: right
x -> y
```
This is equivalent to `d2 --layout=elk --theme=4 --dark-theme=200 --pad=0 --sketch --center in.d2`.

| Key | Flag equivalent |
|---|---|
| `theme-id` | `--theme` |
| `dark-theme-id` | `--dark-theme` |
| `pad` | `--pad` |
| `center` | `--center` |
| `sketch` | `--sketch` |
| `layout-engine` | `--layout` (`dagre`, `elk`, `tala`. TALA is bundled in v0.9.0.) |
| `theme-overrides` / `dark-theme-overrides` | theme color codes such as `B1` |
| `data` | free-form map for plugins and library users. For example, `data.tala-seeds` maps to `--tala-seeds`. |

- **Precedence:** CLI flags and env vars (`D2_PAD`, `D2_LAYOUT`, ...) override `d2-config`.
- Unknown keys are a compile error (`"font" is not a valid config`). `direction` is **not** a config key, so set it at the top level.

### `d2-legend`
Declares a legend. Its contents are ordinary shapes and connections drawn as legend entries. The label renames the legend.
```d2
vars: {
  d2-legend: Key {
    a: Microservice
    b: Database {
      shape: cylinder
      style.stroke-dash: 2
    }
    a <-> b: Good relationship {
      style.stroke: red
      style.stroke-dash: 2
    }
    a -> b: Tenuous {
      target-arrowhead.shape: circle
    }
  }
}
api-1 <-> api-2: {
  style.stroke: red
  style.stroke-dash: 2
}
api-1 -> postgres
postgres.shape: cylinder
```

To show only a connection in the legend, hide its endpoint shapes with opacity 0:
```d2
vars: {
  d2-legend: {
    a <-> b: Good relationship {
      style.stroke: red
    }
    a.style.opacity: 0
    b.style.opacity: 0
  }
}
x <-> y: {style.stroke: red}
```

---

## Globs

Globs are wildcard keys that apply settings to many objects at once. Matching is **case-insensitive**.

| Glob | Matches |
|---|---|
| `*` | direct children of the current scope (any key segment, or part of one: `*kong`, `t*h*r`) |
| `**` | all descendants of the current scope, recursively |
| `***` | everything in the whole diagram, **including nested `layers`/`scenarios`/`steps` and across imports** |
| `x.*`, `x.**` | children / descendants of `x` |
| `* -> *` | **creates** connections between every pair of matches (self-connections omitted) |
| `(a* -> b)[*]` | **targets existing** connections, all indexes |
| `(** -> **)[*]` | every existing connection, recursively |

```d2
iphone 10
iphone 11 mini
iphone 11 pro
iphone 12 mini
*.height: 300
*.width: 140
*mini.height: 200
*pro.height: 400
diddy kong
Donkey Kong
*kong.style.fill: brown
teacher
thriller
thrifter
t*h*r.shape: person
```

### Lazy: globs apply backwards and forwards
A glob rule applies to matching objects declared before it **and** after it.
```d2
a
* -> y
b
c
```
This connects `a`, `b` and `c` to `y`.

### Connection globs
```d2
Spiderman 1
Spiderman 2
Spiderman 3
* -> *: 👉
```
This creates 6 connections, with no self-loops.
```d2
lady 1
lady 2
barbie
lady 1 -> barbie: hi barbie
lady 2 -> barbie: hi barbie
(lady* -> barbie)[*].style.stroke: pink
```

### Scope
A glob only applies inside the map where it is written.
```d2
foods: {
  pizzas: {
    cheese
    sausage
    pineapple
    *.shape: circle
  }
  humans: {
    john
    james
    *.shape: person
  }
  humans.* -> pizzas.pineapple: eats
}
```

### Recursive `**`
```d2
a: {
  b: {
    c
  }
}
**.style.border-radius: 7
```
In a **connection**, `**` matches **leaf** shapes only, never containers:
```d2
zone-A: {
  machine A
  machine B: {
    submachine A
    submachine B
  }
}
zone-A.** -> load balancer
```
This connects `machine A`, `submachine A` and `submachine B`, but not `machine B`.

### Global `***`
```d2
***.style.fill: yellow
**.shape: circle
*.style.multiple: true
x: {
  y
}
layers: {
  next: {
    a
  }
}
```
Only `***` reaches `layers.next.a`. Triple globs are also the only globs carried over when a file is imported.

### Changing theme defaults
Put this at the top of the file:
```d2
***.style.fill: lightblue
(*** -> ***)[*]: {
  style.stroke: red
}
x -> y
```

### Filters `&` (include) and `!&` (exclude)
Write a filter inside the glob's map. It can filter on any reserved keyword (`shape`, `label`, `link`, `class`, `style.*`, `icon`, ...) or on a special property.

| Filter | Meaning |
|---|---|
| `&shape: person` | keyword equals value |
| `&label: likes` | label equals value. Works on connections too. |
| `&label: Hi*` | glob as the filter value |
| `&link: *` | `*` alone means "key is set" |
| `&class: server` | array-valued attribute: matches if **any** element matches |
| `&style.fill: blue` | nested attribute path |
| `&connected: true\|false` | special: the shape has any connection |
| `&leaf: true\|false` | special: the shape has no children |
| `&src: a` / `&dst: a.c` | connection endpoint ID (**absolute path**, even inside a nested scope) |
| `&src.shape: rectangle`, `&dst.style.opacity: 0.8` | connection endpoint property |
| `!&shape: person` | inverse: exclude matches |
| several `&` lines | AND |

```d2
bravo team.shape: person
charlie team.shape: person
command center.shape: cloud
hq.shape: rectangle
*: {
  &shape: person
  style.multiple: true
}
*: {
  !&shape: person
  style.fill: lightgray
}
```

```d2
**: {
  &connected: true
  style.fill: yellow
}
**: {
  &leaf: true
  style.stroke: red
}
container: {
  a -> b
}
c
```

```d2
the-little-cannon: {
  class: [server; deployed]
}
dino: {
  class: [internal; deployed]
}
catapult: {
  class: [server]
}
*: {
  &class: server
  style.multiple: true
}
```

```d2
*: {
  &link: *
  style.fill: red
}
x.link: https://google.com
y
```

The AND filter, and connections filtered by endpoint and by label:
```d2
*: {
  &shape: person
  &connected: true
  style.fill: red
}
(** -> **)[*]: {
  &src: a
  &dst: c
  style.stroke: yellow
}
(** -> **)[*]: {
  &label: likes
  style.stroke-dash: 3
}
a -> b
a.shape: person
a -> c: likes
```

Endpoint property filters:
```d2
a: {
  shape: circle
  style.fill: blue
}
b: {
  shape: rectangle
  style.opacity: 0.5
}
c: {
  shape: diamond
  style.fill: green
}
(* -> *)[*]: {
  &src.style.fill: blue
  style.stroke-dash: 3
}
(* -> *)[*]: {
  &src.shape: rectangle
  &dst.style.fill: green
  style.stroke-width: 5
}
a -> b
b -> c
a -> c
```

Endpoint IDs are absolute:
```d2
x: {
  a -> b
  (* -> *)[*]: {
    &src: x.a
    style.stroke: red
  }
}
```
Writing `&src: a` here would silently match nothing.

### Nested globs
A glob inside a glob's map is scoped to each match:
```d2
conversation 1: {
  shape: sequence_diagram
  alice -> bob: hi
  bob -> alice: hi
}
conversation 2: {
  shape: sequence_diagram
  alice -> bob: hello again
  bob -> alice: hello
}
**: {
  &shape: sequence_diagram
  **: {shape: person}
}
```

---

## Overrides and null

### Redeclaring merges
Redeclaring a key merges into the existing object, and the last explicit value wins. Keys are case-insensitive.
```d2
visual studio code text editor
visual studio code text editor: visual_studio_code_text_editor
visual studio CODE text editor: VisualStudioCodeTextEditor
visual STUDIO code text editor
```
The final label is `VisualStudioCodeTextEditor`.
```d2
aws_s3: AWS S3 California {
  Monitoring -> California
}
aws_s3: "AWS S3 San Francisco, California" {
  California.San Francisco
}
```
The result keeps both children and uses the second label.

### `null` deletes
| Target | Syntax |
|---|---|
| shape | `one: null` |
| connection | `(one -> two)[0]: null` |
| connections via glob | `(a -> *)[*]: null` |
| attribute | `one.style.stroke: null` |

```d2
one
two
one: null
x -> y
(x -> y)[0]: null
s: {
  style: {
    fill: pink
    stroke: green
  }
}
s.style.stroke: null
```

Implicit cascades:
- Nulling a shape also removes its connections.
- Nulling a shape also removes its descendants.
```d2
p -> q
q: null
one: {
  two: {
    three
  }
}
one.two: null
```

Use cases: removing unwanted parts of an imported diagram, inheriting a board in `layers`/`scenarios` minus a few objects, or excluding one pair from a glob-made batch:
```d2
a
b
c
* -> *
(a -> c)[*]: null
```

---

## Models

Define everything once, then render selective views. Two keywords do this:

| Keyword | Effect |
|---|---|
| `suspend` | hides the shape or connection (marks it for deletion) |
| `unsuspend` | restores it |

Unlike `null`, a suspended object can come back. The usual pattern is to suspend everything with globs and then unsuspend selectively with filtered globs:
```d2
restaurants: Restaurants {
  style.stroke-dash: 2
  *.style.fill: "#66c4e3"
  chip: Chipotle
  cfa: Chick-Fil-A
  bk: Burger King
  chip -> bk: competes with
}
diners: Diners {
  daniel
  zack
}
diners -> restaurants: eat at
diners.daniel -> restaurants.chip: likes
diners.daniel -> restaurants.cfa: dislikes
diners.zack -> restaurants.bk: likes
diners.zack -> restaurants.chip: likes

# treat everything above as a model
**: suspend
(** -> **)[*]: suspend

# view: only "likes" edges, plus their endpoints
(** -> **)[*]: unsuspend {
  &label: likes
}
```

Alternative views use the same model with a different final block:

| View | Unsuspend block |
|---|---|
| top level only | `*: unsuspend` and `(* -> *)[*]: unsuspend` |
| everything connected to `bk` | `(** -> **)[*]: unsuspend {&dst: restaurants.bk}` |
| only "likes" | `(** -> **)[*]: unsuspend {&label: likes}` |

As the docs show, unsuspending a connection also brings back its endpoints (and their containers). To avoid repeating the model in each file, put it in its own file and import it (see the model-view pattern in imports).

```d2
a: {
  b
}
c
a.b -> c
**: suspend
(** -> **)[*]: suspend
(** -> **)[*]: unsuspend {
  &dst: c
}
```

---

## Autoformat

```sh
d2 fmt file.d2 [more.d2 ...]   # rewrite files in place
d2 fmt --check file.d2         # exit 1 and print a warning if unformatted (CI)
echo 'a->b' | d2 fmt -         # format stdin to stdout
```
`d2 fmt` normalizes spacing, indentation, connection hyphens (`---------->` becomes `->`) and block-string indent. This input:
```d2
aws_s3:    AWS S3 California{
  Monitoring ---------->California
}
```
becomes:
```d2
aws_s3: AWS S3 California {
  Monitoring -> California
}
```

---

## Gotchas

- **`d2 validate` does not resolve vars.** An undefined `${x}`, an inner-scope reference, or spreading a scalar all pass `validate` and fail only at compile time (`could not resolve variable "x"`, `cannot spread non-composite`). To be sure, compile locally, for example `d2 in.d2 out.svg`. Never use `d2 play`.
- **A bare `$` breaks unquoted and double-quoted text.** `a: costs $5` and `"$5"` fail with `substitutions must begin on {`. Use `\$5` or `'$5'`.
- **`#` starts a comment in unquoted text.** `a: C# lang` gives label `C`. Quote it.
- **`;` splits unquoted text.** `b: x;y` gives label `x` plus a new shape `y`.
- **Single quotes:** escape `'` as `''`. `\'` is a parse error. Single quotes never substitute vars.
- **No vars in keys or IDs.** `${n} -> b` is a parse error, and `"${n}" -> b` creates a shape literally named `${n}`.
- **`vars.x: null` is invalid.** You get `"vars" must be the last part of the key`, so redefine vars inside a `vars: {}` map instead.
- **`direction` is not a `d2-config` key.** Set `direction: right` at the top level. Unknown `d2-config` keys are compile errors.
- **CLI flags and env vars beat `d2-config`.**
- **Bad filters fail silently.** A filter on an unknown key (such as `&bogus: x`) or a relative endpoint ID (`&src: a` inside `x`) silently matches nothing, with no error.
- **`* -> *` skips self-connections.** **`**` in connections skips containers** and connects only leaves.
- **`*` vs `**` vs `***`:** only `***` reaches into `layers`/`scenarios`/`steps` and survives imports. Globs in an imported file are otherwise dropped.
- **Globs are scoped to their map.** `*.shape: circle` inside `x: {}` only affects `x`'s children.
- **Globs are lazy.** Rules also apply to objects declared later in the file, and both glob keys and filter values are case-insensitive.
- **`* -> *` creates connections, while `(* -> *)[*]` edits existing ones.** Mixing them up silently adds or misses edges.
- **Redeclaring a key merges.** It never replaces, so use `null` to remove. Nulling a shape cascades to its connections and descendants.
- **Plain `d2 in.d2 out.svg` does not rewrite the source.** Formatting only happens through `d2 fmt` or an editor plugin, despite the docs saying the formatter runs "on compile".
