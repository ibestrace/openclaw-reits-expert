#!/bin/bash
# OpenClaw REITs Expert System - Structural Validation Script
# Checks workspace integrity, install script consistency, and configuration sync.
#
# Usage: ./scripts/validate.sh
# Exit code: 0 = all checks passed, 1 = one or more checks failed

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

ERRORS=0
WARNINGS=0

red() { printf '\033[0;31m%s\033[0m\n' "$1"; }
green() { printf '\033[0;32m%s\033[0m\n' "$1"; }
yellow() { printf '\033[1;33m%s\033[0m\n' "$1"; }
blue() { printf '\033[0;34m%s\033[0m\n' "$1"; }

header() {
    echo ""
    blue "================================================"
    blue "  $1"
    blue "================================================"
}

# Helper: mark error or warning
fail() { red "  ❌ $1"; ((ERRORS++)) || true; }
warn() { yellow "  ⚠️  $1"; ((WARNINGS++)) || true; }
pass() { green "  ✅ $1"; }

# ---------------------------------------------------------------------------
# 1. Workspace directory integrity
# ---------------------------------------------------------------------------
header "Check 1: Workspace Directory Integrity"

WORKSPACE_DIRS=("$PROJECT_DIR"/workspace-*)
TOTAL_WORKSPACES=0

for ws_dir in "${WORKSPACE_DIRS[@]}"; do
    [ -d "$ws_dir" ] || continue
    ((TOTAL_WORKSPACES++)) || true
    ws_name="$(basename "$ws_dir")"

    has_soul=false
    has_agents=false

    if [ -f "$ws_dir/SOUL.md" ]; then
        has_soul=true
    fi

    if [ -f "$ws_dir/AGENTS.md" ]; then
        has_agents=true
    fi

    if [ "$has_soul" = true ] && [ "$has_agents" = true ]; then
        pass "$ws_name (SOUL.md + AGENTS.md)"
    else
        missing=()
        [ "$has_soul" = false ] && missing+=("SOUL.md")
        [ "$has_agents" = false ] && missing+=("AGENTS.md")
        fail "$ws_name missing: ${missing[*]}"
    fi

    # Optional: check frontmatter presence in SOUL.md
    if [ "$has_soul" = true ]; then
        if ! head -1 "$ws_dir/SOUL.md" | grep -q '^---'; then
            warn "$ws_name/SOUL.md missing YAML frontmatter"
        fi
    fi
done

if [ "$TOTAL_WORKSPACES" -eq 0 ]; then
    fail "No workspace-* directories found"
else
    pass "Found $TOTAL_WORKSPACES workspace directorie(s)"
fi

# ---------------------------------------------------------------------------
# 2. openclaw.json vs disk consistency
# ---------------------------------------------------------------------------
header "Check 2: openclaw.json vs Disk Consistency"

OPENCLAW_JSON="$PROJECT_DIR/openclaw.json"
if [ ! -f "$OPENCLAW_JSON" ]; then
    fail "openclaw.json not found in project root"
