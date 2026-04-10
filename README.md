# Researcher Pack

A Claude Code-based research loop that keeps reading, practice, ideation, experiments, and writing connected — so nothing leaks between activities.

> **Most people's experience of LLM-augmented research looks like a bag of disconnected tools.** A chatbot for brainstorming. A summarizer for papers. An autocomplete for writing. Each tool is individually impressive. Nothing compounds. The Researcher Pack is the opposite: one integrated loop where each activity's output automatically becomes structured input to the next, and where an LLM agent maintains all the handoffs for you.

The pattern is described at a higher level in the companion idea file: **[docs/PATTERN.md](./docs/PATTERN.md)**. This repo is the reference implementation.

---

## What you get

- **5 skills** that Claude Code invokes with slash commands — each chains multiple tools into a single workflow (`/research-session`, `/paper-read`, `/research-companion`, `/weekly-review`, `/orchestrate`)
- **2 agents** that specialize on their own context (`idea-critic`, `research-strategist`)
- **2 principles files** the skills and agents load for prose quality and strategic judgment (`academic-writing.md`, `research-strategy.md`)
- **2 hooks** that run automatically on every file write: a bookkeeping daemon that updates shared state + an optional debounced auto-commit
- **A shared-state file** (`.claude/research-state.yaml`) and an **append-only event log** (`events.jsonl`) that all the skills read and write
- **A wiki scaffold** — minimal knowledge-base conventions (topic/concept/group/synthesis/query pages, YAML frontmatter, `[[wikilinks]]`, Obsidian-compatible)
- **An `init` wizard** that sets all of this up in a fresh repo with a few prompts

## The three layers

The pack has three layers that work together. You can use any subset.

1. **Tools** — skills and agents, one per activity. Each is independently useful. Reuse the ones you like; ignore the ones you don't.
2. **Shared state** — plain-text files (`research-state.yaml`, `events.jsonl`, `wiki/`) that all tools read and write. This is the bus.
3. **Bookkeeping daemon** — a PostToolUse hook that runs on every file write, emits events, updates state, and (optionally) batches commits. This is what closes the loop without you having to remember.

No servers, no database beyond files. Everything is inspectable in a text editor and diffable in git.

---

## Install

```bash
# 1. Clone this repo somewhere stable
git clone https://github.com/andrehuang/researcher-pack.git ~/researcher-pack

# 2. From inside the repo you want to use for research:
cd /path/to/your/research/repo
~/researcher-pack/setup.sh init
```

The wizard asks you:
- Target repo root (default: current directory)
- A one-line research domain descriptor
- Where to put the wiki (default: `./wiki`)
- Whether to enable Mental Gym integration (optional)
- Whether to enable auto-commit (opt-in)

Then it:
- Copies `hooks/research_hook.sh` + `hooks/auto_commit.sh` into `.claude/hooks/`
- Writes a seeded `.claude/research-state.yaml` and `events.jsonl`
- Creates a minimal wiki with `wiki.schema.md`, `index.md`, `log.md`, and empty topic/concept/group/synthesis/query folders
- Symlinks `skills/*` into `~/.claude/skills/` (so updates via `git pull` are picked up automatically)
- Copies `agents/*` into `~/.claude/agents/`
- Copies `principles/*` into `~/.claude/principles/`
- Writes a `.claude/settings.local.json` with the hook registered

After pulling updates, run `~/researcher-pack/setup.sh link` (or just `~/researcher-pack/setup.sh`) to re-link skills without touching your repo's state files.

## Quickstart

Once `init` finishes, open Claude Code in your research repo and run:

```
/research-session
```

You'll see a briefing: what's due, what's stale, what happened since last time, what to prioritize. If you have no content yet, it'll suggest ingesting a paper with `/paper-read <path>`.

## Skills reference

| Skill | What it does |
|---|---|
| `/research-session` | Reads the shared state, presents a briefing, proposes an agenda, chains to sub-skills. The front door. |
| `/paper-read` | 5-phase paper workflow: Load → Analyze → Discuss → Ingest → Follow-up. Grounds discussion in existing wiki context; updates the wiki on ingestion. |
| `/research-companion` | 6-phase ideation loop: Seed → Diverge → Evaluate → Deepen → Frame → Decide. Invokes the `idea-critic` agent for adversarial pressure. |
| `/weekly-review` | Generates a digest from `events.jsonl` and the state file: activity, knowledge growth, drift, priorities. Not a productivity report — a navigation aid. |
| `/orchestrate` | Meta-skill that runs multi-stage pipelines (e.g., paper → review → draft). Useful when a single request should fan out to several skills in sequence. |

