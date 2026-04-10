# Researcher Pack

A pattern for keeping research activities connected when most of your tools are LLMs.

This is an idea file, designed to be copy-pasted to your own LLM agent (e.g. Claude Code, OpenAI Codex, OpenCode, or similar). Its goal is to communicate the pattern at a high level. Your agent will build out the specifics in collaboration with you.

### The core idea

Most people's experience of LLM-augmented research looks like a bag of disconnected tools. A chatbot for brainstorming. A summarizer for papers. An autocomplete for writing. A spaced-repetition app for reviewing. A notebook for thoughts. Each tool is individually impressive. Each one, used by itself, makes some part of research faster or easier.

And yet, after a few months of this, most researchers notice the same thing: the work feels fragmented in a way it didn't before. You read a paper on Monday and by Thursday the insight is gone. You brainstorm an idea and never evaluate it rigorously. You write a section and never test whether you actually understand the thing you're writing about. The summary you had the LLM generate sits in a folder you don't open again. The notes from the brainstorming chat are lost in a thread you can't find. Each tool does its one job well and then stops. Nothing compounds.

The diagnosis is not that any particular tool is weak. The diagnosis is that **research is not a set of activities — it's a set of activities that feed each other, and the handoff between activities is where the work lives.** If reading doesn't feed practice, you don't learn what you read. If practice doesn't feed writing, your writing is ungrounded. If writing doesn't feed the knowledge base, the next paper starts from scratch. Humans are bad at handoffs; the bookkeeping is tedious, and tedious maintenance is what gets skipped first.

The pattern here is to **treat research as a single integrated loop where each activity's output automatically becomes structured input to the next, and where an LLM agent maintains all the handoffs for you.** You read a paper and it joins a persistent knowledge base that gets tested against later. You practice and the gaps the system finds direct what you read next. You brainstorm and the agent already knows what you know and what's been tried. You write and the writing gets challenged against your own understanding.

The key shift is subtle but load-bearing: **you stop being the integrator between your own tools.** The agent is. You bring taste, judgment, vision, and the actual intellectual work. The agent brings bookkeeping, cross-referencing, context-holding, and the kind of unglamorous consistency that humans abandon the moment it gets boring. The research is yours. The glue is the agent's.

### What the activities look like

Deliberately: the point of this pattern is not to prescribe a fixed set of activities. Your research will have its own shape. But as a starting point, most research workflows include some version of:

*   **Reading and ingestion** — pulling new sources into a persistent knowledge artifact. Karpathy's [LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f) pattern describes one way to do this well.
*   **Active practice** — forcing yourself to retrieve and argue from memory, not just recognize. The companion *Mental Gym* idea file describes this pattern specifically.
*   **Idea generation and evaluation** — brainstorming where the agent doesn't just generate ideas but also stress-tests them, checks the competitive landscape, and forces you to articulate a compelling conclusion before you commit.
*   **Project scaffolding and experiments** — turning surviving ideas into tracked work with reproducible artifacts.
*   **Writing and review** — getting real critique from specialist agents that follow codified principles (consistency, logic, prose quality, citation hygiene), not generic "make this better" prompts.

Your research may not include all of these. It may include others — fieldwork notes, interview transcripts, data curation, code review, reading group discussions. The pattern is the same regardless of the specific activities: each one produces an output the next can use, and something maintains the handoff so that nothing leaks.

Resist the urge to lock in a canonical list. Start with the activities you actually do, and add more when you find yourself wishing the agent could help with one it doesn't know about yet.

### Architecture

Three layers, at the level of pattern:

**Tools.** One piece of software (or skill, or agent, or script) per activity. Each should be independently useful — a good reading tool should be good even if you throw away everything else. Coupling the tools too tightly is a trap; the power comes from composition, not from monolithic design. Reuse existing tools whenever you can. The pattern doesn't require new software so much as it requires that the software you already use share a common substrate.

