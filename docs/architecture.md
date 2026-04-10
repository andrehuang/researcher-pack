# Architecture

The Researcher Pack has three layers. This document walks through each one in enough detail to read the source.

For the pattern-level motivation (why integrate research activities at all?), see **[PATTERN.md](./PATTERN.md)**.

## Layer 1 — Tools

Each skill lives at `skills/<name>/SKILL.md`. Claude Code reads these when you type `/<name>`. A skill is a structured prompt that tells the agent which files to read, which phases to run, and how to report progress.

Each skill is designed to be useful on its own. You could delete `research-companion/` and the rest would still work. Coupling between skills is indirect — they communicate through shared state, not through function calls.

Agents (under `agents/`) are a different primitive. Claude Code spawns them as sub-agents with a fresh context window and a narrow role (`idea-critic`, `research-strategist`). Skills delegate to agents for tasks that benefit from isolated context or adversarial framing.

## Layer 2 — Shared state

Three plain-text files form the bus:

| File | Format | Purpose |
|---|---|---|
| `.claude/research-state.yaml` | YAML | Snapshot of current state: gym stats, wiki counts, last session, suggested actions, path configuration |
| `events.jsonl` | JSON Lines, append-only | Chronological log of every research action (wiki updates, ingests, writing edits, gym sessions) |
| `wiki/` | Markdown with YAML frontmatter + `[[wikilinks]]` | The knowledge base itself — topics, concepts, groups, syntheses, queries, raw sources |

At session start, the `research-session` skill reads all three. During a session, skills update the state file as a side effect of their work. The append-only event log lets the `weekly-review` skill reconstruct activity over arbitrary time ranges.

The `paths:` block at the top of `research-state.yaml` is the only place that resolves physical locations — everything else uses relative references the agent resolves on read.

## Layer 3 — Bookkeeping daemon

Two shell scripts in `hooks/`:

- **`research_hook.sh`** — registered as a Claude Code `PostToolUse` hook on `Write|Edit`. Runs after every file write. Dispatches on the modified file's path: wiki edits emit `wiki:update` events and update the state timestamp; draft edits emit `writing:edit` and suggest `/academic review`; IDEAS.md edits emit `ideas:update`; experiment result files emit `experiment:update`. It degrades gracefully if Mental Gym isn't installed.

- **`auto_commit.sh`** — called by `research_hook.sh` for commit-worthy changes. Uses a pending-file debounce pattern: each call timestamps the change; a background process waits for a 30-second quiet period before committing everything at once. Categorizes commit messages (`wiki: update X`, `research: update Y`). Opt-in via `RESEARCHER_PACK_AUTOCOMMIT=1` or a `.claude/autocommit.enabled` marker file.

These two scripts close the loop without the human having to remember. The alternative — "maintain a tidy knowledge base by sheer discipline" — is exactly the thing humans fail at.

## Data flow, end to end

Here's what happens when you run `/paper-read path/to/paper.pdf`:

1. `paper-read` skill loads `wiki/index.md` and `research-state.yaml` to know what already exists.
2. Phase 1–3 analyze and discuss the paper, with the agent grounding its response in relevant wiki pages.
3. Phase 4 ingests: the agent edits `wiki/topics/*.md`, `wiki/concepts/*.md`, `wiki/log.md`, `wiki/index.md`.
4. Each edit triggers `research_hook.sh`, which appends a `wiki:update` event to `events.jsonl`, bumps `last_updated` in `research-state.yaml`, and prints a mental-gym suggestion.
5. After a 30s quiet period, `auto_commit.sh` bundles all the changes into one commit and pushes.
6. Phase 5 offers follow-ups — most commonly `mental-gym train --focus <topic>` to test retention against what was just ingested.

At no point did you write a commit message, update an index by hand, or maintain cross-references. That's all in Layer 3.

## Extending

**New activity**: write a new skill under `skills/<name>/SKILL.md`. If it reads/writes files, the hook will auto-log its events. If it needs a specialized sub-agent, add it under `agents/`.

**New file type for the hook to recognize**: add a `case` clause to `research_hook.sh`. The existing dispatch is organized top-to-bottom by specificity — wiki pages first, then experiment results, then drafts, then fallbacks.

**New path convention**: edit the `paths:` block in `templates/research-state.yaml.template` and the skills that read it. Skills are forgiving — they default to standard locations if a path is missing.

The pattern is portable across implementations because the contract is just "read and write these plain-text files." You can swap any one tool for a better one as long as the new one honors the state contract.
