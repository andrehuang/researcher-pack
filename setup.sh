#!/bin/bash
# Researcher Pack — Setup Script
#
# Usage:
#   ./setup.sh init          # interactive wizard: scaffold a fresh repo with the pack
#   ./setup.sh link          # re-symlink skills/agents/principles into ~/.claude/ (after git pull)
#   ./setup.sh               # defaults to `link` for backward compatibility
#
# The pack consists of:
#   - skills/       -> symlinked into ~/.claude/skills/
#   - agents/       -> copied into  ~/.claude/agents/
#   - principles/   -> copied into  ~/.claude/principles/
#   - hooks/        -> copied into  <target-repo>/.claude/hooks/ (per-repo)
#   - templates/    -> materialized into <target-repo>/ at init time

set -e

PACK_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILLS_TARGET="$HOME/.claude/skills"
AGENTS_TARGET="$HOME/.claude/agents"
PRINCIPLES_TARGET="$HOME/.claude/principles"

MODE="${1:-link}"

# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------

info()    { printf "  [ok] %s\n" "$1"; }
action()  { printf "  [+]  %s\n" "$1"; }
warn()    { printf "  [!]  %s\n" "$1"; }
bold()    { printf "\033[1m%s\033[0m\n" "$1"; }

prompt() {
    local question="$1"
    local default="$2"
    local answer
    if [ -n "$default" ]; then
        printf "  %s [%s]: " "$question" "$default" >&2
    else
        printf "  %s: " "$question" >&2
    fi
    read -r answer
    echo "${answer:-$default}"
}

confirm() {
    local question="$1"
    local default="${2:-N}"
    local answer
    printf "  %s (y/N): " "$question" >&2
    read -r answer
    answer="${answer:-$default}"
    case "$answer" in y|Y|yes|YES) return 0 ;; *) return 1 ;; esac
}

