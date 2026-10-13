---
type: llm
focus: { source: file, path: arch.d2 }
---
Judge the D2 source. Pass only if all of these hold:
- Element types have a consistent visual style defined once and reused, through D2 `classes` (e.g. person, service/container, database, queue, external system). Repeating ad-hoc inline `style` blocks per node instead of classes is a failure.
- External systems (Stripe, SendGrid, Okta) are styled distinctly from Parcel's own parts.
- Databases are cylinders and the SQS queue uses the `queue` shape.
- People (customers, support staff) use the `person` (or `c4-person`) shape.
