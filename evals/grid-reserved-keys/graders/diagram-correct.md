---
type: llm
focus: { source: file, path: board.png }
---
The image is a rendered grid. Pass only if all of these hold:
- Six cells in a 3x2 grid. Reading left to right, the first row is top, left, label and the second row is status, near, queue.
- The status cell contains two stacked cells, "up" above "down".
- The queue cell reads exactly "C# Worker; handles $5 invoices".
- One connection goes from the left cell to the queue cell.
- Four cells share a fill colour and a drop shadow.
- No extra or empty cells.
