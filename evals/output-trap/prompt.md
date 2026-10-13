---
tags: [d2, steps, globs, output-safety]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Write, Edit, Glob, Grep, Skill, Bash]
---
Create rollout.d2: a blue/green deployment in 3 steps. Step 1 has blue live, step 2 adds green and splits traffic, step 3 removes blue. Use globs to make every connection animated across all boards. Render the deliverable SVG to docs.svg in the current folder.
