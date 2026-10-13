# Architecture diagrams in D2

How to structure a system or architecture diagram so it works for both a big-picture reader and an engineer, and how to express that in D2. Verified on d2 v0.9.0.

## Contents

1. [The deliverable](#1-the-deliverable)
2. [Boards: one level of detail each](#2-boards-one-level-of-detail-each)
3. [Element vocabulary: classes](#3-element-vocabulary-classes)
4. [Connections](#4-connections)
5. [Boundaries](#5-boundaries)
6. [Legend on every board](#6-legend-on-every-board)
7. [Worked example](#7-worked-example)
8. [Review checklist](#8-review-checklist)
9. [Larger systems](#9-larger-systems)
10. [Gotchas](#10-gotchas)

## 1. The deliverable

An architecture diagram set is:

1. A **context board** (the root): the system as one box, the people who use it, and the external systems it depends on.
2. A **container board** (a layer): what runs inside the system (apps, services, data stores, queues), where it runs, and how the parts talk.
3. Optionally, one **component board** per container that needs it.

Plus, on every board: classes for every element type, a label on every connection, a legend, and navigation links between the boards.

## 2. Boards: one level of detail each

| Board | Shows | Hides |
|---|---|---|
| Context (root) | people, the system as a single box, external systems | gateways, services, databases, caches, queues |
| Container (`layers.containers`) | client apps, services, data stores, queues, workers, the deployment boundary, external systems | classes, functions, internal modules |
| Component (`layers.containers.layers.<name>`) | modules inside one container | everything else |

Navigation:

- The system box on the context board links down: `billing: {link: layers.containers}`.
- Each detail board links back up with a text shape: `back: "Back to context" {shape: text; near: top-left; link: _}`.
- Title each board with `label:` inside the block. That label becomes the footnote text for links in PNG/PDF.

## 3. Element vocabulary: classes

Define one class per element type at the root, then give every node a class. Classes carry into layers, so define them once. Boundaries and connection types get classes too: no inline `style` on individual nodes.

| Element | Class (example) | Shape / style |
|---|---|---|
| Person | `person` | `shape: person` |
| Your system (context board) | `system` | solid, strong fill |
| Client app (web, mobile, back-office) | `app` | rectangle |
| Service / worker | `service` | rectangle |
| Database / cache / bucket | `store` | `shape: cylinder` |
| Queue / topic / stream | `queue` | `shape: queue` |
| External system | `external` | grey fill, `stroke-dash` |
| Deployment or trust boundary | `boundary` | `fill: transparent`, dashed stroke |
| Async connection | `async` | `stroke-dash: 3` |

Put the technology in the node label on a second line: `api: Billing API\n(Kotlin, Cloud Run)`.

## 4. Connections

Every connection on every board has a label:

| Board | Label form | Examples |
|---|---|---|
| Context | intent only | `"issues invoices"`, `"collects payments"` |
| Container | `"<intent> [<protocol>]"` | `"read/write invoices [SQL]"`, `"publish PaymentRequested [Pub/Sub]"`, `"send email [HTTPS API]"` |
| Person to app | `"uses"` | `customer -> portal: "uses"` |

- Point arrows the way the request or data flows: caller → callee, publisher → queue → consumer.
- Mark asynchronous hops with the `async` class.
- Quote labels; protocols often contain `/`, `#` or `;`.

## 5. Boundaries

On the container board, draw the deployment or trust boundary (cloud account, VPC, cluster) as a container with `class: boundary`, holding the system's services and data stores. People, client apps and external systems sit outside it. Nest a second boundary (e.g. VPC inside AWS) only when it changes what can reach what.

## 6. Legend on every board

A legend renders only on the board that declares it, but board-level `vars` can spread a root var. Define the entries once in `vars`, then spread them into each board's `d2-legend`. Legend entries take `class:`, so the legend always matches the diagram. Hide the endpoints of legend connections with `opacity: 0`.

```d2
classes: {
  service: {style.fill: "#FFF3E0"}
  async: {style.stroke-dash: 3}
}
vars: {
  key: {
    c: Our service {class: service}
    a -> b: "sync call [protocol]"
    e -> f: "async message" {class: async}
    a.style.opacity: 0
    b.style.opacity: 0
    e.style.opacity: 0
    f.style.opacity: 0
  }
  d2-legend: {...${key}}
}
api: API {class: service}
layers: {
  detail: {
    vars: {d2-legend: {...${key}}}
    worker: Worker {class: service}
  }
}
```

## 7. Worked example

Context board plus container board, with every rule above applied. Rendered with `d2 billing.d2 out.png`, it produces `out/index.png` (context) and `out/containers.png`.

```d2
vars: {
  d2-config: {
    layout-engine: elk
  }
  # Legend defined once, spread into every board.
  key: {
    p: Person {class: person}
    s: Our system {class: system}
    ap: Client app {class: app}
    c: Our service {class: service}
    d: Data store {class: store}
    q: Queue {class: queue}
    x: External system {class: external}
    a -> b: "sync call [protocol]"
    e -> f: "async message" {class: async}
    a.style.opacity: 0
    b.style.opacity: 0
    e.style.opacity: 0
    f.style.opacity: 0
  }
  d2-legend: {...${key}}
}

classes: {
  person: {shape: person; style.fill: "#E3F2FD"; style.stroke: "#1565C0"}
  system: {style.fill: "#1565C0"; style.font-color: "#FFFFFF"; style.bold: true}
  app: {style.fill: "#E8F5E9"; style.stroke: "#2E7D32"}
  service: {style.fill: "#FFF3E0"; style.stroke: "#E65100"}
  store: {shape: cylinder; style.fill: "#EDE7F6"; style.stroke: "#4527A0"}
  queue: {shape: queue; style.fill: "#FCE4EC"; style.stroke: "#AD1457"}
  external: {style.fill: "#F5F5F5"; style.stroke: "#757575"; style.stroke-dash: 4}
  boundary: {style.fill: "transparent"; style.stroke: "#546E7A"; style.stroke-dash: 5}
  async: {style.stroke-dash: 3}
}

direction: right

# Context board (root): the system as one box, its people and external systems.
title: "Billing platform: context" {shape: text; near: top-center; style.font-size: 24}
finance: Finance team {class: person}
customer: Customer {class: person}
billing: Billing platform {
  class: system
  link: layers.containers
}
bank: Bank (ACH) {class: external}
mail: Postmark {class: external}

finance -> billing: "issues invoices"
customer -> billing: "views and pays invoices"
billing -> bank: "collects payments"
billing -> mail: "sends invoice emails"

layers: {
  # Container board: what runs where and how the parts talk.
  containers: {
    # Title the board with label:, not "containers: Container view {" (that drops inherited classes).
    label: Container view
    # Boards do not inherit direction; set it again.
    direction: right
    vars: {d2-legend: {...${key}}}
    title: "Billing platform: containers" {shape: text; near: top-center; style.font-size: 24}
    back: "Back to context" {shape: text; near: top-left; link: _}

    finance: Finance team {class: person}
    customer: Customer {class: person}
    portal: Customer portal\n(Next.js) {class: app}
    admin: Admin console\n(React) {class: app}

    gcp: GCP project {
      class: boundary
      api: Billing API\n(Kotlin, Cloud Run) {class: service}
      worker: Payment worker\n(Kotlin) {class: service}
      db: Billing DB\n(Cloud SQL Postgres) {class: store}
      jobs: payment-jobs\n(Pub/Sub) {class: queue}
    }

    bank: Bank (ACH) {class: external}
    mail: Postmark {class: external}

    finance -> admin: "uses"
    customer -> portal: "uses"
    admin -> gcp.api: "manage invoices [HTTPS/JSON]"
    portal -> gcp.api: "view and pay [HTTPS/JSON]"
    gcp.api -> gcp.db: "read/write invoices [SQL]"
    gcp.api -> gcp.jobs: "publish PaymentRequested [Pub/Sub]" {class: async}
    gcp.jobs -> gcp.worker: "deliver job [Pub/Sub push]" {class: async}
    gcp.worker -> bank: "submit ACH debit [SFTP/NACHA]"
    gcp.worker -> gcp.db: "record result [SQL]"
    gcp.api -> mail: "send invoice email [HTTPS API]"
  }
}
```

## 8. Review checklist

Check each rendered board's PNG:

- Context board: the system is one box; no internal parts are visible.
- Container board: every person, app, service, store, queue and external system from the request is present exactly once.
- Every connection has a label; container-board labels name a protocol.
- Shapes and colours match the legend; nothing is unstyled (unstyled nodes on a layer usually mean the shorthand-label bug in Gotchas).
- External systems and people sit outside the boundary; services and stores sit inside.
- Each detail board has a link back up, and the system box links down (numbered badge + footnote in PNG).

## 9. Larger systems

- Keep each board to roughly 15 nodes. Past that, add a component board for the busiest container instead of growing the container board.
- When several diagrams must show the same system, keep the model in one file and build views by importing it. See the model-view recipe in `composition.md`.

## 10. Gotchas

- **A board titled in shorthand loses inherited classes.** `layers: {containers: Container view {...}}` renders every node unstyled, with no error. Use `containers: {label: Container view ...}`.
- **Boards don't inherit `direction`.** Set it again inside each layer, or the layer falls back to top-down.
- **A legend renders only on the board that declares it.** Spread a shared var into each board's `vars.d2-legend`, as in section 6.
- A `tooltip` and a `link` on the same shape show two numbered badges in PNG/PDF output. Use only `link` on the system box.
