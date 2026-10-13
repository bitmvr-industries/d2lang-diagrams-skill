---
type: llm
focus: { source: file, path: arch.png }
---
The image is a rendered architecture diagram. Pass only if all of these hold:
- A person-shaped "Users" node connects to a CDN, which connects to a load balancer.
- The load balancer sits inside an "AWS" container that also contains a nested "VPC" container.
- The VPC holds API servers drawn as a stacked/multiple shape, a cylinder Postgres database with a light blue fill, and a Redis cache.
- API servers connect to the database and the cache with labeled connections.
- An external Stripe/payments node is shown with an icon or image, and the API connects to it.
- A text note explaining the setup is visible.
- The overall flow runs left to right on a dark background.
- No node appears twice and there are no stray, unlabeled or empty shapes.
