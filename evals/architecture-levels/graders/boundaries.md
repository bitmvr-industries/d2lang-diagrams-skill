---
type: llm
focus: { source: file, path: arch.d2 }
---
Judge the D2 source. Pass only if all of these hold:
- The detailed board shows a deployment or trust boundary as a container (e.g. "AWS" and/or "VPC") holding Parcel's services and data stores.
- External systems (Stripe, SendGrid, Okta) and the user-facing clients/people are outside that boundary.
