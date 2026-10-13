---
type: llm
focus: { source: file, path: arch.d2 }
---
Judge the D2 source. Pass only if all of these hold:
- The diagram is split into at least two levels of detail on separate boards (layers, scenarios or steps), not one diagram that mixes everything.
- The big-picture board shows Parcel as a single system box together with the people (customers, support staff) and the external systems (Stripe, SendGrid, Okta). It does NOT show internal parts such as the gateway, services, databases, cache or queue.
- A more detailed board shows the internal parts (clients, gateway, services, databases, cache, queue, worker) and how they connect.
- The boards are linked so a reader can navigate from the big-picture system box to the detailed board (a `link:` to the other board).
