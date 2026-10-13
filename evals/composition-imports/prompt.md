---
tags: [d2, imports, globs, steps, scenarios, vars]
max_turns: 50
timeout_seconds: 1200
allowed_tools: [Read, Write, Edit, Glob, Grep, Skill, Bash]
---
Write two D2 files:
- shared.d2 defines classes "service" and "store" and a vars block with a "team" variable.
- main.d2 imports shared.d2, uses both classes, and interpolates the team variable in the title label.

main.d2 also:
- uses a glob to make every connection on every board animated, and a glob to make every shape whose key ends in "-db" a cylinder;
- has 3 steps showing a deployment rollout (step 2 adds an "api-v2" node, step 3 removes the original "api" node), plus a "failure" scenario where orders-db is filled red without redeclaring it;
- has a multi-line markdown label containing a code block on one node;
- has a legend;
- places the title at the top center.

Render the deliverable as a PDF: main.pdf.
