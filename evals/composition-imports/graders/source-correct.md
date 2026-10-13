---
type: llm
focus: { source: file, path: main.d2 }
---
This is main.d2, a D2 file that imports a sibling shared.d2 (which defines classes "service" and "store" and a "team" var). Pass only if all of these hold:
- It imports shared.d2 (`...@shared` or `x: @shared` form) and uses classes service and store.
- The title label interpolates the team variable with `${team}` inside a double-quoted or unquoted string (not single-quoted).
- A connection glob covers every board, including steps and the scenario (for example `(*** -> ***)[*]` or `(** -> **)[*]`; a single-star `(* -> *)[*]` glob is a failure).
- A glob such as `*-db` or `**-db` sets shape: cylinder.
- Steps 2 and 3 add api-v2 and remove api with `api: null`, respectively.
- The failure scenario sets orders-db's fill without redeclaring the node.
- A markdown block (`|md` or `|||md`) contains a fenced code block, and a legend is defined (`vars.d2-legend` or equivalent).
- The title uses `near: top-center`.
