---
tags: [d2, sequence, layers]
max_turns: 40
timeout_seconds: 900
allowed_tools: [Read, Write, Edit, Glob, Grep, Skill, Bash]
---
Write oauth.d2: an OAuth2 authorization-code sequence diagram with actors Browser, App Server, Auth Server and Resource API. Include a group named "token exchange" spanning the token request and response, a note on Auth Server, a self-message on App Server ("validate state"), activation spans showing when App Server is busy, and dashed return arrows.

Also add a second board (a layer named "components") showing the same 4 actors as a plain component diagram, and link the Auth Server in the main diagram to that layer.

Render PNGs of both boards with the output path oauth.png.
