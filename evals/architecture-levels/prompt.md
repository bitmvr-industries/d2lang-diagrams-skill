---
tags: [d2, architecture, design]
max_turns: 50
timeout_seconds: 1200
allowed_tools: [Read, Write, Edit, Glob, Grep, Skill, Bash]
---
We need architecture diagrams in D2 for our order platform, "Parcel". They have to work for leadership (the big picture) and for engineers (what runs where and how the parts talk). Put everything in arch.d2 and render PNGs with the output path arch.png.

How Parcel works:
- Customers order through a React web app and an iOS app. Support staff use an internal back-office web app.
- All clients call an API gateway, which routes to an Order service and an Inventory service (both Go, on AWS ECS inside a VPC).
- The Order service stores orders in Postgres (RDS) and caches carts in Redis (ElastiCache). Inventory has its own Postgres database.
- When an order is placed, the Order service publishes an event to an SQS queue. A Notification worker consumes it and sends email through SendGrid.
- Payments go from the Order service to Stripe.
- Single sign-on for support staff is handled by Okta.
