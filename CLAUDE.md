# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is the **OpenClaw REITs Expert System** — a multi-agent expert system for China's Public REITs (Real Estate Investment Trusts) and real estate securitization, built on the [OpenClaw](https://github.com/openclaw) multi-agent framework. The project is entirely prompt-engineering driven; there is no application code, only agent configuration files.

**Language**: Content is primarily in Chinese, targeting China's REITs market.

## Common Commands

This repository has no traditional build system (no `package.json`, `Makefile`, `pyproject.toml`, etc.). The primary operations are installation and configuration management via the `openclaw` CLI:

### Installation (for end users)

```bash
# Linux/macOS
chmod +x install.sh
./install.sh

# Windows PowerShell
.\install.ps1
```

### OpenClaw CLI Commands (requires `openclaw` installed)

```bash
# List all registered agents
openclaw agents list

# Check gateway status
openclaw gateway status

# Chat with the master agent
openclaw chat --agent reits-expert

# Register an agent manually
openclaw agents add <agent-id> --workspace <path>

# Set configuration values
openclaw config set <key> <value> --json
openclaw config get <key>
```

### Validation

There are currently no automated tests or linting. Verification is manual:

1. Run `install.sh` or `install.ps1` and confirm all agents register without errors.
2. Run `openclaw agents list` to verify all 11 agents appear.
3. Test with: `openclaw chat --agent reits-expert`, then query: `"请对某10万千瓦风电项目进行估值分析"`

## Architecture

### High-Level Structure

The system follows a **hub-and-spoke architecture** managed by the OpenClaw framework:

- **1 Master Agent**: `reits-expert` — central orchestrator for task decomposition, complexity assessment, asset classification, and result integration.
- **10 Sub-Agents**:
  - 5 **Industry-vertical asset analysts**: `energy-asset-analyst`, `utility-asset-analyst`, `transport-asset-analyst`, `property-asset-analyst`, `housing-asset-analyst`
  - 5 **Functional specialists**: `ops-supervisor`, `struct-designer`, `market-researcher`, `esg-analyst`, `report-writer`

The master agent is the sole entrypoint. All user messages route to it, and it dispatches sub-agents internally via `sessions_spawn()`.

### Workspace Pattern

Each agent lives in its own `workspace-<agent-id>/` directory containing exactly two files:

- **`SOUL.md`** — Agent identity, domain expertise, core capabilities, asset coverage, valuation frameworks, output style guidelines, and available skills.
- **`AGENTS.md`** — Orchestration rules: task routing logic, sub-agent dispatch rules, compliance red lines, result integration protocols, and behavioral constraints.

This split is intentional: `SOUL.md` defines "who I am and what I know," while `AGENTS.md` defines "how I operate and dispatch."

### Asset Classification Matrix

When the master agent receives an asset valuation task, it routes to the appropriate industry analyst based on keywords:

| Keywords | Target Agent |
|----------|-------------|
| 风电, 光伏, 水电, 储能, 新能源 | `energy-asset-analyst` |
| 供水, 污水, 供热, 供气, 垃圾焚烧 | `utility-asset-analyst` |
| 高速, 地铁, 港口, 物流园, 高标仓 | `transport-asset-analyst` |
| 产业园, 数据中心, 购物中心, 酒店 | `property-asset-analyst` |
| 保租房, 保障性租赁住房, 长租公寓 | `housing-asset-analyst` |

### Task Complexity Levels

1. **Simple**: Master agent answers directly.
2. **Medium**: Dispatches 1-2 relevant sub-agents in parallel.
3. **Complex**: Assembles full team with parallel + sequential execution.

### Compliance Red Lines

The following items must be reviewed by the master agent personally and cannot be delegated to sub-agents: investor suitability assessment, related party transaction identification, rating downgrade response decisions, bondholder meeting requirements, tax compliance judgments, legal clause review, information disclosure compliance, asset disposal/repurchase decisions, expansion target selection, and public investor protection terms.

## Configuration Files

- **`openclaw.json`** — OpenClaw configuration template defining the `agents.list` (with workspaces, models, and sub-agent permissions) and `bindings` (routing rules). The `${HOME}` placeholder must be replaced with an absolute path before use. The install scripts apply this configuration via `openclaw config set` commands rather than copying the file directly.
- **`install.sh` / `install.ps1`** — Cross-platform install scripts that copy workspace files to `~/.openclaw/`, register all agents, configure master agent sub-agent permissions, and set up routing bindings.

## Important Context

- **No code, tests, or CI**: This is a pure configuration/prompt repository. There are no unit tests, no linting tools, and no CI/CD pipelines.
- **Docs directory shadow files**: `docs/` contains earlier versions of agent definitions that may be out of sync with `workspace-*/` files. Treat `workspace-*/SOUL.md` and `workspace-*/AGENTS.md` as the authoritative sources.
- **Improvement audit available**: `IMPROVEMENT_SUGGESTIONS.md` contains a detailed third-party audit (dated 2026-05-03) cataloging issues including missing workspaces, duplicate content between SOUL.md/AGENTS.md, install script fragility, and recommended fixes. Review this file before making structural changes.
