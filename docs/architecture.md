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

The wiki carries one page type that deserves a separate mention: `research_evaluation`. A `research-evaluation` page is what `/research-companion` writes at the end of its Decide phase — a dated record of the idea it considered, the alternatives it killed, the stress tests it survived, the final verdict (PURSUE / PARK / KILL), and the revisit conditions if it was parked. These pages compose with the rest of the substrate in four ways. The wiki linter treats them as first-class (missing frontmatter fails the same lint checks). The index page lists them alongside topics and concepts. The `weekly-review` skill scans them to produce the "decisions you made this week" section of the digest. The `research_hook.sh` dispatcher recognizes edits under `wiki/research-evaluations/` and emits a dedicated event, so the history of every decision is recoverable from the event log alone.

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

## The optional-companion contract

researcher-pack has one companion plugin it knows about by name: **academic-writing-agents**. The contract is detection at link time and silent skip at runtime. `setup.sh link` does not fail if the companion isn't installed; it just links the pack's own skills and agents. Skill prompts that reference `/academic review`, `/academic draft`, `paper-crawler`, or `research-analyst` are written so that those references degrade gracefully — when the referenced command doesn't exist, the skill notes the absence and continues with the pack-local tools (`research-strategist` for DEEPEN, the wiki substrate for FRAME). There is no feature detection beyond "did the command resolve" — no version pinning, no capability negotiation. Install the companion to upgrade; uninstall it and every skill keeps running.

### The visual dashboard

The pack intentionally ships no dashboard of its own. The wiki is plain markdown, so the right dashboard is a markdown viewer you already trust — and the recommended viewer is Obsidian. Because Obsidian vaults are just folders with an `.obsidian/` directory for config, we ship a starter at `templates/wiki/.obsidian/` that `setup.sh init` drops into your new wiki during scaffolding. It's a project-template artifact, not a user-level one: it lives inside each research repo's wiki directory (not `~/.claude/`), so every research project can customize it independently without touching a global config. That means a user with three research repos gets three `.obsidian/` directories, each freely forkable.

The pattern is portable across implementations because the contract is just "read and write these plain-text files." You can swap any one tool for a better one as long as the new one honors the state contract.

## README philosophy

The README for this repo is deliberately narrative rather than reference. It opens with a hook paragraph, walks through the loop as a single command (`/research-session`), shows the loop and components as two Mermaid figures rather than tables, tells a Monday-through-Friday vignette, and only then drops into per-component specifics. The rationale: a research environment that exposes only reference documentation forces the user to re-learn it each time they return. A narrative they can scan in under two minutes on a Monday morning is what keeps the loop actually running. The architecture document you're reading now is the reference side of the same split — it exists so that when the README's narrative leaves out a detail, there is exactly one other place to look. Two figures, one narrative, one reference. Single-file per side.
