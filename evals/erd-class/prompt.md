---
tags: [d2, sql_table, class]
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Write, Edit, Glob, Grep, Skill, Bash]
---
Write erd.d2 and render it to erd.png. It is an ERD with tables users (id primary key, email unique, org_id foreign key, label varchar), orgs (id primary key, name), and invoices (id primary key, org_id foreign key, total decimal, created_at). Draw foreign-key connections from the specific columns to the referenced columns. Also include a UML class "InvoiceService" with a private field, a public method returning a value, and a protected method.
