---
type: llm
focus: { source: file, path: arch.d2 }
---
Judge the D2 source. Ignore entries inside `vars` (legend samples). Pass only if all of these hold:
- Every connection on every board has a label saying what flows or why (e.g. "places orders", "publishes OrderPlaced"). Unlabeled connections are a failure.
- On the detailed board, every connection between two software elements (apps, gateway, services, workers, data stores, queues, external systems) also names the protocol or technology (e.g. HTTPS/JSON, SQL, SQS, SMTP/API). A person-to-app connection needs only an intent label such as "uses".
- Connection direction follows the request or data flow (caller -> callee, publisher -> queue -> consumer).
