# Wiki Schema & Conventions

This file defines how the LLM Wiki is structured and maintained. Claude Code reads this
when performing wiki operations (ingest, query, lint).

---

## Three-Layer Architecture

1. **Raw sources** (`sources/`): Immutable documents — papers, notes, clippings. Never modified after ingestion.
2. **Wiki pages** (`concepts/`, `entities/`, `syntheses/`, `queries/`): LLM-generated and maintained. The knowledge layer.
3. **This schema** (`wiki.schema.md`): Conventions and workflows. The configuration layer.

## Special Files

- **`index.md`**: Content catalog organized by type. Updated whenever pages are added/removed.
- **`log.md`**: Append-only chronological record of all wiki operations.

---

## Page Types

### Topic Page (`topics/`) — THE HEART OF THE WIKI

Thematic pages covering a subfield or major theme. Each topic page weaves together
5-15 papers in context, compares approaches, and identifies gaps. **When ingesting a
new paper, update the relevant topic page(s) rather than creating standalone entity pages.**

```yaml
---
type: topic
related_projects: [project-slug, ...]
key_papers: [Author Year, ...]
last_reviewed: YYYY-MM-DD
---
```

Structure:
1. `# Title`
2. `## Overview` — 2-3 paragraphs introducing the theme
3. `## Key Papers & Approaches` — each major paper/system described with contributions, limitations
4. `## Current State & Debates` — what's settled, what's contested
5. `## Gaps & Opportunities` — what's missing, where our work fits
6. `## Related` — `[[wikilinks]]` to other topics and concepts

### Group Page (`groups/`)

Research groups — who's building what, their trajectory, how they relate to our work.

```yaml
---
type: group
members: [names]
affiliation: institution
last_reviewed: YYYY-MM-DD
---
```

Structure:
1. `# Group Name`
2. `## Key Contributions` — major papers/systems
3. `## Trajectory` — where they're heading
4. `## Relevance to Our Work`
5. `## Related`

### Concept Page (`concepts/`)

Cross-cutting methodological ideas that appear across multiple topics.

```yaml
---
type: concept
aliases: [alternate names]
related_projects: [project-slug, ...]
related_concepts: [page-slug, ...]
confidence: high | medium | speculative
last_reviewed: YYYY-MM-DD
---
```

Structure:
1. `# Title`
2. One-paragraph definition (2-4 sentences)
3. `## Key Claims` — numbered, each with citation or source
4. `## Evidence` — from our research + literature
5. `## Open Questions` — what we don't know yet
6. `## Related` — `[[wikilinks]]` to other pages

### Note on Papers/Entities

Individual papers are **not** given standalone pages. Instead, they are described within
the relevant topic page(s). When ingesting a new paper, find the topic(s) it belongs to
and add it there with context. This keeps papers from being scattered and ensures each
is immediately positioned relative to other work in the same subfield.
5. `## Limitations` — known gaps, critiques, or scope boundaries
6. `## Related`

### Synthesis Page (`syntheses/`)

For cross-cutting analyses that integrate multiple concepts and sources.

```yaml
---
type: synthesis
source_pages: [page-slugs this synthesizes]
related_projects: [project-slug, ...]
last_reviewed: YYYY-MM-DD
---
```

Structure:
1. `# Title`
2. `## Thesis` — 1-3 sentence core claim
3. `## Evidence & Argument` — detailed analysis with citations
4. `## Implications` — what this means for our research
5. `## Sources` — citations with `[[wikilinks]]`

### Query Result Page (`queries/`)

For promoted query results — valuable answers worth preserving.

```yaml
---
type: query
original_question: "the question that was asked"
date_answered: YYYY-MM-DD
source_pages: [pages consulted]
---
```

Structure:
1. `# Question Title`
2. `## Short Answer` — 2-3 sentences
3. `## Detailed Analysis`
4. `## Sources Consulted`
5. `## Follow-up Questions`

---

## Linking Conventions

- Use `[[page-slug]]` for wiki-internal links (Obsidian-compatible)
- Use `[text](../path)` for links to project files outside the wiki
- Every page must have at least one incoming link (no orphans)
- Cross-reference IDEAS.md sections by name when relevant

## Naming Conventions

- Filenames: kebab-case, descriptive, no dates (e.g., `variance-compression.md`)
- One concept per page — split if a page covers two distinct ideas
- Prefer specificity over generality (e.g., `schelling-segregation-model.md` not `segregation.md`)
- Entity pages for papers: `lastnames-keyword-year.md` (e.g., `park-generative-agents-2023.md`)

## Page Size

- Concept pages: under 500 words (concise definitions, not essays)
- Entity pages: under 400 words (summaries, not full reviews)
- Synthesis pages: under 800 words (focused arguments)
- Query pages: under 600 words

---

## Operations

### Ingest

When processing a new source (paper, article, reading notes):

1. Add the source file to `sources/papers/` or `sources/notes/`
2. Create/update entity page for the paper (title, authors, key claims)
3. Create/update entity pages for notable authors/labs if they don't exist
4. Identify 3-7 key concepts — for each, create or update a concept page
5. Check if the source changes any existing synthesis page
6. Add `[[wikilinks]]` between new and existing pages
7. Append to `log.md`
8. Update `index.md`

### Query

When answering a question using the wiki:

1. Read `index.md` to identify candidate pages
2. Read relevant concept, entity, and synthesis pages
3. Synthesize an answer with citations to wiki pages
4. If the answer reveals a novel insight worth preserving, offer to promote it to `queries/`
5. Append to `log.md`

### Lint

Health checks for wiki consistency:

1. **Orphan detection**: every page must have at least one incoming `[[wikilink]]`
2. **Stale claims**: pages not reviewed in 60+ days (check `last_reviewed`)
3. **IDEAS.md coverage**: every confirmed building block should have a concept page
4. **Index consistency**: all pages listed in `index.md`, no dead links
5. **Contradiction scan**: check synthesis pages for conflicting claims

---

## Relationship to Other Systems

- **IDEAS.md**: Ephemeral scratchpad. Ideas graduate to wiki pages when confirmed. Wiki pages link back to IDEAS.md sections when relevant.
- **Project docs** (`{project}/docs/`): Stay in their project directories. Wiki pages cross-reference them but don't replace them.
- **CLAUDE.md**: Contains the wiki protocol section that triggers these workflows.
- **Dashboard**: Discovers and renders wiki pages at `/wiki`. Read-only display.
- **Obsidian**: Optional local viewer. Open `wiki/` as a vault for graph exploration.
