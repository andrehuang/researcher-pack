---
name: weekly-review
description: >-
  Generate a weekly research digest — activity summary, knowledge growth, priorities. TRIGGER when: user asks for a weekly review, research summary, progress check, or "what did I do this week." Reads events.jsonl, research-state.yaml, wiki, mental-gym status, and IDEAS.md to produce a structured report.
allowed-tools: Agent, Read, Glob, Grep, Edit, Write, Bash, WebSearch, WebFetch
argument-hint: [optional: "last N days" or date range]
---

# Weekly Review — Research Digest

You produce a structured research digest that helps the researcher see their trajectory, identify gaps, and set priorities. This is reflection and planning, not just reporting.

ultrathink

## Context Loading

Read all sources in parallel:

1. **`events.jsonl`** — filter to the review period (default: last 7 days). Count events by type.
2. **`.claude/research-state.yaml`** — current gym, wiki, and session state
3. **`IDEAS.md`** — check for changes (git diff if available), note new items
4. **Wiki pages** — Glob all pages, check `last_reviewed` dates, count by type
5. **Mental Gym status** — run `cd mental-gym && .venv/bin/mental-gym status` to get current mastery data
6. **Git log** — run `git log --oneline --since="7 days ago"` for commit activity
7. **`.review/` directory** — check for unresolved academic review findings

If a date range is provided in $ARGUMENTS (e.g., "last 14 days", "March 1-7"), adjust the filter period accordingly. Default is 7 days from today.

## Report Structure

Present the digest in this format:

```
Weekly Research Digest — [Start Date] to [End Date]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Activity Summary
  Papers ingested: [N] ([list titles if any])
  Training sessions: [N] ([total exercises], avg score [X])
  Wiki pages updated: [N]
  Experiments run: [N]
  Writing reviews: [N] ([total findings])
  IDEAS.md updates: [N]
  Commits: [N]

Knowledge Growth
  Wiki: [total pages] pages ([+N new] this week)
  Topics mastered (>70%): [list or "none yet"]
  Topics improved: [list with deltas, e.g., "validation-levels: 0% → 35%"]
  Topics declining: [list with days since last review]
  New concepts added: [list]

Research Trajectory
  Active threads: [from IDEAS.md and recent events]
  Decisions made: [any PURSUE/PARK/KILL from research-companion]
  Dots connected: [any new connections identified]
  Questions answered: [any wiki queries promoted]

Health Checks
  Stale wiki pages (>60 days): [list]
  Orphan wiki pages: [list]
  Unresolved review findings: [count and file]
  Training streak: [N days, or "broken — last session [date]"]
  IDEAS.md last updated: [date]
```

## Analysis Layer

After the report, add a brief analysis section (3-5 bullet points):

### Patterns
- What topics are getting the most attention? Is this aligned with priorities?
- Are there blind spots — topics that haven't been touched?
- Is the read→ingest→train flywheel running, or is one step being skipped?

### Connections
- Did any papers ingested this week connect to each other or to existing work?
- Are there IDEAS.md dots-to-connect that now have more evidence?
- Did training reveal knowledge gaps that should drive the next reading?

### Risks
- Is any project stuck or losing momentum?
- Are there stale wiki pages in areas of active research?
- Is the researcher learning broadly but not deeply, or vice versa?

## Priorities for Next Week

Based on the analysis, suggest 3-5 priorities ranked by impact:

```
Priorities for [Next Week Dates]
  1. [Priority] — [why it matters] — [specific action]
  2. ...
  3. ...
```

Priority categories:
- **Knowledge gaps**: Topics with low mastery that are needed for active work
- **Stale knowledge**: Wiki pages or training topics that need refreshing
- **Momentum**: Projects that need a push to stay on track
- **Opportunities**: New connections or ideas worth exploring
- **Maintenance**: Wiki lint, review findings, broken streaks

## Optional Actions

After presenting the digest, offer:

1. **Update IDEAS.md** — "Based on this week's activity, I'd suggest adding/updating these items in IDEAS.md: [list]. Want me to make these edits?"

2. **Graduate mature ideas** — "These IDEAS.md items seem ready to become wiki pages: [list]. Want to promote them?"

3. **Wiki lint** — "There are [N] health issues in the wiki. Want me to run a full lint and fix them?"

4. **Set focus for next week** — "Want to set a specific focus for next week? I'll adjust your research-state.yaml suggested actions."

5. **Share as event** — Emit a weekly review event:
```jsonl
{"ts":"...","type":"review:weekly","detail":"Week of [dates]: [N] papers, [N] sessions, [N] wiki updates","source":"weekly-review"}
```

## Orchestration Rules

- **Be honest about low activity.** If nothing happened this week, say so without judgment. "Quiet week — that's fine. Here's what might be worth picking up."
- **Spot patterns the researcher might miss.** You see the data across all tools — use that holistic view.
- **Don't moralize about streaks.** Report them factually. Some weeks are for thinking, not training.
- **Suggest, don't prescribe.** Present priorities as suggestions. The researcher knows their context better.
- **Keep it scannable.** The digest should be readable in 2 minutes. Use the structured format above.

## User's Input

$ARGUMENTS
