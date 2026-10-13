# D2 Styling Reference (d2 v0.9.0)

Covers: themes, `style.*`, classes, width/height, `near`/positions, sketch, tooltips/links, fonts, legend.
All d2 blocks below compile and render with d2 v0.9.0.

**Validation warning:** `d2 validate` only checks syntax. Bad style values (out-of-range numbers, unknown colors, wrong shape for `3d`) and layout-engine restrictions are only caught when you actually render: `d2 in.d2 out.svg`.

## Contents
1. [Style keyword table](#style-keyword-table)
2. [Style syntax and examples](#style-syntax-and-examples)
3. [Root-level styles](#root-level-styles)
4. [sql_table / class shape coloring](#sql_table--class-shape-coloring)
5. [Themes](#themes)
6. [Theme overrides](#theme-overrides)
7. [Classes](#classes)
8. [Dimensions (width/height)](#dimensions-widthheight)
9. [Positions: near, top/left](#positions-near-topleft)
10. [Sketch mode](#sketch-mode)
11. [Interactive: tooltips and links](#interactive-tooltips-and-links)
12. [Fonts](#fonts)
13. [Legend](#legend)
14. [Gotchas](#gotchas)

## Style keyword table

Applies-to: S = shape, C = connection, R = root (diagram). "Values" are what the v0.9.0 compiler enforces.

| Keyword | Values | S | C | R | Notes |
|---|---|---|---|---|---|
| `opacity` | float `0`-`1` | Y | Y | - | `0` hides the element (also hides it from a legend). |
| `stroke` | color | Y | Y | Y | Root: frame around diagram. sql_table/class: body fill. |
| `fill` | color | Y | - | Y | `transparent` is valid. Root: background. sql_table/class: header fill. |
| `fill-pattern` | `dots` `lines` `grain` `paper` `none` | Y | - | Y | `none` cancels a theme default. `paper` is accepted by the compiler but undocumented. |
| `stroke-width` | int `0`-`15` | Y | Y | Y | Docs say 1-15; compiler allows 0 (no border). |
| `stroke-dash` | int `0`-`10` | Y | Y | Y | `0` = solid. |
| `border-radius` | int `0`+ | Y | Y | - | Docs say 0-20; larger values work (`999` makes a pill shape). Connections: rounds route corners (only engines with corners, e.g. ELK). |
| `shadow` | `true`/`false` | Y | - | - | |
| `3d` | `true`/`false` | Y | - | - | Only `rectangle`, `square`, `hexagon` (render error otherwise). |
| `multiple` | `true`/`false` | Y | - | - | Stacked-copies look. Works on most shapes (cylinder, circle, ...). |
| `double-border` | `true`/`false` | Y | - | Y | Only `rectangle`, `square`, `circle`, `oval` (render error otherwise). Root: two frames. |
| `font` | `mono` | Y | Y | - | The only valid value. |
| `font-size` | int `8`-`100` | Y | Y | - | |
| `font-color` | color | Y | Y | - | sql_table/class: header text only. |
| `animated` | `true`/`false` | Y | Y | - | Animation is only visible in SVG output. |
| `bold` | `true`/`false` | Y | Y | - | Shape labels are bold by default. Bold wins over italic. |
| `italic` | `true`/`false` | Y | Y | - | Set `bold: false` to see italic on shapes. |
| `underline` | `true`/`false` | Y | Y | - | |
| `text-transform` | `uppercase` `lowercase` `capitalize` `none` | Y | Y | - | Docs list `title`, which the compiler REJECTS. Use `capitalize`. `none` cancels the Terminal theme's caps. |

**Color values:** a CSS named color (`deepskyblue`, `PapayaWhip`; case-insensitive), a hex code that MUST be quoted (`"#f4a261"`, `"#f00"`), `transparent`, or a gradient string such as `"linear-gradient(#f69d3c, #3f87a6)"` or `"radial-gradient(red, blue)"` (only a subset of CSS gradients is supported).

The compiler silently accepts some keys outside their documented scope (for example `fill`, `shadow`, `3d` on connections, and `opacity`/`shadow`/`font-size` at root). It does not report them, but they are unsupported, so stick to the table.

## Style syntax and examples

Styles go under `style`, either as a map or as dotted keys:

```d2
direction: right
x -> y: hi {
  style: {
    stroke: deepskyblue
    stroke-width: 8
    stroke-dash: 3
    opacity: 0.4
    font-color: red
    font-size: 28
    font: mono
    bold: true
    animated: true
    text-transform: capitalize
  }
}
x.style.fill: "#f4a261"
x.style.stroke: "#f4a261"
x.style.border-radius: 3
x.style.shadow: true
x.style.3d: true
x.style.underline: true
y.style.italic: true
y.style.bold: false
y.style.multiple: true
y.style.fill-pattern: lines
y.style.text-transform: uppercase
```

Fill variants, transparency, patterns:

```d2
x: {
  y
  y.style.fill: transparent
}
x.style.fill: PapayaWhip
z.style.fill: "linear-gradient(#f69d3c, #3f87a6)"
p.style.fill-pattern: dots
q.style.fill-pattern: grain
```

Shape-restricted styles and pill:

```d2
a.style.3d: true
h: {shape: hexagon; style.3d: true}
c: {shape: circle; style.double-border: true}
r.style.double-border: true
tylenol.style.border-radius: 999
```

## Root-level styles

`style` at the top level (not on any object) styles the diagram itself. Documented root keys: `fill` (background), `fill-pattern`, `stroke` (frame), `stroke-width`, `stroke-dash`, `double-border` (two frames).

```d2
direction: right
x -> y: hi
style: {
  fill: LightBlue
  fill-pattern: dots
  stroke: FireBrick
  stroke-width: 2
  double-border: true
}
```

When using `stroke` as a frame, add padding (`--pad` or `pad` in `d2-config`).

## sql_table / class shape coloring

On `sql_table` and `class` shapes, `fill` colors the header, `stroke` colors the body, and `font-color` colors only the header text. The theme controls the other body colors.

```d2
costumes: {
  shape: sql_table
  id: int {constraint: primary_key}
  silliness: int
  style.fill: "#2E7D32"
  style.stroke: "#C5E1A5"
  style.font-color: "#8AF5B0"
}
parser: {
  shape: class
  -lookahead: "[]rune"
  +peek(): (r rune, eof bool)
  style.font-color: "#8AF5B0"
}
costumes -> parser
```

## Themes

CLI: `d2 -t 101 in.d2` / `--theme 101` / env `D2_THEME=101`. Dark-mode variant (applied when the viewer's OS prefers dark): `--dark-theme 200` / env `D2_DARK_THEME=200`. By default no dark theme is set, so the diagram looks the same in light and dark mode. You can pass any ID to either flag, so a dark theme can be used as the main theme. `d2 themes` lists the IDs.

In-file equivalent (`vars.d2-config`):

```d2
vars: {
  d2-config: {
    theme-id: 4
    dark-theme-id: 200
  }
}
a -> b
```

| ID | Name | Kind |
|---|---|---|
| 0 | Neutral Default | light (default) |
| 1 | Neutral Grey | light |
| 3 | Flagship Terrastruct | light |
| 4 | Cool Classics | light |
| 5 | Mixed Berry Blue | light |
| 6 | Grape Soda | light |
| 7 | Aubergine | light |
| 8 | Colorblind Clear | light |
| 100 | Vanilla Nitro Cola | light |
| 101 | Orange Creamsicle | light |
| 102 | Shirley Temple | light |
| 103 | Earth Tones | light |
| 104 | Everglade Green | light |
| 105 | Buttered Toast | light |
| 300 | Terminal | light, special |
| 301 | Terminal Grayscale | light, special |
| 302 | Origami | light, special |
| 303 | C4 | light, special |
| 200 | Dark Mauve | dark |
| 201 | Dark Flagship Terrastruct | dark |

(There is no ID 2.) Themes also color special shapes such as `sql_table`.

**Special themes** change more than colors. Terminal (300) defaults: all-caps labels, no border radius, monospace font, `fill-pattern: dots` on containers, `double-border: true` on the outermost container. Undo these per object with `text-transform: none`, `fill-pattern: none`, `double-border: false`.

```d2
vars: {
  d2-config: {
    layout-engine: elk
    theme-id: 300
  }
}
network: {
  cell tower: {
    satellites: {shape: stored_data; style.multiple: true}
    transmitter
    satellites -> transmitter: send
  }
  data processor: {
    storage: {shape: cylinder; style.multiple: true}
  }
  cell tower.transmitter -> data processor.storage: phone logs
}
user: {shape: person; width: 130}
user -> network.cell tower: make call {style.stroke-dash: 3}
```

## Theme overrides

`theme-overrides` replaces color codes of the active theme. `dark-theme-overrides` does the same for the dark theme. Values must be a named color or a hex code (no gradients).

```d2
vars: {
  d2-config: {
    theme-overrides: {
      B1: "#2E7D32"
      B2: "#66BB6A"
      B3: "#A5D6A7"
      B4: "#C5E1A5"
      B5: "#E6EE9C"
      B6: "#FFF59D"
      AA2: "#0D47A1"
      AA4: "#42A5F5"
      AA5: "#90CAF9"
      AB4: "#F44336"
      AB5: "#FFCDD2"
      N1: "#111111"
    }
    dark-theme-overrides: {
      B1: "#FFFFFF"
    }
  }
}
a -> b
```

Valid codes (the compiler checks them; any other code fails with `is not a valid theme code`):
- `N1`-`N7`: neutrals (text, backgrounds, borders)
- `B1`-`B6`: base/primary colors (shape fills and strokes, darkest to lightest)
- `AA2`, `AA4`, `AA5`: alternative accent A
- `AB4`, `AB5`: alternative accent B

The exact role of each code is shown only in an image in the docs. Some codes are reserved and not used yet.

## Classes

Define reusable attribute bundles under top-level `classes`, then apply them with `.class`. A class can hold any attributes, not just style: `label`, `shape`, `icon`, `width`, `height`, `style.*`.

```d2
direction: right
classes: {
  load balancer: {
    label: load\nbalancer
    width: 100
    height: 200
    style: {
      stroke-width: 0
      fill: "#44C7B1"
      shadow: true
      border-radius: 5
    }
  }
  unhealthy: {
    style: {
      fill: "#FE7070"
      stroke: "#F69E03"
    }
  }
}
web traffic -> web lb
web lb.class: load balancer
web lb -> api1
web lb -> api2
api2.class: unhealthy
```

Connections can take a class when declared or later by index:

```d2
classes: {something: {style.stroke: red}}
a -> b: {class: something}
c -> d
(c -> d)[0].class: something
```

**Overriding:** an attribute set on the object wins over the same attribute from its class.

```d2
classes: {unhealthy: {style.fill: red}}
x.class: unhealthy
x.style.fill: orange
```

**Multiple classes:** use an array whose items are separated by `;` (a comma is NOT a separator). Classes are applied left to right, so later ones win.

```d2
classes: {
  d2: {
    label: ""
    icon: https://play.d2lang.com/assets/icons/d2-logo.svg
  }
  sphere: {
    shape: circle
    style.stroke-width: 0
  }
  uno: {label: 1}
  dos: {label: 2}
}
logo.class: [d2; sphere]
x.class: [uno; dos]
y.class: [dos; uno]
```
Here `x` is labeled `2` and `y` is labeled `1`.

**Classes as tags:** every applied class name is written to the SVG element's `class` attribute, so CSS or JS on the host page can target it (e.g. `.stuff {...}`).

## Dimensions (width/height)

`width` and `height` (pixels) work on most shapes. They go at the top level of the object, NOT under `style`.

```d2
direction: right
small: "" {
  shape: image
  icon: https://icons.terrastruct.com/essentials%2F005-programmer.svg
  width: 200
  height: 200
}
box: {width: 300; height: 50}
small -> box
```

On containers, width/height work only with ELK or TALA (TALA may grow the container to fit its children). With dagre, the render fails with `does not support dimensions set on containers`.

## Positions: near, top/left

Normally the layout engine places everything. Two ways to override that:

### near (constant positions)
Values: `top-left`, `top-center`, `top-right`, `center-left`, `center-right`, `bottom-left`, `bottom-center`, `bottom-right`. You can only use these on **root-level** shapes; on a nested shape the render fails. A `near`-constant shape can still connect to other shapes. Use it for titles, legends, and side explanations.

```d2
title: |md
  # A winning strategy
| {near: top-center}

explanation: |md
  Longform notes go here.
| {near: center-left}

legend: {
  near: bottom-center
  color1: foo {
    shape: text
    style.font-color: green
  }
  color2: bar {
    shape: text
    style.font-color: red
  }
}

poll the people -> results
results -> favorable: {style.stroke: green}
results -> unfavorable: {style.stroke: red}
```

### label.near / icon.near
`label.near` and `icon.near` take all of the constants above, plus:
- outside the shape: `outside-top-left`, `outside-top-center`, `outside-top-right`, `outside-left-center`, `outside-right-center`, `outside-bottom-left`, `outside-bottom-center`, `outside-bottom-right`. Note the order: it is `outside-left-center`, but `center-left`.
- on the border: `border-` prefix, e.g. `border-top-center`, `border-left-center`.

```d2
direction: right
x: worker {
  label.near: top-center
  icon: https://icons.terrastruct.com/essentials%2F005-programmer.svg
  icon.near: outside-top-right
}
y: profits {
  label.near: bottom-right
}
env: Your environment {
  label.near: outside-bottom-center
  app: Your application {
    label.near: border-top-center
  }
}
x -> y
```

### near another object (TALA only)
`near: <absolute id>` hints that a shape should be placed next to another shape. Dagre and ELK reject this at render time.

```d2
vars: {
  d2-config: {
    layout-engine: tala
  }
}
aws: {
  load_balancer -> api
  api -> db
}
gcloud: {
  auth -> db
}
gcloud -> aws
explanation: |md
  # Why do we use AWS?
  - It has more uptime than GCloud
| {
  near: aws
}
```

### top / left (TALA only)
Locks an object at absolute coordinates, and TALA arranges the other objects around it. Set **both** `top` and `left`. Dagre and ELK reject them at render time.

```d2
vars: {
  d2-config: {
    layout-engine: tala
  }
}
x: {
  top: 100
  left: 100
}
x -> y
```

## Sketch mode

Hand-drawn look. CLI: `d2 --sketch in.d2 out.svg`. In the file: `sketch: true` in `d2-config`. Sketch uses a hand-drawn font (a blend of Architect's Daughter and Fuzzy Bubbles).

```d2
vars: {
  d2-config: {
    sketch: true
  }
}
a -> b
```

## Interactive: tooltips and links

`tooltip` shows text on hover, and `link` makes the element clickable. Both work on shapes and connections and are interactive in SVG. In static exports (PNG/PDF), icons are numbered and an appendix lists the tooltip/link text for each number.

```d2
x: I'm a Mac {
  link: https://apple.com
  tooltip: Total abstinence is easier than perfect moderation
}
y: And I'm a PC {
  link: "https://example.com/page#fragment"
}
x -> y: gazoontite {
  link: https://google.com
  tooltip: hover text on a connection
}
```

- Tooltips use the HTML `title` attribute, so markdown is NOT rendered and the text shows as plain text. Inside a tooltip, `\n` gives a line break.
- **A `#` in an unquoted URL starts a comment**, so `https://x.com/p#frag` silently becomes `https://x.com/p`. Quote the URL or escape the `#` (`\#`).
- `tooltip.near: <constant>` turns the tooltip into an always-visible label at that position:

```d2
codedeploy: {
  tooltip: God has abandoned this pipeline
  tooltip.near: center-left
}
ci-runner -> codedeploy
```

## Fonts

Default font families: Source Sans Pro (labels, markdown), Source Code Pro (code, `class` shape, `style.font: mono`), and an Architect's Daughter + Fuzzy Bubbles blend (sketch). In D2 source the only font choice is `style.font: mono`. You can only replace fonts with CLI flags that take `.ttf` files:

| Flag | Replaces |
|---|---|
| `--font-regular`, `--font-italic`, `--font-bold`, `--font-semibold` | Source Sans Pro styles |
| `--font-mono`, `--font-mono-italic`, `--font-mono-bold`, `--font-mono-semibold` | Source Code Pro styles |

Example: `d2 --font-regular=./helvetica-regular.ttf in.d2`. Supply all four of a family or none; any style you omit falls back to the default font. In sketch mode, the supplied fonts replace the hand-drawn font instead of Source Sans Pro.

## Legend

Declare a legend with the special variable `vars.d2-legend`. Every shape and connection inside it becomes a legend entry, labeled with its label. To rename the legend title, give `d2-legend` a label. Shapes with `opacity: 0` are left out, which lets you list only the connection from `a -> b` (that line declares 3 entries: 2 shapes and 1 connection).

```d2
vars: {
  d2-legend: "Key" {
    a: {
      label: Microservice
    }
    b: Database {
      shape: cylinder
      style.stroke-dash: 2
    }
    a <-> b: Good relationship {
      style.stroke: red
      style.stroke-dash: 2
      style.stroke-width: 1
    }
    a -> b: Tenuous {
      target-arrowhead.shape: circle
    }
    c <-> d: Hidden-shape entry {
      style.stroke: blue
    }
    c.style.opacity: 0
    d.style.opacity: 0
  }
}
api-1 -> postgres
postgres: {shape: cylinder}
api-1 <-> api-2: {
  style.stroke: red
  style.stroke-dash: 2
}
```

## Gotchas

- **`d2 validate` passes invalid styles.** Range errors, bad colors, unknown `fill-pattern`/`text-transform`/`font` values, `3d`/`double-border` on the wrong shape, nested `near` constants, and layout-engine restrictions only fail when you render. To really check a file, render it (`d2 f.d2 out.svg`).
- **Hex colors must be quoted:** `fill: #ff0000` is parsed as a comment, which gives `missing value after colon`. Write `fill: "#ff0000"`.
- **`#` in unquoted URLs** (`link`, `icon`) truncates the value with no error.
- **`text-transform: title` is rejected.** The docs list it, but the compiler only accepts `uppercase | lowercase | capitalize | none`.
- `3d` works only on rectangle/square/hexagon. `double-border` works only on rectangle/square/circle/oval.
- Ranges: `opacity` 0-1, `stroke-width` 0-15, `stroke-dash` 0-10, `font-size` 8-100. `border-radius` has no practical upper limit.
- `font` accepts only `mono`.
- `width`, `height`, `near`, `top`, `left`, `tooltip`, `link`, `class`, `icon`, `label` are object attributes, not `style.*` keys.
- `near` constants only work on root-level shapes. Use `center-left`/`center-right` (not `left-center`), but `outside-left-center`/`outside-right-center`. There is no plain `center` value.
- `near: <object>`, `top`/`left`, and container `width`/`height` depend on the layout engine. Dagre rejects all three at render time, and ELK rejects `near: <object>` and `top`/`left`.
- **Class arrays use `;`**: `[a; b]`. A comma (`[a, b]`) is read as one class named `"a, b"` and fails to render. Classes apply left to right, and the object's own attributes override all of them.
- A reference to an undefined class (`x.class: nope`) is silently ignored, not reported as an error.
- Shape labels are bold by default, and bold beats italic. Set `bold: false` to make `italic: true` visible.
- On `sql_table`/`class` shapes, `fill` colors the header, `stroke` colors the body, and `font-color` colors the header text only.
- Root `style` only documents `fill`, `fill-pattern`, `stroke`, `stroke-width`, `stroke-dash`, `double-border`. Other keys at root are not rejected but are unsupported.
- The compiler also accepts shape-only keys (`fill`, `shadow`, `3d`, `multiple`) on connections without error, but they are unsupported there.
- Theme-override codes are limited to `N1-N7`, `B1-B6`, `AA2`, `AA4`, `AA5`, `AB4`, `AB5`, and their values cannot be gradients.
- No dark theme is applied unless you set `--dark-theme` or `dark-theme-id`. Theme ID 2 does not exist.
- Special themes (Terminal etc.) change caps, fill-pattern, border radius and double-border. Undo them per object with `text-transform: none`, `fill-pattern: none`, `double-border: false`.
- `animated` and interactive tooltips/links only work in SVG. PNG/PDF exports turn tooltips/links into a numbered appendix.
- Tooltips do not render markdown.
- An escaped `\#` in an unquoted URL works: `link: https://x.com/p\#frag`.
- With `stroke` used as a diagram frame, add padding or the frame will be clipped.