**Shared state.** A small number of inspectable files that record the state of your research: what's in the knowledge base, what's been practiced, what ideas survived evaluation, what's due for review, what happened recently. Plain text. YAML, markdown, JSONL — anything your agent can read and any human can open in an editor. This is the bus the tools talk over. The agent reads it on every session to know the state of the world. You read it when you want to see what you've been doing.

**Bookkeeping daemon.** Something that runs on every significant file write and updates the shared state. A hook, a file watcher, a cron job — whatever fits your environment. This is what closes the loop without the human having to remember. Without it, the pattern degrades to "maintain a tidy knowledge base by sheer discipline," which is exactly the thing humans fail at.

A note on the tools: the exact set matters less than the interface. As long as each tool reads from and writes to the shared state, the loop works. This is also what makes the pattern portable across implementations — you can swap one tool for a better one as long as the new one honors the same state contract.

### Operations

Three operations define the rhythm of the loop:

**Session start.** The agent reads the shared state and presents a briefing. What's due? What happened since last time? What's stale? What's blocked? Which thread needs attention? The briefing itself has value beyond the information — it removes the "what was I doing?" cost of context switching, which is surprisingly expensive in research work. Over time the briefing becomes the most-used feature in the whole system.

**Activity.** You do whatever the session calls for — read, practice, brainstorm, experiment, write. The tool you pick updates the shared state as a side effect (this is what the bookkeeping daemon handles automatically). The agent watches for handoffs: if you just ingested a paper, it might suggest practicing the concepts; if you just finished an experiment, it might suggest updating the knowledge base; if you just wrote a section, it might suggest testing your own understanding of the claims. These suggestions should be non-coercive — you ignore them freely — but they're valuable when you're tired and would otherwise just stop.

**Review.** Periodically — weekly or monthly — the agent produces a digest from the event log: what you did, how knowledge grew, what's drifting, what to prioritize. This is not a productivity report; it's a navigation aid. It surfaces patterns you wouldn't notice by looking at any single session ("you've been reading a lot but not practicing", "three concepts have gotten stale this month", "the idea you pursued two weeks ago hasn't been touched since").

These three operations are enough to make the loop self-sustaining. You can add more — scheduled lints, hourly summaries, cross-project syntheses — but start with these.

### Why this works

Individual LLM-research tools are commodity. Anyone can use Claude to summarize a paper, brainstorm ideas, or draft a section. What isn't commodity is the integration. Most tools for researchers solve one activity brilliantly and then stop, leaving the handoff to the user. The pattern here is the opposite — no single tool does anything remarkable, but the compound effect of the loop matters more than the cleverness of any individual piece.

The bookkeeping is also, conveniently, the part humans hate most and LLMs do best. Humans abandon knowledge bases because maintaining cross-references, updating stale pages, and logging activity is boring. LLMs don't get bored. They also don't get tired, forget to log things, or skip the update because they're hungry. The maintenance cost approaches zero, which means the system stays maintained, which is the thing that makes it actually useful over time.

And one more insight that's less obvious: **the handoff between activities is where research identity lives.** If an idea you read about never shows up in your practice, you didn't learn it. If a paper you wrote wasn't tested against your own understanding, you wrote someone else's paper. If a brainstorming session never became a project, it was just chat. The connections are where "doing research" actually happens — and the loop is what enforces that the connections get made.

### Note

This document is intentionally abstract. The exact set of activities, the specific tools, the schema for the shared state, the format of the event log, the trigger for the bookkeeping daemon — all of it will depend on your domain, your research style, your taste, and your agent. Start minimal: one tool, one state file, one hook. Grow it only when you notice something falling through a crack that another piece would catch.

There's a reference implementation informed by this pattern — paper reading, deliberate practice, idea generation, experiment scaffolding, writing review — built on Claude Code, at [github.com/andrehuang/researcher-pack](https://github.com/andrehuang/researcher-pack). It's the pack I use for my own research, packaged as a standalone repo with an `init` wizard that scaffolds a fresh research environment in a few prompts. That said, the pattern is what matters — your agent can help you instantiate a version that fits your own work, with or without the reference implementation. The document's only job is to communicate the shape.
