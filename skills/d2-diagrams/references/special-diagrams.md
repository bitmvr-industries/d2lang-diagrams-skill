# Special diagram types: SQL tables, UML classes, sequence diagrams, grids

Verified against d2 v0.9.0. Every `d2` block below compiles and renders.

## Contents
1. [SQL tables (`shape: sql_table`)](#1-sql-tables-shape-sql_table)
2. [UML classes (`shape: class`)](#2-uml-classes-shape-class)
3. [Sequence diagrams (`shape: sequence_diagram`)](#3-sequence-diagrams-shape-sequence_diagram)
4. [Grid diagrams (`grid-rows` / `grid-columns`)](#4-grid-diagrams-grid-rows--grid-columns)
5. [Gotchas](#5-gotchas)

> Validation note: `d2 validate` only parses the file. It does **not** catch many compile errors (bad
> `grid-rows` values, children on table columns, nested sequence diagrams). To be sure a file works,
> render it locally (`d2 in.d2 out.svg`). Never use `d2 play`.

---

## 1. SQL tables (`shape: sql_table`)

Each child key is a **row**: key = column name, value = column type, `constraint` = SQL constraint.

```d2
my_table: {
  shape: sql_table
  id: int {constraint: primary_key}
  last_updated: timestamp with time zone
}
```

`id: int {constraint: primary_key}` is shorthand for the map `{type: int; constraint: primary_key}`.
Types can contain spaces without quotes (`timestamp with time zone`).

### Constraints

| constraint value | rendered as |
|---|---|
| `primary_key` | `PK` |
| `foreign_key` | `FK` |
| `unique` | `UNQ` |
| anything else (e.g. `"not null"`) | shown verbatim |

Use an array for multiple constraints. They render comma-joined, e.g. `PK, UNQ`:

```d2
t: {
  shape: sql_table
  id: int {constraint: [primary_key; unique]}
  email: text {constraint: [unique; "not null"]}
}
```

### Reserved keywords as column names: quote them

```d2
my_table: {
  shape: sql_table
  "label": string
  "shape": text
}
```

If you leave `label: string` unquoted, it silently sets the table's **title** to "string" and no
column is created. No error is raised.

### Foreign keys: column-to-column connections

Connect `table.column -> table.column`:

```d2
objects: {
  shape: sql_table
  id: int {constraint: primary_key}
  disk: int {constraint: foreign_key}
  json: jsonb {constraint: unique}
  last_updated: timestamp with time zone
}
disks: {
  shape: sql_table
  id: int {constraint: primary_key}
}
objects.disk -> disks.id
```

- Arrows point at the exact row only with the **TALA** or **ELK** layout engines (`--layout elk`).
  With dagre (the default) they attach to the table.
- Columns cannot have children: `id: {a: b}` gives the compile error `sql_table columns cannot have children`.

### Nesting and connecting tables

Tables behave like any other shape. They can sit in containers and connect to other shapes:

```d2
cloud: {
  disks: {
    shape: sql_table
    id: int {constraint: primary_key}
  }
  blocks: {
    shape: sql_table
    id: int {constraint: primary_key}
    disk: int {constraint: foreign_key}
    blob: blob
  }
  blocks.disk -> disks.id
  AWS S3 Vancouver -> disks
}
```

---

## 2. UML classes (`shape: class`)

Each child key is a **field** or a **method**:

| key form | meaning | value |
|---|---|---|
| no `(` in key | field | field type (may be omitted) |
| key contains `(` | method | return type; omit it for `void` |

```d2
MyClass: {
  shape: class
  field: "[]string"
  method(a uint64): (x, y int)
  noReturn()
}
```

- Quote any type that starts with `[`, because unquoted `[` starts a D2 array. `field: []string` fails
  with `unexpected text after array`. Quote types containing `#`, `;`, `{` and similar characters as well.
- A method with no value renders as `void`. A field with no value renders with an empty type.
- Quote reserved keywords: `"label": string`.
- Class members cannot have children (`class fields cannot have children`).

### Visibility prefixes

| prefix | meaning | how to write it |
|---|---|---|
| none | public | `name: T` |
| `+` | public | `+name: T` |
| `-` | private | `-name: T` |
| `#` | protected | `\#name: T` (**escape it**, since a bare `#` starts a comment) |

Other prefixes such as `~` (package) are **not** recognized. `~d` renders as a public member literally named `~d`.

```d2
D2 Parser: {
  shape: class
  +reader: io.RuneReader
  readerPos: d2ast.Position
  -lookahead: "[]rune"
  \#lookaheadPos: d2ast.Position
  +peek(): (r rune, eof bool)
  rewind()
  commit()
  \#peekn(n int): (s string, eof bool)
}
"github.com/terrastruct/d2parser.git" -> D2 Parser
```

An unescaped `#p: int` inside a map comments out the rest of the line. In `{...}` on one line this
yields `maps must be terminated with }`.

### Labels and UML relationships

Set the display name with the label shorthand. Draw relationships with ordinary connections plus arrowhead settings:

```d2
direction: right
DebitCard: Debit card {
  shape: class
  +cardno
  +ownedBy
  +access()
}
Bank: {
  shape: class
  +code
  +manages()
}
Account: {
  shape: class
  +type
}
CurrentAccount: Current account {
  shape: class
  +balance
  +debit()
}
# association with multiplicities (undirected edge)
DebitCard -- Bank: manages {
  source-arrowhead: 1..*
  target-arrowhead: 1
}
DebitCard -- Account: +provides access to {
  source-arrowhead: *
  target-arrowhead: 1..*
}
# inheritance: hollow triangle
CurrentAccount -> Account: {
  target-arrowhead.shape: triangle
  target-arrowhead.style.filled: false
}
```

The docs render the full class example with `--layout elk`.

---

## 3. Sequence diagrams (`shape: sequence_diagram`)

Set `shape: sequence_diagram` on an object, or at the root to make the whole diagram one. There is
no special syntax: actors are objects and messages are connections.

```d2
shape: sequence_diagram
alice -> bob: What does it mean\nto be well-adjusted?
bob -> alice: The ability to play bridge or\ngolf as if they were games.
```

### Glossary

| D2 term | a.k.a. elsewhere | how it is created |
|---|---|---|
| actor | participant | a top-level child of the sequence diagram |
| lifeline | | the vertical line under each actor (automatic) |
| message | | a connection between actors or spans |
| span | lifespan, activation box/bar | a nested object on an actor that has a connection (`alice.t1 -> bob`) |
| group | fragment, edge group, frame | a container with no connections of its own that holds messages or notes |
| note | | a nested object on an actor with **no** connections |
| self-message | | `a -> a` |

### Rule 1: ordering matters

Everywhere else in D2, definition order does not matter. In sequence diagrams, **definition order is
render order** for both messages (top to bottom) and actors (left to right, in order of first
appearance). To fix the actor order, declare the actors first:

```d2
shape: sequence_diagram
# actors appear left-to-right as a, b, c, d
a; b; c; d
# ...even though the connections first mention c, d
c -> d
d -> a
b -> d
```

### Rule 2: shared scope

All descendants of a sequence diagram share **one scope**. Inside nested groups, `alice` refers to
the top-level actor `alice`, not to a new `group.alice`. (Outside sequence diagrams, each container
would get its own `alice`.)

```d2
Office chatter: {
  shape: sequence_diagram
  alice: Alice
  bob: Bobby
  awkward small talk: {
    alice -> bob: uhm, hi
    bob -> alice: oh, hello
    icebreaker attempt: {
      alice -> bob: what did you have for lunch?
    }
    unfortunate outcome: {
      bob -> alice: that's personal
    }
  }
}
```

### Groups

A group is a container inside the sequence diagram that is not connected to anything and that holds
connections or objects. Groups can nest (see above).

```d2
shape: sequence_diagram
# Predefine actors. REQUIRED when they first appear in a group.
alice
bob
shower thoughts: {
  alice -> bob: A physicist is an atom's way of knowing about atoms.
  alice -> bob: Today is the first day of the rest of your life.
}
life advice: {
  bob -> alice: If all else fails, lower your standards.
}
```

**Caution:** objects referenced inside a group must already exist at the top level, declared
*before* the group. Otherwise the compiler silently creates `group.alice` and `group.bob` as group-local
objects, and the group itself becomes an actor with a lifeline. Declaring the actors after the group
does not fix this. It compiles but renders wrong.

### Spans (activations)

Connect to or from a **nested object on an actor**. The nested key names the span, and spans can nest.

```d2
shape: sequence_diagram
alice.t1 -> bob
alice.t2 -> bob.a
alice.t2.a -> bob.a
alice.t2.a <- bob.a
alice.t2 <- bob.a
```

- Each distinct child key (`t1`, `t2`, `t2.a`) is a separate span. Reusing a key extends that span
  across its messages.
- `<-` is a reverse arrow (`a <- b` means a message from b to a). Use it for return messages.

### Notes

A nested object on an actor with **no** connections is a note. Notes can go inside groups. Quote any
note text that contains punctuation.

```d2
shape: sequence_diagram
alice -> bob
bob."In the eyes of my dog, I'm a man."
important insight: {
  bob."Cold hands, no gloves."
}
bob -> alice: Chocolate chip.
```

A note can also be given a key plus a label and style, like `bob.n: "note text" {shape: page}`.

### Self-messages

```d2
shape: sequence_diagram
son -> father: Can I borrow your car?
friend -> father: Never lend your car to anyone to whom you have given birth.
father -> father: internal debate ensues
```

### Styling actors, messages, lifelines

Style shapes and connections as usual. Common patterns: a `person` shape for actors and dashed
return messages.

```d2
shape: sequence_diagram
scorer: {shape: person}
scorer.t -> itemResponse.t: getItem()
scorer.t <- itemResponse.t: item {
  style.stroke-dash: 5
}
scorer.t -> essayRubric.t: applyTo(essayResp)
itemResponse -> essayRubric.t.c
essayRubric.t.c -> concept.t: match(essayResponse)
scorer <- essayRubric.t: score {
  style.stroke-dash: 5
}
```

**Lifelines inherit the actor's `style.stroke` and `style.stroke-dash`.** Lifelines are dashed by
default, so `stroke-dash: 0` makes one solid:

```d2
shape: sequence_diagram
alice -> bob: hi
bob -> alice: hello
alice.style: {
  stroke: red
  stroke-dash: 0
}
```

### Sequence diagrams as ordinary objects

A sequence diagram can be nested in containers, labeled, styled and connected like any other object.
Connections into its actors from outside are allowed, e.g. `x -> seq.alice`.

```d2
direction: right
Before and after becoming friends: {
  2007: Office chatter in 2007 {
    shape: sequence_diagram
    alice: Alice
    bob: Bobby
    alice -> bob: uhm, hi
  }
  2012: Office chatter in 2012 {
    shape: sequence_diagram
    alice: Alice
    bob: Bobby
    bob -> alice.play: Write a play...
    alice.play -> bob.play: about 2 friends...
  }
  2007 -> 2012: Five\nyears\nlater
}
```

- An actor **cannot itself be a sequence diagram**. This is a compile error:
  `actors in sequence diagrams cannot themselves be sequence diagrams`.
- A sequence diagram *can* be a grid cell (see §4 Nesting).

---

## 4. Grid diagrams (`grid-rows` / `grid-columns`)

Set `grid-rows` and/or `grid-columns` on a container (or at the root). Its children become cells.

```d2
grid-rows: 3
Executive
Legislative
Judicial
```

| keyword | value | effect |
|---|---|---|
| `grid-rows` | positive int | number of rows |
| `grid-columns` | positive int | number of columns |
| `grid-gap` | non-negative int | sets both vertical and horizontal gap |
| `vertical-gap` | non-negative int | gap between rows; overrides `grid-gap` |
| `horizontal-gap` | non-negative int | gap between columns; overrides `grid-gap` |

`0`, negative or non-integer values for rows/columns are compile errors (`grid-rows must be a positive
integer`). A negative gap is also an error. `d2 validate` does not catch these, so render to check.

### Rows only, columns only, both

```d2
grid-columns: 3
Executive
Legislative
Judicial
```

```d2
grid-rows: 2
grid-columns: 2
Executive
Legislative
Judicial
```

- **Fill order (verified v0.9.0):** `grid-columns` alone fills **column by column** (6 cells, 3 columns:
  `a c e / b d f`). For reading order (`a b c / d e f`), set `grid-rows` first, then `grid-columns`.
- With only one of the two set, the other dimension is computed and cells **expand to fill** the
  row (or column) width. With `grid-rows` alone, cells are distributed across rows, and the counts
  per row may be uneven.
- When both are set and there are more cells than `rows*cols`, the grid grows along the dominant
  direction (see below). Example: `grid-rows: 2` then `grid-columns: 4` with 16 cells gives 4 rows of 4.

### Dominant direction: whichever keyword appears first

Cells are filled in the order of the first keyword defined.

```d2
# grid-rows first: fill row by row: a b / c d / e f ...
grid-rows: 4
grid-columns: 2
a; b; c; d; e; f; g; h
```

```d2
# grid-columns first: fill column by column: a b c d down column 1, then e f g h
grid-columns: 2
grid-rows: 4
a; b; c; d; e; f; g; h
```

Grid build-up can be animated with `steps` that each add one cell, rendered with the
`--animate-interval` flag:

```d2
grid-rows: 2
grid-columns: 2
a
steps: {
  1: {b}
  2: {c}
  3: {d}
}
```

### Width and height of cells

Set `width` and/or `height` on cells. Cells in the same row share a height, and cells in the same column share a width.
Within a row, cells are evenly distributed, and a cell may be stretched beyond its set width to fill.

```d2
grid-rows: 3
Executive
Legislative
Judicial
The American Government.width: 400
Voters
Non-voters
```

### Gap 0: tables, maps, tight layouts

```d2
# row-dominant so cells are written row by row
grid-rows: 2
grid-columns: 4
grid-gap: 0
classes: {
  header: {style.underline: true}
}
Element.class: header
Atomic Number.class: header
Atomic Mass.class: header
Melting Point.class: header
Hydrogen
1
"1.008"
"-259.16"
Carbon
6
"12.011"
3500
```

- Quote numeric-looking cell names that contain `.` or a leading `-`, because `.` is the key-path separator.
- Cell keys must be unique. **For data tables with duplicate values, use a Markdown table**:

```d2
savings: ||md
  | Month    | Savings | Expenses | Balance |
  | -------- | ------- | -------- | ------- |
  | January  | $250    | $150     | $100    |
  | February | $80     | $200     | -$120   |
||
```

(Use `||md ... ||` when the content contains a single `|`.)

### Connections

- Connections **to or from a grid container** (or from outside into a cell) work normally.
- Connections **between cells** in dagre or ELK are straight center-to-center lines with no
  pathfinding, so they may cross other cells. TALA routes them properly.

```d2
direction: right
users: "" {
  grid-columns: 1
  Engineers: {shape: circle}
  Machines: {shape: circle}
}
teleport: Teleport {
  grid-rows: 2
  inp: |md
    # Identity Native Proxy
  | {
    width: 300
  }
  Audit Log
  Cert Authority
}
users -> teleport
teleport.Audit Log -> teleport.Cert Authority
```

### Nesting

Grid cells can be grids, sequence diagrams, or regular containers. `label: ""` (or `name: ""`) hides a container label.

```d2
grid-gap: 0
grid-columns: 1
header
body: "" {
  grid-gap: 0
  grid-columns: 2
  content
  sidebar
}
footer
```

```d2
grid-columns: 2
flow: {
  a -> b
}
chat: {
  shape: sequence_diagram
  alice -> bob: hi
}
```

### Aligning with invisible padding cells

To center or shift cells, pad the grid with invisible elements (`style.opacity: 0`). Give the padding
cells a label similar in size to the real cells so they take the same space.

```d2
classes: {
  invisible: {
    style.opacity: 0
    label: a
  }
}
grid-columns: 1
us-east-1: {
  grid-rows: 1
  a; b; c; d; e
}
us-west-1: {
  grid-rows: 1
  pad1.class: invisible
  pad2.class: invisible
  a
  # move the container label so the connection doesn't cross it
  label.near: bottom-center
}
us-east-1.c -> us-west-1.a
```

### Troubleshooting: extra padding in one cell

Cells in a column share a width and cells in a row share a height. One wider label (e.g. "FLASK POD"
vs "NEXT POD") therefore widens the whole column and leaves empty space in sibling containers.
Fix it by setting matching explicit `width`s on the cells, usually through a class:

```d2
classes: {
  pod: {width: 180}
}
Kubernetes: {
  grid-columns: 1
  Backend Node: {
    grid-columns: 2
    ClusterIP Service 1
    Deployment 1: {
      grid-rows: 2
      NEXT POD 1
      NEXT POD 2
    }
  }
  Frontend Node: {
    grid-columns: 2
    ClusterIP Service 2
    Deployment 2: {
      grid-rows: 2
      FLASK POD 1
      FLASK POD 2
    }
  }
}
kubernetes.backend node.deployment 1.next pod*.class: pod
kubernetes.frontend node.deployment 2.flask pod*.class: pod
```

(Keys are case-insensitive, so `kubernetes.backend node` matches `Kubernetes.Backend Node`. A `*` glob
applies the class to every matching cell.)

---

## 5. Gotchas

1. **`d2 validate` is parse-only.** It passes `grid-rows: 0`, `grid-rows: two`, children under
   sql/class rows, and nested sequence diagrams, all of which fail at render. Verify with `d2 in.d2 out.svg`.
2. **sql_table / class reserved keys:** an unquoted `label`, `shape`, `style`, `width` and so on inside
   a table or class is treated as the keyword, not as a row or field. Quote it (`"label": string`). It fails silently.
3. **Protected `#` must be escaped:** `\#field: T`. A bare `#` starts a comment.
4. **Quote types that start with `[`** (`"[]string"`). Otherwise they parse as an array.
5. **Class: `(` in the key makes it a method.** The value is the return type, and no value means `void`. Only
   `+ - #` are visibility prefixes, and `~` is not recognized.
6. **Multiple constraints use array syntax with `;`**: `{constraint: [primary_key; unique]}`, not commas.
7. **Row-level FK arrows need ELK/TALA.** Dagre attaches them to the table box.
8. **Table columns and class members cannot have children** (compile error).
9. **Sequence order = source order** for both actors and messages. Declare actors up front to control left-to-right order.
10. **Declare actors at the top level BEFORE any group that uses them.** Otherwise the group gets its
    own private copies, the group renders as an actor, and no error is raised.
11. **Shared scope:** inside a sequence diagram, `alice` in any nested group is the same top-level `alice`.
    You cannot have two different `alice`s.
12. **Span vs note:** a nested object on an actor is a span if it has a connection and a note if it has none.
    A typo in a span name (`alice.t1` vs `alice.tl`) silently creates a second span.
13. **Lifeline styling goes on the actor** (`alice.style.stroke`, `alice.style.stroke-dash`). Lifelines
    are dashed by default, so set `stroke-dash: 0` for a solid one.
14. **An actor cannot be a `sequence_diagram`.** A sequence diagram inside a grid cell or a container is fine.
15. **Grid dominant direction = whichever of `grid-rows` / `grid-columns` appears first** in the map.
    Overflow grows along that direction.
16. **Grid cells in one row share a height and cells in one column share a width.** Fix stray padding with explicit `width`/`height`.
17. **Cells are unique keys.** Duplicate cell text (e.g. two `1` cells) merges into one object. Use
    distinct keys with labels (`r1c2: "1"`) or a Markdown table.
18. **Cell names with `.` must be quoted** (`"1.008"`), since `.` is the path separator.
19. **Cell-to-cell connections are straight lines in dagre/ELK** and can overlap cells. Use TALA
    for routing, or rearrange the cells.
20. **Gap keywords:** `grid-gap` sets both. `vertical-gap`/`horizontal-gap` override it regardless of order.
    Values must be non-negative ints.
