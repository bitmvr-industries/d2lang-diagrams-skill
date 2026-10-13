# d2lang-diagrams-skill

An [Agent Skill](https://agentskills.io/specification) for writing, rendering and verifying [D2](https://d2lang.com) diagrams. It works with any agent that loads `SKILL.md` skills (Claude Code, Codex, Copilot CLI, Gemini CLI, Cursor, …) and needs the `d2` CLI on `PATH`.

The skill itself is `skills/d2-diagrams/`. Everything else in this repo exists to install, test and maintain it.

## Install

Install d2 first: `brew install d2` (or see [d2lang.com/tour/install](https://d2lang.com/tour/install)).

**Claude Code** (plugin; updates with the repo):

```bash
claude plugin marketplace add git@github.com:bitmvr-industries/d2lang-diagrams-skill.git
claude plugin install d2-diagrams@d2lang-diagrams-skill
# later, to pick up new releases:
claude plugin marketplace update d2lang-diagrams-skill
```

**Other agents** (copies the skill; re-run to update):

```bash
bash scripts/install.sh                      # ~/.agents/skills (cross-agent location)
bash scripts/install.sh ~/.codex/skills      # or any agent's skills directory
```

## Layout

```
skills/d2-diagrams/        the skill: SKILL.md + references/ (agent-neutral; nothing else ships)
evals/                     eval cases: prompt.md + graders/*.md per case
scripts/check-snippets.sh  renders every d2 snippet in references/ with the installed d2
scripts/check-behaviors.sh re-verifies the CLI behaviors SKILL.md states as facts
scripts/run-evals.sh       runs the evals with and without the skill (Claude Code)
scripts/install.sh         installs the skill for non-plugin agents
tests/fixtures/            import targets used by check-snippets.sh
.claude-plugin/            Claude Code plugin + marketplace manifests
SOURCES.md                 d2 version and docs commit the skill was verified against
```

Rule: `skills/d2-diagrams/` never names a specific agent, tool or config path. Agent-specific packaging stays outside it.

## Maintaining

### When d2 is upgraded

```bash
bash scripts/check-snippets.sh   # every reference snippet still renders (or still fails, if marked INVALID)
bash scripts/check-behaviors.sh  # every CLI behavior SKILL.md relies on is unchanged
```

Fix what they report, re-run, then update `SOURCES.md`. To pull in new docs content, diff the docs repo from the commit in `SOURCES.md`.

### When the skill gets something wrong

Test first, like code:

1. **Red:** add an eval case under `evals/<name>/` that reproduces the failure. Run it and confirm it fails: `bash scripts/run-evals.sh --case <name> --runs 1`.
2. **Green:** make the smallest change to `SKILL.md` or a reference that fixes it. Add any new snippet with the behavior it demonstrates, and run `check-snippets.sh`.
3. **Regressions:** run the full suite: `bash scripts/run-evals.sh`. Compare against the last results.
4. Bump `version` in `.claude-plugin/plugin.json`, add a `CHANGELOG.md` entry, commit, push.

Every eval runs twice, with and without the skill, and reports the difference (Δ). A case where both arms pass is not testing the skill. Keep it as a regression guard, but don't add skill content for it. Content that no case needs is a candidate for removal: the smaller `SKILL.md` stays, the better it works.

Eval reports stay local (`--no-publish`) under `evals/results/`, which is git-ignored.

## License

The reference files are derived from the D2 documentation, © Terrastruct, Inc., BSD-3-Clause. See `NOTICE`.
