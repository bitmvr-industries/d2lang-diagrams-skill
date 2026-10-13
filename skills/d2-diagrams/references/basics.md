# D2 basics: shapes, connections, containers, text, icons, comments

Source: d2 docs `tour/{hello-world,shapes,connections,containers,text,icons,comments}`. All `d2` blocks compile on d2 v0.9.0 unless marked `# INVALID`.

## Contents

1. [Syntax primitives](#1-syntax-primitives) (key vs label, `:`, `;`, `.`, `{}`)
2. [Keys: naming, quoting, escaping, case](#2-keys-naming-quoting-escaping-case)
3. [Shapes](#3-shapes) (full `shape` value list)
4. [Connections](#4-connections) (operators, labels, chaining, repeats)
5. [Arrowheads](#5-arrowheads)
6. [Referencing connections](#6-referencing-connections) (`(a -> b)[i]`)
7. [Containers](#7-containers) (dot paths, nested maps, `label`, `_`)
8. [Text, Markdown, code, LaTeX](#8-text-markdown-code-latex) (block strings `|md ... |`, `|||`, `` |`...`| ``)
9. [Icons and images](#9-icons-and-images)
10. [Comments](#10-comments)
11. [Gotchas](#11-gotchas)

`d2 validate` only parses; it does NOT catch unknown shape names, bad `_` use, missing edge indexes, or reserved words in edges. Do a real compile (`d2 in.d2 out.svg`) to catch those.

## 1. Syntax primitives

| Syntax | Meaning |
|---|---|
| `x` | Declare shape with key `x` (label defaults to key) |
| `x: Label text` | Declare shape `x` with label `Label text` |
| `x -> y` | Connection; undeclared endpoints are auto-created |
| `x -> y: label` | Connection with label |
| `a; b; c` | `;` separates statements on one line |
| `x.shape: cloud` | `.` path to a field (reserved keyword) or child |
| `x: { ... }` | Map: fields/children of `x` |
| `x: Label { ... }` | Label + map at once |
| `# ...` | Line comment |
| `"""` ... `"""` | Block comment |

```d2
x -> y: hello world
```

## 2. Keys: naming, quoting, escaping, case

Unquoted keys may contain spaces, apostrophes, single hyphens, underscores.

```d2
imAShape
im_a_shape
im a shape
i'm a shape
a-shape
```

- Single `-` is part of a key. `--` (and `->`, `<-`, `<->`) inside an unquoted key makes a connection: `a--b` = `a -- b`.
- Keys are **case-insensitive**: `postgresql`, `postgreSQL`, and `PostgreSQL` are one shape. Labels keep their case.
- Leading/trailing spaces around keys and labels are trimmed.
- Quote a key with `"..."` or `'...'` if it contains syntax chars: `:` `.` `;` `{` `}` `#` `|` `[` `]` `(` `)` `->` `--`, or a reserved keyword.
- Double-quoted strings support escapes (`\"`, `\n`). Single-quoted strings are also allowed.
- Labels after `:` are unquoted strings until end of line, `;`, `{`, or `#`. Quote a label to include `#`, `;`, `{`, `}`.

```d2
"a:b" -> "c.d"
x: "say \"hi\"\nsecond line"
y: 'single quoted'
z: "has # hash; and {braces}"
```

## 3. Shapes

Default shape is `rectangle`. Set with the reserved field `shape`.

```d2
pg: PostgreSQL
Cloud: my cloud
Cloud.shape: cloud
SQLite; Cassandra
```

### Standard `shape` values (catalog)

| | | | |
|---|---|---|---|
| `rectangle` (default) | `square` | `page` | `parallelogram` |
| `document` | `cylinder` | `queue` | `package` |
| `step` | `callout` | `stored_data` | `person` |
| `diamond` | `oval` | `circle` | `hexagon` |
| `cloud` | `c4-person` | | |

Note `stored_data` uses an underscore, `c4-person` uses a hyphen.

### Special `shape` values (covered in other pages)

`text`, `code`, `image`, `class`, `sql_table`, `sequence_diagram`. The compiler also accepts `hierarchy`. Of these, the tour pages here cover only `text` (§8) and `image` (§9).

An unknown value is a compile error: `unknown shape "foo"`. `d2 validate` won't catch it.

### 1:1 ratio shapes

`circle` and `square` always have width == height. A long label grows both dimensions.

The docs say unequal `width`/`height` are both set to the larger value. **The v0.9.0 compiler instead rejects them** with `width and height must be equal for circle shapes` (the same applies to square). Set only one dimension, or set both to the same value.

```d2
c: a long label grows height too {shape: circle}
s: {shape: square; width: 100}
t: {shape: circle; width: 120; height: 120}
```

```d2
# INVALID (compile error; d2 validate passes it): unequal dims on 1:1 shape
s: {shape: square; width: 100; height: 300}
```

## 4. Connections

### Operators (exactly 4)

| Op | Meaning |
|---|---|
| `--` | undirected line |
| `->` | arrow to target |
| `<-` | arrow to source (left side) |
| `<->` | arrows both ends |

```d2
Write Replica Canada <-> Write Replica Australia
Read Replica <- Master
Write Replica -> Master
Read Replica 1 -- Read Replica 2: Kept in sync
super long shape id here -> super long shape id even longer here
```

### Connect by key, never by label

```d2
be: Backend
fe: Frontend

# Creates two NEW shapes keyed "Backend" and "Frontend"
Backend -> Frontend

# Connects the existing shapes
be -> fe
```

### Repeated connections add new edges

They never override earlier ones. This creates 3 separate edges:

```d2
Database -> S3: backup
Database -> S3
Database -> S3: backup
```

### Chaining

One line can hold many connections. A trailing label applies to **every** edge in the chain. Operators can be mixed.

```d2
High Mem Instance -> EC2 <- High CPU Instance: Hosted By
```

### Cycles are fine

```d2
Stage One -> Stage Two -> Stage Three -> Stage Four
Stage Four -> Stage One: repeat
```

### Connection map (label + fields)

```d2
a -> b: my label {
  style.stroke: red
}
c -> d: {
  label: set via keyword
}
```

## 5. Arrowheads

Arrowheads are special child fields of a connection: `source-arrowhead` and `target-arrowhead`. Each takes a label (value) and/or a map with `shape`, `label`, `style.filled`.

```d2
a: The best way to avoid responsibility is to say, "I've got responsibilities"
b: Whether weary or unweary, O man, do not rest
c: I still maintain the point that designing a monolithic kernel in 1991 is a

a -> b: To err is human, to moo bovine {
  source-arrowhead: 1
  target-arrowhead: * {
    shape: diamond
  }
}

b <-> c: "Reality is just a crutch for people who can't handle science fiction" {
  source-arrowhead.label: 1
  target-arrowhead: * {
    shape: diamond
    style.filled: true
  }
}

d: A black cat crossing your path signifies that the animal is going somewhere

d -> a -> c
```

- `source-arrowhead: 1` sets the arrowhead **label** to `1` (same as `source-arrowhead.label: 1`). `*` here is just a label string.
- Arrowhead labels do not go through autolayout, so keep them short (e.g. `1`, `*`, `0..n`).

### Arrowhead `shape` values

| Value | Notes |
|---|---|
| `triangle` | default; `style.filled: false` makes it hollow |
| `arrow` | like triangle but pointier |
| `diamond` | hollow by default; `style.filled: true` to fill |
| `circle` | hollow by default; `style.filled: true` to fill |
| `box` | hollow by default; `style.filled: true` to fill |
| `cf-one`, `cf-one-required` | crow's foot (ERD) |
| `cf-many`, `cf-many-required` | crow's foot (ERD) |
| `cross` | X |

The compiler also accepts `none` (not in the tour docs). Other values are compile errors (`unknown shape`).

```d2
a -> b: {
  source-arrowhead.shape: cf-one-required
  target-arrowhead.shape: cf-many
}
c <-> d: {
  source-arrowhead: {shape: circle; style.filled: true}
  target-arrowhead: {shape: triangle; style.filled: false}
}
e -> f: {target-arrowhead.shape: cross}
```

### Arrowheads need an endpoint

An arrowhead shape on an end with no arrow does nothing. `x -> y` has no source arrowhead, and `x -- y` has none at all. Use `<-`/`<->` to get a source end.

```d2
# Valid, but the diamond is silently ignored (no source end on ->)
x -> y: {
  source-arrowhead.shape: diamond
}
```

Observed in v0.9.0: an arrowhead *label* on a missing end still renders near that end. Only the shape is dropped.

## 6. Referencing connections

Use `(src -> dst)[index]` to address an existing edge. The index is 0-based and counts in declaration order among edges with the same endpoints and direction.

```d2
x -> y: hi
x -> y: hello

(x -> y)[0].style.stroke: red
(x -> y)[1].style.stroke: blue
```

```d2
x -> y
x -> y
# [*] targets all matching edges
(x -> y)[*].style.stroke: red
# relabel an existing edge
(x -> y)[0]: new label
```

Edges inside containers can be referenced from the container's scope or by full path:

```d2
c: {x -> y}
c.(x -> y)[0].style.stroke: red
(c.x -> c.y)[0].style.opacity: 0.5
```

```d2
# INVALID: negative index is a parse error
x -> y
(x -> y)[-1].style.stroke: red
```

```d2
# INVALID (compile error "indexed edge does not exist"; d2 validate passes it)
x -> y
(x -> y)[3].style.stroke: red
```

## 7. Containers

A shape with children is a container. You can declare children with dot paths. Each segment creates or reuses a shape.

```d2
server
# child of server
server.process

# container and child in one line
im a parent.im a child

# connections declare keys too, so this creates nested shapes
apartment.Bedroom.Bathroom -> office.Spare Room.Bathroom: Portal
```

### Nested map syntax

Keys inside a map are relative to that map.

```d2
clouds: {
  aws: {
    load_balancer -> api
    api -> db
  }
  gcloud: {
    auth -> db
  }

  gcloud -> aws
}
```

### Container labels (two ways)

```d2
# 1. shorthand
gcloud: Google Cloud {
  auth
}
# 2. reserved keyword `label`
aws: {
  label: Amazon Web Services
  ec2
}
```

### Cross-container references use full paths from current scope

```d2
clouds: {
  aws: AWS {
    load_balancer -> api
    api -> db
  }
  gcloud: Google Cloud {
    auth -> db
  }

  gcloud -> aws
}

users -> clouds.aws.load_balancer
users -> clouds.gcloud.auth

ci.deploys -> clouds
```

### Parent reference `_`

Inside a map, `_` means the parent scope. You can chain it: `_._`.

```d2
christmas: {
  presents
}
birthdays: {
  presents
  _.christmas.presents -> presents: regift
  _.christmas.style.fill: "#ACE1AF"
}
```

```d2
a: {
  b: {
    # c is created at root, d inside a.b
    _._.c -> d
  }
}
```

```d2
# INVALID: compile error "invalid underscore" (root has no parent; d2 validate passes it)
_.x -> y
```

## 8. Text, Markdown, code, LaTeX

### Block strings

`key: |<lang>` opens a block. A matching closing delimiter ends it. Content is dedented.

| Opener | Closer | Use when |
|---|---|---|
| `\|md` | `\|` | normal |
| `\|\|ts` | `\|\|` | content has `\|` |
| `\|\|\|ts` | `\|\|\|` | content has `\|\|` |
| `` \|`ts `` | `` `\| `` | any symbol(s) after first `\|`: mirrored on close |
| `\|#md` | `#\|` | same rule, other symbol |

The delimiter after the first `|` may be any chars that are not alphanumeric, space, or `_`. A letter right after `|` is read as the language (e.g. `|xmd` = language `xmd`, closed by plain `|`).

```d2
my_code: |`ts
  declare function getSmallPet(): Fish | Bird;
  const works = (a > 1) || (b < 2)
`|
```

```d2
my_code: |||ts
  declare function getSmallPet(): Fish | Bird;
  const works = (a > 1) || (b < 2)
|||
```

### Standalone Markdown (`|md`)

A shape whose value is a `|md` block renders as borderless Markdown text (GitHub-styled).

```d2
explanation: |md
  # I can do headers
  - lists
  - lists

  And other normal markdown stuff
|
```

### Markdown label inside a real shape

You must set the shape explicitly, even to the default `rectangle`. Otherwise it renders as bare text.

```d2
explanation: |md
  # I can do headers
  - lists
|
explanation.shape: rectangle
```

Markdown/code blocks also work as connection labels:

```d2
a -> b: |md
  **bold** edge label
|
```

### Code blocks

Replace `md` with a language name to get a syntax-highlighted code block. Languages come from the [Chroma](https://github.com/alecthomas/chroma) list. An unrecognized language falls back to plain text with no highlighting (no error).

```d2
explanation: |go
  awsSession := From(c.Request.Context())
  client := s3.New(awsSession)

  ctx, cancelFn := context.WithTimeout(c.Request.Context(), AWS_TIMEOUT)
  defer cancelFn()
|
```

Built-in aliases: `md`→markdown, `tex`→latex, `js`→javascript, `go`→golang, `py`→python, `rb`→ruby, `ts`→typescript.

### LaTeX (`|latex` or `|tex`)

```d2
plankton -> formula: will steal
formula: |latex
  \lim_{h \rightarrow 0 } \frac{f(x+h)-f(x)}{h}
|
```

- Rendered by MathJax. It handles math notation, not full LaTeX documents.
- `style.font-size` is ignored. Size inside the expression with `\tiny{}`, `\small{}`, `\normal{}`, `\large{}`, `\huge{}`.
- No line breaks. Use `\displaylines{a \\ b}`.
- Plugins included: `amscd`, `braket`, `cancel`, `color`, `gensymb`, `mhchem`, `physics`.

```d2
sizes: |tex
  \large{E = mc^2}
|
multi: |tex
  \displaylines{x = a + b \\ y = b + c}
|
amscd: |tex
  \begin{CD} B @>{\text{very long label}}>> C S^{{\mathcal{W}}_\Lambda}\otimes T @>j>> T\\ @VVV V \end{CD}
|
braket: |tex
  \bra{a}\ket{b}
|
cancel: |tex
  \cancel{Culture + 5}
|
color: |tex
  \textcolor{red}{y} = \textcolor{green}{\sin} x
|
gensymb: |tex
  \lambda = 10.6\,\micro\mathrm{m}
|
mhchem: |tex
  \ce{SO4^2- + Ba^2+ -> BaSO4 v}
|
physics: |tex
  \var{F[g(x)]}
  \dd(\cos\theta)
|
mathclap: |latex
  \min_{ \mathclap{\substack{ x \in \mathbb{R}^n \ x \geq 0 \ Ax \leq b }}} c^T x
|
```

### Plain (non-Markdown) text: `shape: text`

Turns any shape into a borderless plain-text label. You can still style it.

```d2
title: A winning strategy {
  shape: text
  near: top-center
  style: {
    font-size: 55
    italic: true
  }
}

poll the people -> results
results -> unfavorable -> poll the people
results -> favorable -> will of the people
```

### Unicode

Any script and emoji work in keys and labels. Use `\n` in a double-quoted label for a line break.

```d2
a: 床前明月光
b: "トマトが赤くなったのはなぜですか？\nBecause it saw the salad dressing!👩‍👩‍👧‍👶" {
  style.font-size: 55
}
c: ສະບາຍດີ (sabaai dii) - Lao
a -> b -> c
```

## 9. Icons and images

`icon:` takes any URL or, with the local CLI, a local path (`icon: ./my_cat.png`). URL-encode spaces and slashes as needed. Free icon set: https://icons.d2lang.com. Icons also work on connections.

```d2
deploy: {
  icon: https://icons.d2lang.com/aws%2FDeveloper%20Tools%2FAWS-CodeDeploy.svg
}
backup: {
  icon: https://icons.d2lang.com/aws%2FStorage%2FAWS-Backup.svg
}
deploy -> backup: {
  icon: https://icons.d2lang.com/infra%2F002-backup.svg
}
```

Placement is automatic and depends on the layout engine: container icons go top-left, non-container icons go center (avoiding the label). Override with `near` (see the positions reference).

```d2
vpc: VPC 1 10.1.0.0./16 {
  icon: https://icons.d2lang.com/aws%2F_Group%20Icons%2FVirtual-private-cloud-VPC_light-bg.svg
  style: {
    stroke: green
    font-color: green
    fill: white
  }
  az: Availability Zone A {
    style: {
      stroke: blue
      stroke-dash: 3
    }
    ec2: EC2 Instance {
      icon: https://icons.d2lang.com/aws%2FCompute%2F_Instance%2FAmazon-EC2_C4-Instance_light-bg.svg
    }
  }
}
```

### Standalone image: `shape: image`

Renders only the icon, with no box. It **requires** `icon`, or compile fails with `image shape must include an "icon" field`.

```d2
direction: right
server: {
  shape: image
  icon: https://icons.d2lang.com/tech/022-server.svg
}
github: {
  shape: image
  icon: https://icons.d2lang.com/dev/github.svg
}
server -> github
```

## 10. Comments

```d2
# Line comment: from # to end of line
x -> y # trailing comment

"""
Block comment: opens and closes with three double quotes,
each on its own line.
"""

y -> z
```

## 11. Gotchas

1. **Connect by key, not label.** `be: Backend` then `Backend -> x` creates a new shape `Backend`. Use `be -> x`.
2. **Keys are case-insensitive.** `Foo -> foo` is a self-loop on one shape.
3. **`--` inside a key is a connection.** `a--b` means `a -- b`. `a--shape` is a compile error (`reserved keywords are prohibited in edges`), because `shape` is a keyword. The docs comment says it "would be a connection"; the compiler rejects it. A single `-` (`a-shape`) is fine.
4. **No space is needed after `:`.** `a:b -> c` is shape `a` with label `b -> c`, not an edge. Quote keys that contain `:` or `.`.
5. **`#` starts a comment in unquoted labels.** `x: a # b` gives label `a`. Quote the label to keep `#`.
6. **`"""` only works as a standalone block comment.** Inline on a statement line (`x -> y """ c """`), it becomes part of the key/label text.
7. **Repeating `a -> b` adds another edge.** It does not update the old one. To modify an edge, use `(a -> b)[0].field: ...`.
8. **Chain labels apply to every edge** in the chain (`a -> b -> c: L` labels both edges).
9. **Edge indexes are 0-based, non-negative ints or `*`.** `[-1]` is a parse error. An out-of-range index is a compile error.
10. **Arrowhead shapes need an existing arrow end.** `source-arrowhead` on `->` is ignored, and so are both on `--`. The arrowhead label still renders.
11. **`source-arrowhead: X` sets a label**, not a shape. Use `.shape:` for the shape.
12. **`|md` text without an explicit `shape` renders borderless.** Add `shape: rectangle` (or another shape) to get a box.
13. **Block-string delimiters:** after `|`, a letter starts the language tag. Only non-alphanumeric, non-space, non-`_` chars form a custom delimiter, and the closer mirrors it (`` |`ts ``…`` `| ``).
14. **Unknown language** in a code block falls back to plain text silently.
15. **LaTeX ignores `font-size`** and has no line breaks. Use `\large{}`, etc., and `\displaylines{a \\ b}`.
16. **`shape: image` requires `icon`.**
17. **`_` at root is invalid** (`invalid underscore`).
18. **`circle`/`square` force 1:1.** Explicit unequal `width`/`height` is a compile error in v0.9.0. The docs say they get "maxed", which is wrong. Set one dimension or set equal ones.
19. **`d2 validate` is parse-only.** Unknown shape or arrowhead names, a bad `_`, missing edge indexes, reserved keywords in edges, `shape: image` without `icon`, and unequal width/height on circle or square all pass `validate` and fail on render. Compile (`d2 f.d2 out.svg`) to be sure.
20. **Undeclared shapes in connections are auto-created**, so a typo in a key silently creates a new shape instead of erroring.
