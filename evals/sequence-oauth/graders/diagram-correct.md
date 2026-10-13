---
type: llm
focus: { source: file, path: oauth/index.png }
---
The image is the main board of a rendered sequence diagram. Pass only if all of these hold:
- Exactly four actor lifelines: Browser, App Server, Auth Server, Resource API. No actor appears twice, and the "token exchange" group is NOT drawn as its own actor or lifeline.
- A labeled "token exchange" group box spans a token request and its response.
- A note is attached to Auth Server's lifeline.
- App Server has a self-message labeled "validate state".
- Activation spans (narrow boxes on the lifeline) are visible on App Server.
- At least one return message is dashed.
