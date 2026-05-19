#!/bin/bash
# OpenClaw REITs Expert System - Installation Script (Linux/macOS)
# This script automates the installation of the REITs expert multi-agent system

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OPENCLAW_DIR="${HOME}/.openclaw"
WORKSPACES=(
    "workspace-reits-expert"
    "workspace-energy-asset-analyst"
    "workspace-utility-asset-analyst"
    "workspace-transport-asset-analyst"
    "workspace-property-asset-analyst"
    "workspace-housing-asset-analyst"
    "workspace-ops-supervisor"
    "workspace-struct-designer"
    "workspace-market-researcher"
    "workspace-esg-analyst"
    "workspace-report-writer"
)

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  OpenClaw REITs Expert System Installer${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""

# Check if OpenClaw is installed
echo -e "${YELLOW}🔍 Checking OpenClaw installation...${NC}"
if ! command -v openclaw &> /dev/null; then
    echo -e "${RED}❌ Error: OpenClaw is not installed or not in PATH${NC}"
    echo "Please install OpenClaw first: https://github.com/openclaw"
    exit 1
fi
echo -e "${GREEN}✅ OpenClaw found: $(openclaw --version 2>/dev/null || echo 'version unknown')${NC}"
echo ""

# Detect OpenClaw workspace directory
echo -e "${YELLOW}📁 Detecting OpenClaw workspace...${NC}"
if [ -d "$OPENCLAW_DIR" ]; then
    echo -e "${GREEN}✅ Found OpenClaw directory: $OPENCLAW_DIR${NC}"
else
    echo -e "${YELLOW}⚠️  OpenClaw directory not found at $OPENCLAW_DIR${NC}"
    echo -e "${YELLOW}   Creating directory...${NC}"
    mkdir -p "$OPENCLAW_DIR"
    echo -e "${GREEN}✅ Created: $OPENCLAW_DIR${NC}"
fi
echo ""

# Create workspace directories
echo -e "${YELLOW}📂 Creating workspace directories...${NC}"
for ws in "${WORKSPACES[@]}"; do
    ws_path="$OPENCLAW_DIR/$ws"
    if [ ! -d "$ws_path" ]; then
        mkdir -p "$ws_path"
        echo -e "  ${GREEN}✓${NC} $ws"
    else
        echo -e "  ${YELLOW}⚠${NC} $ws (already exists)"
    fi
done
echo ""

# Copy configuration files
echo -e "${YELLOW}📋 Copying configuration files...${NC}"
for ws in "${WORKSPACES[@]}"; do
    src_path="$SCRIPT_DIR/$ws"
    dest_path="$OPENCLAW_DIR/$ws"
    
    if [ -f "$src_path/SOUL.md" ]; then
        cp "$src_path/SOUL.md" "$dest_path/"
        echo -e "  ${GREEN}✓${NC} $ws/SOUL.md"
    else
        echo -e "  ${RED}✗${NC} $ws/SOUL.md (not found in source)"
    fi
    
    if [ -f "$src_path/AGENTS.md" ]; then
        cp "$src_path/AGENTS.md" "$dest_path/"
        echo -e "  ${GREEN}✓${NC} $ws/AGENTS.md"
    else
        echo -e "  ${RED}✗${NC} $ws/AGENTS.md (not found in source)"
    fi
done
echo ""

# Register agents with OpenClaw
echo -e "${YELLOW}🤖 Registering agents with OpenClaw...${NC}"

register_agent() {
    local name="$1"
    local workspace="$2"
    
    if openclaw agents list 2>/dev/null | grep -q "$name"; then
        echo -e "  ${YELLOW}⚠${NC} $name (already registered)"
    else
        if openclaw agents add "$name" --workspace "$workspace" 2>/dev/null; then
            echo -e "  ${GREEN}✓${NC} $name"
        else
            echo -e "  ${RED}✗${NC} $name (failed to register)"
        fi
    fi
}

register_agent "reits-expert" "$OPENCLAW_DIR/workspace-reits-expert"
register_agent "energy-asset-analyst" "$OPENCLAW_DIR/workspace-energy-asset-analyst"
register_agent "utility-asset-analyst" "$OPENCLAW_DIR/workspace-utility-asset-analyst"
register_agent "transport-asset-analyst" "$OPENCLAW_DIR/workspace-transport-asset-analyst"
register_agent "property-asset-analyst" "$OPENCLAW_DIR/workspace-property-asset-analyst"
register_agent "housing-asset-analyst" "$OPENCLAW_DIR/workspace-housing-asset-analyst"
register_agent "ops-supervisor" "$OPENCLAW_DIR/workspace-ops-supervisor"
register_agent "struct-designer" "$OPENCLAW_DIR/workspace-struct-designer"
register_agent "market-researcher" "$OPENCLAW_DIR/workspace-market-researcher"
register_agent "esg-analyst" "$OPENCLAW_DIR/workspace-esg-analyst"
register_agent "report-writer" "$OPENCLAW_DIR/workspace-report-writer"
echo ""

# Configure master agent permissions
echo -e "${YELLOW}⚙️  Configuring master agent permissions...${NC}"

# Resolve master agent index dynamically (do not assume reits-expert is at index 0,
# since the user may have pre-existing agents registered ahead of it).
MASTER_INDEX=""

# Strategy 1: parse `openclaw config get agents.list` as JSON via jq
if command -v jq &> /dev/null; then
    AGENTS_JSON=$(openclaw config get agents.list 2>/dev/null || echo "")
    if [ -n "$AGENTS_JSON" ]; then
        IDX=$(echo "$AGENTS_JSON" | jq -r 'map(.agentId == "reits-expert") | index(true) // empty' 2>/dev/null)
        if [ -n "$IDX" ] && [[ "$IDX" =~ ^[0-9]+$ ]]; then
            MASTER_INDEX=$IDX
        fi
    fi
fi

# Strategy 2: fall back to scraping `openclaw agents list` row position
if [ -z "$MASTER_INDEX" ]; then
    LINE_NO=$(openclaw agents list 2>/dev/null | grep -n "^[[:space:]]*reits-expert\b\|[[:space:]]reits-expert\b" | head -1 | cut -d: -f1)
    if [ -n "$LINE_NO" ] && [[ "$LINE_NO" =~ ^[0-9]+$ ]]; then
        MASTER_INDEX=$((LINE_NO - 1))
    fi
fi

# Strategy 3: last-resort default
if [ -z "$MASTER_INDEX" ] || ! [[ "$MASTER_INDEX" =~ ^[0-9]+$ ]]; then
    echo -e "${YELLOW}⚠️  Could not auto-detect master agent index. Defaulting to 0.${NC}"
    echo -e "${YELLOW}    If reits-expert is not at index 0, run the manual command shown below.${NC}"
    MASTER_INDEX=0
else
    echo -e "${GREEN}   Detected reits-expert at index $MASTER_INDEX${NC}"
fi

SUBAGENTS='["energy-asset-analyst","utility-asset-analyst","transport-asset-analyst","property-asset-analyst","housing-asset-analyst","ops-supervisor","struct-designer","market-researcher","esg-analyst","report-writer"]'

if openclaw config set "agents.list[$MASTER_INDEX].subagents.allowAgents" "$SUBAGENTS" --json 2>/dev/null; then
    echo -e "${GREEN}✅ Master agent permissions configured (index=$MASTER_INDEX)${NC}"
else
    echo -e "${YELLOW}⚠️  Could not configure permissions automatically${NC}"
    echo -e "${YELLOW}   Please run manually:${NC}"
    echo -e "   ${BLUE}openclaw config set agents.list[$MASTER_INDEX].subagents.allowAgents '$SUBAGENTS' --json${NC}"
fi
echo ""

# Configure routing
echo -e "${YELLOW}🌐 Configuring routing...${NC}"
if openclaw config set bindings '[{"agentId": "reits-expert", "match": {}}]' --json 2>/dev/null; then
    echo -e "${GREEN}✅ Routing configured${NC}"
else
    echo -e "${YELLOW}⚠️  Could not configure routing automatically${NC}"
    echo -e "${YELLOW}   Please run manually:${NC}"
    echo -e "   ${BLUE}openclaw config set bindings '[{\"agentId\": \"reits-expert\", \"match\": {}}]' --json${NC}"
fi
echo ""

# Verify installation
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}  Installation Summary${NC}"
echo -e "${BLUE}================================================${NC}"
echo ""
echo -e "${GREEN}✅ REITs Expert System installation complete!${NC}"
echo ""

# Show registered agents
echo -e "${YELLOW}📊 Registered Agents:${NC}"
openclaw agents list 2>/dev/null || echo -e "${YELLOW}   (Unable to list agents - please check manually)${NC}"
echo ""

# Test instructions
echo -e "${BLUE}🧪 Test Commands:${NC}"
echo -e "   ${GREEN}openclaw agents list${NC}                          # List all agents"
echo -e "   ${GREEN}openclaw gateway status${NC}                       # Check gateway status"
echo -e "   ${GREEN}openclaw chat --agent reits-expert${NC}            # Start chat with master agent"
echo ""
echo -e "${BLUE}💡 Example Test Query:${NC}"
echo -e "   ${YELLOW}'请对某10万千瓦风电项目进行估值分析'${NC}"
echo -e "   ${YELLOW}'分析某产业园区REITs的存续期管理方案'${NC}"
echo ""
echo -e "${GREEN}🎉 Setup complete! Happy analyzing!${NC}"
