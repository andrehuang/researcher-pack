# Wiki — Claude Code Quick Start

This file tells Claude Code how to operate the wiki from any machine. The root `CLAUDE.md` has your project context; this file is the wiki-specific protocol.

## First Steps

1. Read `wiki/wiki.schema.md` — it defines page types, structure, and all operations
2. Read `wiki/index.md` — the content catalog
3. Follow `~/.claude/principles/academic-writing.md` (or `principles/academic-writing.md` from researcher-pack, or the copy installed by academic-writing-agents — any of these is fine, the file is byte-identical across both projects) for prose quality

## Wiki Operations (Summary)

### Ingest a Source
1. Place the source document in `wiki/sources/papers/` (or `wiki/sources/notes/`)
2. Identify which topic page(s) in `wiki/topics/` the source belongs to
3. Update those topic pages — add the source under "Key Papers & Approaches" with contributions and limitations
4. Create/update concept pages in `wiki/concepts/` for cross-cutting ideas (only if they span multiple topics)
5. Update group pages in `wiki/groups/` if a notable lab is involved
6. Add `[[wikilinks]]` between new and existing pages
7. Append to `wiki/log.md`
8. Update `wiki/index.md`

### Save a Research Evaluation
The canonical writer for research-evaluation pages is the `/research-companion` skill —
it produces the verdict and dimension scores in Phase 3 and hands them to the wiki.
When invoked, the skill (or a human following its output) should:
1. Write the page at `wiki/research-evaluations/YYYY-MM-DD-<topic-slug>.md` following the `research_evaluation` schema
2. Wire it into the graph — add `[[wikilinks]]` from related topic/concept pages and vice versa
3. Append an entry to `wiki/log.md` with the date, topic, and verdict
4. Update `wiki/index.md` under the `## Research Evaluations` section
5. Update `state.yaml` (research state) with the verdict and revisit conditions so `/research-session` can surface it

### Query the Wiki
1. Read `wiki/index.md` to find relevant pages
2. Read and synthesize across pages
3. Offer to promote valuable answers to `wiki/queries/`

### Lint
Run health checks: orphan pages, stale `last_reviewed` dates, index consistency, missing coverage.

## Page Types & Limits

| Type | Directory | Word Limit | Purpose |
|------|-----------|------------|---------|
| Topic | `topics/` | 800 | Subfield surveys weaving 5-15 sources |
| Concept | `concepts/` | 500 | Cross-cutting methodological ideas |
| Group | `groups/` | 400 | Research lab / actor profiles |
| Synthesis | `syntheses/` | 800 | Cross-topic analyses |
| Query | `queries/` | 600 | Promoted query results |
| Research Evaluation | `research-evaluations/` | 600 | Point-in-time research-direction verdicts from `/research-companion` |

## Cross-Machine Sync

When working from a different machine, the wiki is just files — sync it however you sync the rest of your repo (git push/pull, rsync, Dropbox, etc.). A typical git flow:

```
git pull origin main
# ... do wiki work
git add wiki/
git commit -m "wiki: ingest [source name]"
git push origin main
```

If you have the Researcher Pack's auto-commit hook enabled (`.claude/autocommit.enabled`), this happens automatically after a short quiet period.

## Key Conventions

- All pages use YAML frontmatter + `[[wikilinks]]` (Obsidian-compatible — open `wiki/` as a vault for graph exploration)
- Filenames: kebab-case, no dates (e.g., `variance-compression.md`)
- Individual papers are NOT standalone pages — they live in topic pages
- Every page must have at least one incoming `[[wikilink]]` (no orphans)
- Append every operation to `wiki/log.md` with date and description