## Agents reference

| Agent | Role |
|---|---|
| `idea-critic` | Adversarial evaluator. Stress-tests research ideas along seven dimensions (novelty, impact, timing, feasibility, competitive landscape, nugget, narrative) and returns Pursue/Refine/Kill. |
| `research-strategist` | Project-level triage: continue/pivot/kill decisions, comparative advantage, impact forecasting, opportunity cost, scooping risk. |

## File layout after `init`

In your research repo:

```
<your-repo>/
├── .claude/
│   ├── hooks/
│   │   ├── research_hook.sh        # runs on every Write/Edit
│   │   └── auto_commit.sh          # opt-in, debounced
│   ├── research-state.yaml         # shared state (gym, wiki, session info)
│   ├── settings.local.json         # hook registration + permissions
│   └── autocommit.enabled          # marker file (if you opted in)
├── wiki/
│   ├── wiki.schema.md              # conventions
│   ├── CLAUDE.md                   # wiki-specific protocol
│   ├── index.md                    # content catalog
│   ├── log.md                      # append-only operation log
│   ├── topics/
│   ├── concepts/
│   ├── groups/
│   ├── syntheses/
│   ├── queries/
│   └── sources/                    # raw papers/notes — immutable
└── events.jsonl                    # append-only event log
```

User-level (set up once per machine by `setup.sh link`):

```
~/.claude/
├── skills/research-session     -> ~/researcher-pack/skills/research-session
├── skills/paper-read           -> ~/researcher-pack/skills/paper-read
├── skills/research-companion   -> ~/researcher-pack/skills/research-companion
├── skills/weekly-review        -> ~/researcher-pack/skills/weekly-review
├── skills/orchestrate          -> ~/researcher-pack/skills/orchestrate
├── agents/idea-critic.md
├── agents/research-strategist.md
└── principles/
    ├── academic-writing.md
    └── research-strategy.md
```

## Mental Gym integration

The pack works without it, but is better with [Mental Gym](https://github.com/andrehuang/mental-gym) — a companion CLI for deliberate practice where you produce knowledge from memory and the AI evaluates gaps. The `research-session` briefing will surface topics that are due for review; `paper-read` will suggest practicing the key claims after ingestion.

To enable: install Mental Gym, then re-run `setup.sh init` (or manually set `paths.mental_gym` in `research-state.yaml`).

## Auto-commit

Off by default. To enable: set `RESEARCHER_PACK_AUTOCOMMIT=1` or `touch .claude/autocommit.enabled`. Once enabled, `auto_commit.sh` batches all wiki/state/event changes in a single commit after a 30-second quiet period, then pushes to `origin main`.

The design goal is: you write, the pack keeps the repo up to date, nothing piles up in your working tree. If you don't want this, leave it off — everything else still works.

## Customization

- **Add a skill**: drop a directory under `skills/<name>/` with a `SKILL.md`. Re-run `setup.sh link`.
- **Add an agent**: drop a markdown file under `agents/`. Re-run `setup.sh link`.
- **Change state schema**: edit `templates/research-state.yaml.template` (for future `init` runs) or `.claude/research-state.yaml` directly (for an existing repo).
- **Change hook behavior**: `hooks/research_hook.sh` is a readable shell script. Fork it.

## Philosophy

- **Tools over monoliths.** Every piece is independently useful. The pack is an integration layer, not a framework.
- **Files as API.** No servers, no databases beyond plain text. If git can version it, the pack can use it.
- **Bookkeeping is for machines.** Humans abandon knowledge bases because maintaining cross-references is boring. LLMs don't get bored.
- **The loop over the tool.** Individual LLM-research tools are commodity. What's not commodity is the integration — and the integration is where research identity lives.

## License

MIT — see [LICENSE](./LICENSE).

## See also

- **[docs/PATTERN.md](./docs/PATTERN.md)** — the Researcher Pack pattern at a higher level of abstraction (intended to be handed to any LLM agent that wants to build its own version)
- **[docs/architecture.md](./docs/architecture.md)** — implementation walkthrough of the three layers in this repo
- **[Mental Gym](https://github.com/andrehuang/mental-gym)** — the deliberate-practice companion
