# Changelog

## 0.1.0 - 2026-10-13

- Initial skill: `SKILL.md` workflow (render-and-look verification, output safety, reserved keywords, silent failures) and seven reference files distilled from the D2 tour docs.
- 179 reference snippets verified with d2 v0.9.0 (`scripts/check-snippets.sh`).
- 11 CLI behaviors verified (`scripts/check-behaviors.sh`).
- Eval suite: 7 cases from the original baseline and with-skill tests.
- Baseline eval (Claude Code, 2 runs per arm): with skill 7/7 cases at 1.00; without skill 6/7. Only `output-trap` differs (1.00 vs 0.50): without the skill the agent renders onto `docs.svg` and deletes the existing `docs/` folder. With `d2` available, agents fix syntax errors by re-rendering, so the other cases pass in both arms and serve as regression guards.
