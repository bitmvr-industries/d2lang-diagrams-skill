---
tags: [d2, layers, links, sequence]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Write, Edit, Glob, Grep, Skill, Bash]
---
Write checkout.d2 and render it as an SVG bundle with output path checkout.svg.
- The root board is a component overview: shop, payments, ledger.
- Add a layer "flow": a sequence diagram where shop calls payments and payments calls ledger, with a group "retry" holding two messages (payments -> ledger, ledger -> payments), a note on ledger, and a self-message on payments.
- Add a layer "failure": the same components, with ledger styled red.
- Inside the "flow" layer, the ledger actor links to the sibling "failure" layer. On the root board, payments links to the "flow" layer.
- Use the ELK layout engine and theme 3, set inside the file.
