---
tags: [d2, architecture, config]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Write, Edit, Glob, Grep, Skill, Bash]
---
Create a D2 architecture diagram of a web app and save the source as arch.d2, rendered to arch.png.

A "Users" person shape connects to a CDN. The CDN connects to a load balancer inside an "AWS" container, which also holds a "VPC" container with two API servers (drawn as a group of 2), a Postgres database (cylinder) and a Redis cache. The API servers read from and write to the DB and the cache, with labeled connections. Use a dark theme, make the DB fill light blue, add a Stripe icon for an external payments service the API calls, a markdown text note explaining the setup, and a tooltip on the load balancer. Use the ELK layout engine with direction right. Set the theme and layout engine inside the file, not as CLI flags.