link_user_assets() {
    # Skills: symlinked so `git pull` updates them automatically
    mkdir -p "$SKILLS_TARGET"
    for skill_dir in "$PACK_DIR"/skills/*/; do
        [ -d "$skill_dir" ] || continue
        local name
        name=$(basename "$skill_dir")
        if [ -L "$SKILLS_TARGET/$name" ]; then
            local existing
            existing=$(readlink "$SKILLS_TARGET/$name")
            if [ "$existing" = "${skill_dir%/}" ] || [ "$existing" = "$skill_dir" ]; then
                info "skill: $name (already linked)"
                continue
            fi
            rm "$SKILLS_TARGET/$name"
        elif [ -e "$SKILLS_TARGET/$name" ]; then
            warn "skill: $name (existing non-symlink, skipping — remove manually to relink)"
            continue
        fi
        ln -sfn "$skill_dir" "$SKILLS_TARGET/$name"
        action "skill: $name"
    done

    # Agents: copied (Claude Code reads them directly)
    mkdir -p "$AGENTS_TARGET"
    for agent_file in "$PACK_DIR"/agents/*.md; do
        [ -f "$agent_file" ] || continue
        cp "$agent_file" "$AGENTS_TARGET/$(basename "$agent_file")"
        action "agent: $(basename "$agent_file")"
    done

    # Principles: copied (writing and research-strategy principles)
    mkdir -p "$PRINCIPLES_TARGET"
    for p in "$PACK_DIR"/principles/*.md; do
        [ -f "$p" ] || continue
        cp "$p" "$PRINCIPLES_TARGET/$(basename "$p")"
        action "principle: $(basename "$p")"
    done
}

install_repo_hooks() {
    local repo="$1"
    mkdir -p "$repo/.claude/hooks"
    cp "$PACK_DIR/hooks/research_hook.sh" "$repo/.claude/hooks/"
    cp "$PACK_DIR/hooks/auto_commit.sh"   "$repo/.claude/hooks/"
    chmod +x "$repo/.claude/hooks/research_hook.sh" "$repo/.claude/hooks/auto_commit.sh"
    action "hooks installed at $repo/.claude/hooks/"
}

materialize_template() {
    # $1 = template filename under templates/
    # $2 = destination path
    # Replaces __TS__, __DOMAIN__, __WIKI_PATH__, __MENTAL_GYM_PATH__ placeholders.
    local src="$PACK_DIR/templates/$1"
    local dst="$2"
    local ts
    ts=$(date -u +"%Y-%m-%dT%H:%M:%S")
    sed \
        -e "s|__TS__|$ts|g" \
        -e "s|__DOMAIN__|$DOMAIN|g" \
        -e "s|__WIKI_PATH__|$WIKI_REL|g" \
        -e "s|__MENTAL_GYM_PATH__|$MENTAL_GYM_REL|g" \
        "$src" > "$dst"
}

# --------------------------------------------------------------------------
# Mode: link (default)
# --------------------------------------------------------------------------

run_link() {
    bold "Researcher Pack — link mode"
    echo "Linking skills, agents, and principles into ~/.claude/"
    echo ""
    link_user_assets
    echo ""
    bold "Done."
    echo "Use \`./setup.sh init\` from a research repo to scaffold hooks and state files."
}

# --------------------------------------------------------------------------
# Mode: init (interactive wizard)
# --------------------------------------------------------------------------

run_init() {
    bold "Researcher Pack — init wizard"
    echo "Scaffold a research repo with the full loop: skills, agents, hooks, state files, wiki."
    echo ""

    # 1. Target repo root
    local default_repo
    default_repo=$(pwd)
    REPO=$(prompt "Target repo root" "$default_repo")
    REPO=$(cd "$REPO" && pwd)
    mkdir -p "$REPO"
    echo "  -> using repo: $REPO"
    echo ""

    # 2. Research domain
    DOMAIN=$(prompt "Research domain (one-line descriptor)" "research")
    echo ""

    # 3. Wiki location
    local default_wiki="$REPO/wiki"
    local wiki_input
    wiki_input=$(prompt "Wiki location (absolute or relative to repo)" "$default_wiki")
    case "$wiki_input" in
        /*) WIKI_ABS="$wiki_input" ;;
        *)  WIKI_ABS="$REPO/$wiki_input" ;;
    esac
    # Compute repo-relative path for state file
    WIKI_REL="${WIKI_ABS#$REPO/}"
    echo "  -> wiki: $WIKI_ABS"
    echo ""

    # 4. Mental Gym integration
    MENTAL_GYM_REL="mental-gym"
    if confirm "Enable Mental Gym integration?"; then
        local mg_input
        mg_input=$(prompt "Mental Gym directory (or 'skip' to use PATH lookup)" "$REPO/mental-gym")
        if [ "$mg_input" = "skip" ]; then
            MENTAL_GYM_REL=""
        else
            case "$mg_input" in
                /*) MENTAL_GYM_REL="${mg_input#$REPO/}" ;;
                *)  MENTAL_GYM_REL="$mg_input" ;;
            esac
        fi
        if ! command -v mental-gym >/dev/null 2>&1 && [ ! -x "$REPO/$MENTAL_GYM_REL/.venv/bin/mental-gym" ]; then
            warn "Mental Gym not found on PATH or at $REPO/$MENTAL_GYM_REL"
            warn "Install: https://github.com/andrehuang/mental-gym"
        fi
    else
        MENTAL_GYM_REL=""
    fi
    echo ""

    # 5. Auto-commit hook
    local want_autocommit="no"
    if confirm "Enable auto-commit? (hooks commit + push after a 30s quiet period)"; then
        want_autocommit="yes"
    fi
    echo ""

    bold "Scaffolding..."

    # 6. Create .claude structure
    mkdir -p "$REPO/.claude"
    install_repo_hooks "$REPO"

    # 7. Research state
    if [ -f "$REPO/.claude/research-state.yaml" ]; then
        warn "research-state.yaml already exists — leaving as-is"
    else
        materialize_template "research-state.yaml.template" "$REPO/.claude/research-state.yaml"
        action "research-state.yaml created"
    fi

    # 8. Events log
    if [ -f "$REPO/events.jsonl" ]; then
        warn "events.jsonl already exists — leaving as-is"
    else
        materialize_template "events.jsonl.template" "$REPO/events.jsonl"
        action "events.jsonl bootstrapped"
    fi

    # 9. settings.local.json
    if [ -f "$REPO/.claude/settings.local.json" ]; then
        warn "settings.local.json exists — NOT overwriting. Merge hooks block manually:"
        warn "  see $PACK_DIR/templates/settings.local.json.template"
    else
        cp "$PACK_DIR/templates/settings.local.json.template" "$REPO/.claude/settings.local.json"
        action "settings.local.json created with hook registration"
    fi

    # 10. Auto-commit marker
    if [ "$want_autocommit" = "yes" ]; then
        touch "$REPO/.claude/autocommit.enabled"
        action "auto-commit enabled (marker: .claude/autocommit.enabled)"
    fi

    # 11. Wiki scaffold
    if [ -f "$WIKI_ABS/wiki.schema.md" ]; then
        warn "wiki already initialized at $WIKI_ABS — leaving as-is"
    else
        mkdir -p "$WIKI_ABS"/{topics,concepts,groups,syntheses,queries,sources,entities}
        cp "$PACK_DIR/templates/wiki/wiki.schema.md" "$WIKI_ABS/wiki.schema.md"
        cp "$PACK_DIR/templates/wiki/CLAUDE.md"      "$WIKI_ABS/CLAUDE.md"
        cp "$PACK_DIR/templates/wiki/index.md"       "$WIKI_ABS/index.md"
        cp "$PACK_DIR/templates/wiki/log.md"         "$WIKI_ABS/log.md"
        action "wiki scaffolded at $WIKI_ABS"
    fi

    # 12. Link user-level assets
    echo ""
    bold "Linking user-level assets..."
    link_user_assets

    echo ""
    bold "Done."
    echo ""
    echo "Next steps:"
    echo "  1. cd $REPO"
    echo "  2. open Claude Code in this repo"
    echo "  3. run /research-session to see your first briefing"
    if [ -n "$MENTAL_GYM_REL" ]; then
        echo "  4. install mental-gym (if not already): https://github.com/andrehuang/mental-gym"
    fi
}

# --------------------------------------------------------------------------
# Dispatch
# --------------------------------------------------------------------------

case "$MODE" in
    init)  run_init ;;
    link)  run_link ;;
    *)
        echo "Usage: $0 [init|link]" >&2
        exit 1
        ;;
esac
