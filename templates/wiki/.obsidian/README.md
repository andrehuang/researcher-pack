# .obsidian/ — Starter Vault Config

This directory is an **opinionated starter** for opening the wiki as an Obsidian vault. It is not required — delete `.obsidian/` entirely and Obsidian will regenerate defaults the next time you open the vault.

## What's here

- **`app.json`** — core editor settings: source-mode default, new files land in `topics/`, attachments go under `sources/attachments/`, wikilinks (not markdown links), auto-update links on rename.
- **`graph.json`** — graph-view defaults with color groups per page type (topics, concepts, groups, syntheses, queries, research-evaluations) so the knowledge graph is readable on first open. Coloring is by **directory path** (`path:topics/`, `path:concepts/`, etc.), not by frontmatter `type:`. The two must stay in sync — the wiki schema already enforces file-location-by-type (topic pages live in `topics/`, concept pages in `concepts/`, and so on), and the linter flags any frontmatter/path mismatch, so in practice the folder-based coloring matches the conceptual type.
- **`workspace.json`** — minimal layout: file explorer on the left, `index.md` open in the main pane, graph view on the right.
- **`community-plugins.json`** — empty list. No community plugins are installed by default.

## Recommended manual install

**Dataview** is a recommended community plugin — the example queries in the main `README.md` assume it is available. Install it from Settings → Community plugins inside Obsidian.

## Reconfigure freely

Everything in this directory is local-machine preference. Edit it, delete it, or ignore it — the wiki content (markdown files) is the source of truth.