else
    pass "openclaw.json exists"

    # Extract agentIds from openclaw.json, stopping at _examples section
    # to avoid picking up duplicate agentIds in the examples block.
    # Deduplicate because agentId may also appear in bindings.
    RAW_AGENTS=()
    while IFS= read -r line; do
        if echo "$line" | grep -q '"_examples"'; then
            break
        fi
        agent_id="$(echo "$line" | sed -n 's/.*"agentId"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p')"
        if [ -n "$agent_id" ]; then
            RAW_AGENTS+=("$agent_id")
        fi
    done < "$OPENCLAW_JSON"
    # Deduplicate while preserving order
    REGISTERED_AGENTS=()
    declare -A SEEN
    for a in "${RAW_AGENTS[@]}"; do
        if [ -z "${SEEN[$a]+x}" ]; then
            SEEN[$a]=1
            REGISTERED_AGENTS+=("$a")
        fi
    done

    if [ ${#REGISTERED_AGENTS[@]} -eq 0 ]; then
        warn "Could not parse agentIds from openclaw.json"
    else
        pass "Found ${#REGISTERED_AGENTS[@]} agent(s) in openclaw.json"

        for agent_id in "${REGISTERED_AGENTS[@]}"; do
            ws_dir="$PROJECT_DIR/workspace-$agent_id"
            if [ -d "$ws_dir" ]; then
                pass "workspace-$agent_id exists on disk"
            else
                fail "workspace-$agent_id missing (registered in openclaw.json)"
            fi
        done
    fi
fi

# ---------------------------------------------------------------------------
# 3. Install script workspace list consistency
# ---------------------------------------------------------------------------
header "Check 3: Install Script Consistency"

# Extract WORKSPACES from install.sh
SH_WORKSPACES=()
if [ -f "$PROJECT_DIR/install.sh" ]; then
    while IFS= read -r line; do
        ws="$(echo "$line" | sed -n 's/.*"\(workspace-[^"]*\)".*/\1/p')"
        if [ -n "$ws" ]; then
            SH_WORKSPACES+=("$ws")
        fi
    done < <(sed -n '/^WORKSPACES=(/,/)/p' "$PROJECT_DIR/install.sh")
    pass "install.sh readable"
else
    fail "install.sh not found"
fi

# Extract WORKSPACES from install.ps1
PS_WORKSPACES=()
if [ -f "$PROJECT_DIR/install.ps1" ]; then
    while IFS= read -r line; do
        ws="$(echo "$line" | sed -n 's/.*"\(workspace-[^"]*\)".*/\1/p')"
        if [ -n "$ws" ]; then
            PS_WORKSPACES+=("$ws")
        fi
    done < <(sed -n '/\$WORKSPACES = @(/,/)/p' "$PROJECT_DIR/install.ps1")
    pass "install.ps1 readable"
else
    fail "install.ps1 not found"
fi

# Compare install.sh vs install.ps1
if [ ${#SH_WORKSPACES[@]} -gt 0 ] && [ ${#PS_WORKSPACES[@]} -gt 0 ]; then
    SH_SORTED="$(printf '%s\n' "${SH_WORKSPACES[@]}" | sort | tr '\n' ' ')"
    PS_SORTED="$(printf '%s\n' "${PS_WORKSPACES[@]}" | sort | tr '\n' ' ')"

    if [ "$SH_SORTED" = "$PS_SORTED" ]; then
        pass "install.sh & install.ps1 workspace lists match (${#SH_WORKSPACES[@]} entries)"
    else
        fail "install.sh & install.ps1 workspace lists differ"
        # Show diff
        printf '%s\n' "${SH_WORKSPACES[@]}" | sort > /tmp/sh_ws.txt
        printf '%s\n' "${PS_WORKSPACES[@]}" | sort > /tmp/ps_ws.txt
        comm -23 /tmp/sh_ws.txt /tmp/ps_ws.txt | while read -r w; do
            yellow "    only in install.sh: $w"
        done
        comm -13 /tmp/sh_ws.txt /tmp/ps_ws.txt | while read -r w; do
            yellow "    only in install.ps1: $w"
        done
    fi
fi

# Compare install scripts vs disk
DISK_WORKSPACES=()
for d in "$PROJECT_DIR"/workspace-*/; do
    [ -d "$d" ] || continue
    DISK_WORKSPACES+=("$(basename "$d")")
done

if [ ${#SH_WORKSPACES[@]} -gt 0 ] && [ ${#DISK_WORKSPACES[@]} -gt 0 ]; then
    SH_SORTED="$(printf '%s\n' "${SH_WORKSPACES[@]}" | sort | tr '\n' ' ')"
    DISK_SORTED="$(printf '%s\n' "${DISK_WORKSPACES[@]}" | sort | tr '\n' ' ')"

    if [ "$SH_SORTED" = "$DISK_SORTED" ]; then
        pass "Install scripts match disk workspaces"
    else
        warn "Install scripts differ from disk workspaces"
        printf '%s\n' "${DISK_WORKSPACES[@]}" | sort > /tmp/disk_ws.txt
        printf '%s\n' "${SH_WORKSPACES[@]}" | sort > /tmp/sh_ws2.txt
        comm -23 /tmp/disk_ws.txt /tmp/sh_ws2.txt | while read -r w; do
            yellow "    on disk but not in install.sh: $w"
        done
        comm -13 /tmp/disk_ws.txt /tmp/sh_ws2.txt | while read -r w; do
            yellow "    in install.sh but not on disk: $w"
        done
    fi
fi

# ---------------------------------------------------------------------------
# 4. openclaw.json agents.list vs install scripts
# ---------------------------------------------------------------------------
header "Check 4: openclaw.json vs Install Scripts"

if [ ${#REGISTERED_AGENTS[@]} -gt 0 ] && [ ${#SH_WORKSPACES[@]} -gt 0 ]; then
    MISMATCH=0
    for agent_id in "${REGISTERED_AGENTS[@]}"; do
        ws_name="workspace-$agent_id"
        found=false
        for sh_ws in "${SH_WORKSPACES[@]}"; do
            if [ "$sh_ws" = "$ws_name" ]; then
                found=true
                break
            fi
        done
        if [ "$found" = false ]; then
            fail "Agent '$agent_id' in openclaw.json but missing from install.sh"
            ((MISMATCH++)) || true
        fi
    done

    for sh_ws in "${SH_WORKSPACES[@]}"; do
        agent_id="${sh_ws#workspace-}"
        found=false
        for reg in "${REGISTERED_AGENTS[@]}"; do
            if [ "$reg" = "$agent_id" ]; then
                found=true
                break
            fi
        done
        if [ "$found" = false ]; then
            fail "Workspace '$sh_ws' in install.sh but missing from openclaw.json"
            ((MISMATCH++)) || true
        fi
    done

    if [ "$MISMATCH" -eq 0 ]; then
        pass "openclaw.json & install.sh are fully consistent"
    fi
fi

# ---------------------------------------------------------------------------
# 5. docs/ directory (should not contain stale shadow files)
# ---------------------------------------------------------------------------
header "Check 5: docs/ Directory"

DOCS_DIR="$PROJECT_DIR/docs"
if [ ! -d "$DOCS_DIR" ]; then
    pass "docs/ directory does not exist (OK)"
else
    # Look for files that look like old agent definitions
    SHADOW_FILES=()
    while IFS= read -r -d '' f; do
        basename_f="$(basename "$f")"
        if echo "$basename_f" | grep -qiE '(REITs.*专家|系统配置指令|身份设定)'; then
            SHADOW_FILES+=("$basename_f")
        fi
    done < <(find "$DOCS_DIR" -maxdepth 1 -type f -print0 2>/dev/null || true)

    if [ ${#SHADOW_FILES[@]} -gt 0 ]; then
        fail "docs/ contains potential shadow files: ${SHADOW_FILES[*]}"
    else
        pass "docs/ is clean"
    fi
fi

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
header "Validation Summary"

if [ "$ERRORS" -eq 0 ] && [ "$WARNINGS" -eq 0 ]; then
    green "  🎉 All checks passed!"
    exit 0
elif [ "$ERRORS" -eq 0 ]; then
    yellow "  ⚠️  $WARNINGS warning(s) — no blocking issues"
    exit 0
else
    red "  ❌ $ERRORS error(s), $WARNINGS warning(s) — please fix before continuing"
    exit 1
fi
