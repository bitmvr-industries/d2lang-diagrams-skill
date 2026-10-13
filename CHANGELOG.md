# Changelog

## 0.2.0 - 2026-10-13

- Add `references/architecture-recipes.md`: context and container boards linked together, one class per element type (including boundaries and async connections), `"<intent> [<protocol>]"` connection labels, deployment boundaries, a legend defined once and spread into every board, a worked example and a review checklist.
- `SKILL.md`: architecture and system diagrams load the recipes first; new silent failures for boards (a shorthand layer title drops inherited classes, layers don't inherit `direction`, `d2-legend` is per board).
- `check-behaviors.sh`: 3 new checks for those board behaviors (14 total).
- New eval case `architecture-levels`. Before the recipes: with skill 0.50, without 0.44. After: with skill 1.00 (3/3 runs), without 0.56.
- Eval graders: `legend` accepts any legend, `connections` exempts person-to-app "uses" labels, the grid image judge accepts display labels. Full-suite regression run with the skill: 8/8 cases at 1.00.

## 0.1.0 - 2026-10-13

- Initial skill: `SKILL.md` workflow (render-and-look verification, output safety, reserved keywords, silent failures) and seven reference files distilled from the D2 tour docs.
- 179 reference snippets verified with d2 v0.9.0 (`scripts/check-snippets.sh`).
- 11 CLI behaviors verified (`scripts/check-behaviors.sh`).
- Eval suite: 7 cases from the original baseline and with-skill tests.
- Baseline eval (Claude Code, 2 runs per arm): with skill 7/7 cases at 1.00; without skill 6/7. Only `output-trap` differs (1.00 vs 0.50): without the skill the agent renders onto `docs.svg` and deletes the existing `docs/` folder. With `d2` available, agents fix syntax errors by re-rendering, so the other cases pass in both arms and serve as regression guards.
