#!/bin/bash
# Research Hook — enhanced replacement for mental_gym_hook.sh
# Triggered by PostToolUse on Write|Edit
# Updates research-state.yaml, emits events to events.jsonl, suggests next actions.

REPO_ROOT="$(cd "$(dirname "$0")/../.." 2>/dev/null && pwd)"
STATE_FILE="$REPO_ROOT/.claude/research-state.yaml"
EVENTS_FILE="$REPO_ROOT/events.jsonl"
MENTAL_GYM_DIR="$REPO_ROOT/mental-gym"
AUTO_COMMIT="$REPO_ROOT/.claude/hooks/auto_commit.sh"

# Read hook input from stdin
INPUT=$(cat)

# Extract the file path from the tool input
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
data = json.load(sys.stdin)
tool_input = data.get('tool_input', {})
print(tool_input.get('file_path', ''))
" 2>/dev/null)

if [ -z "$FILE_PATH" ]; then
    exit 0
fi

# Skip events.jsonl and research-state.yaml to avoid recursion
case "$FILE_PATH" in
    */events.jsonl|*research-state.yaml)
        exit 0
        ;;
esac

TS=$(date -u +"%Y-%m-%dT%H:%M:%S")

# --- Determine trigger type and act accordingly ---

emit_event() {
    local type="$1"
    local detail="$2"
    local source="$3"
    if [ -n "$EVENTS_FILE" ]; then
        printf '{"ts":"%s","type":"%s","detail":"%s","source":"%s"}\n' \
            "$TS" "$type" "$detail" "$source" >> "$EVENTS_FILE"
    fi
}

update_state_timestamp() {
    if [ -f "$STATE_FILE" ]; then
        # Update last_updated timestamp using python for reliable YAML editing
        python3 -c "
import sys
lines = open('$STATE_FILE').readlines()
with open('$STATE_FILE', 'w') as f:
    for line in lines:
        if line.startswith('last_updated:'):
            f.write('last_updated: \"$TS\"\n')
        else:
            f.write(line)
" 2>/dev/null
    fi
}

# --- Wiki files ---
case "$FILE_PATH" in
    */wiki/topics/*|*/wiki/concepts/*|*/wiki/groups/*|*/wiki/syntheses/*|*/wiki/queries/*)
        PAGE_NAME=$(basename "$FILE_PATH" .md)
        emit_event "wiki:update" "Updated wiki page: $PAGE_NAME" "hook"
        update_state_timestamp

        # Count current wiki pages for state update
        WIKI_COUNT=$(find "$REPO_ROOT/wiki" -name "*.md" \
            ! -name "index.md" ! -name "log.md" ! -name "wiki.schema.md" \
            -path "*/topics/*" -o -path "*/concepts/*" -o -path "*/groups/*" \
            -o -path "*/syntheses/*" -o -path "*/queries/*" 2>/dev/null | wc -l | tr -d ' ')

        # Suggest mental-gym training
        if [ -f "$MENTAL_GYM_DIR/mental_gym.yaml" ] && [ -f "$MENTAL_GYM_DIR/.venv/bin/mental-gym" ]; then
            SUGGESTION=$(cd "$MENTAL_GYM_DIR" && .venv/bin/mental-gym suggest --changed-file "$FILE_PATH" 2>/dev/null)
            if [ -n "$SUGGESTION" ]; then
                echo "$SUGGESTION"
            else
                echo "[Research Hook] Wiki page '$PAGE_NAME' updated. Consider: mental-gym train --focus '$PAGE_NAME'"
            fi
        else
            echo "[Research Hook] Wiki page '$PAGE_NAME' updated. Run mental-gym sync to update training topics."
        fi

        # Queue for auto-commit
        [ -x "$AUTO_COMMIT" ] && bash "$AUTO_COMMIT" "$FILE_PATH"
        exit 0
        ;;
esac

# --- Wiki index/log (no suggestion, just track) ---
case "$FILE_PATH" in
    */wiki/index.md|*/wiki/log.md)
        update_state_timestamp
        [ -x "$AUTO_COMMIT" ] && bash "$AUTO_COMMIT" "$FILE_PATH"
        exit 0
        ;;
esac

# --- Experiment results ---
case "$FILE_PATH" in
    */data/results/*.jsonl|*/data/results/*/*.jsonl)
        EXPERIMENT=$(basename "$(dirname "$FILE_PATH")")
        emit_event "experiment:update" "Experiment data updated: $EXPERIMENT" "hook"
        update_state_timestamp
        echo "[Research Hook] Experiment '$EXPERIMENT' data updated. Consider updating wiki with new findings."
        exit 0
        ;;
esac

# --- Paper drafts and academic writing ---
case "$FILE_PATH" in
    *.tex|*draft*|*paper_draft*|*/papers/*.md)
        DOC_NAME=$(basename "$FILE_PATH")
        emit_event "writing:edit" "Edited: $DOC_NAME" "hook"
        update_state_timestamp
        # Only suggest review for substantial files, not tiny edits
        echo "[Research Hook] Draft '$DOC_NAME' edited. When ready for review, try: /academic review"
        exit 0
        ;;
esac

# --- IDEAS.md ---
case "$FILE_PATH" in
    */IDEAS.md)
        emit_event "ideas:update" "IDEAS.md updated" "hook"
        update_state_timestamp
        echo "[Research Hook] IDEAS.md updated. Check if any mature ideas should graduate to wiki pages."
        [ -x "$AUTO_COMMIT" ] && bash "$AUTO_COMMIT" "$FILE_PATH"
        exit 0
        ;;
esac

# --- Other markdown/research files (lighter touch) ---
case "$FILE_PATH" in
    */wiki/*|*/docs/*|*/papers/*|*.md)
        emit_event "docs:edit" "Edited: $(basename "$FILE_PATH")" "hook"
        update_state_timestamp
        # Run mental-gym suggest for docs/papers
        if [ -f "$MENTAL_GYM_DIR/mental_gym.yaml" ] && [ -f "$MENTAL_GYM_DIR/.venv/bin/mental-gym" ]; then
            SUGGESTION=$(cd "$MENTAL_GYM_DIR" && .venv/bin/mental-gym suggest --changed-file "$FILE_PATH" 2>/dev/null)
            if [ -n "$SUGGESTION" ]; then
                echo "$SUGGESTION"
            fi
        fi
        exit 0
        ;;
esac

# --- Everything else: no action ---
exit 0
