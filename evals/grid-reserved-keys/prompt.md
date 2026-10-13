---
tags: [d2, grid, keywords, quoting]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Write, Edit, Glob, Grep, Skill, Bash]
---
Build a D2 status board in board.d2 and render it to both board.svg and board.png.
- A grid with 3 columns and 2 rows, cells filled in reading order. The cells use exactly these keys: top, left, label (first row), then status, near, queue (second row).
- The "status" cell contains a nested 2-row grid with cells "up" and "down".
- The "queue" cell's label is exactly: C# Worker; handles $5 invoices
- A connection from "left" to "queue".
- A "card" class with a shadow and a fill colour, applied to 4 cells through a class array that also includes a second class "bold-text".
- The "label" cell links to https://example.com/docs#setup
