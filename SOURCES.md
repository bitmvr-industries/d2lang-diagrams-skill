# Sources

What the skill was built and verified against. Update this file whenever the skill is re-verified.

| Source | Version |
|---|---|
| d2 CLI | v0.9.0 (Homebrew) |
| D2 docs | [terrastruct/d2-docs](https://github.com/terrastruct/d2-docs) @ `5530a5ec52f8df7b8a6557a4d554c18fbfe08227` (2026-10-05), `docs/tour/` |

## Reference file → docs pages

| Reference | Docs pages (`docs/tour/`) |
|---|---|
| `basics.md` | hello-world, shapes, connections, containers, text, icons, comments |
| `special-diagrams.md` | sql-tables, uml-classes, sequence-diagrams, grid-diagrams |
| `styling.md` | themes, style, classes, dimensions, positions, sketch, interactive, fonts, legend |
| `layouts.md` | layouts, dagre, elk, tala |
| `language.md` | strings, vars, globs, overrides, models, auto-formatter |
| `composition.md` | composition, layers, scenarios, steps, linking, composition-formats, imports, imports-use-cases, model-view, modular-classes, nested-composition, version-visualization, imported-template |
| `cli.md` | install, man, exports, api, troubleshoot, faq, cheat-sheet, editor-support, vscode, vim, obsidian, extensions |

To see what changed upstream since this snapshot:

```bash
git clone https://github.com/terrastruct/d2-docs.git /tmp/d2-docs
git -C /tmp/d2-docs diff --stat 5530a5ec52f8df7b8a6557a4d554c18fbfe08227 HEAD -- docs/tour
```
