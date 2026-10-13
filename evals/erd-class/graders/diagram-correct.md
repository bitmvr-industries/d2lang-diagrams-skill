---
type: llm
focus: { source: file, path: erd.png }
---
The image is a rendered ERD. Pass only if all of these hold:
- Three table shapes titled users, orgs and invoices.
- The users table has four rows: id, email, org_id and a column named "label" (varchar). The table's title is still "users"; a title of "varchar" or a missing "label" row is a failure.
- Constraint markers are shown (primary key, unique, foreign key).
- Connections go from users.org_id and invoices.org_id to orgs.id, attached at the column rows.
- A UML class box InvoiceService shows a private field, a public method with a return type, and a protected method, with visibility markers.
