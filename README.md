# OpenClaw REITs Expert System

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

> A professional multi-agent system for China's Public REITs (Real Estate Investment Trusts) and real estate securitization, built on [OpenClaw](https://github.com/openclaw).
>
> **Updated for 2025-2026 regulatory framework**: Covers the July 2024 normalization notice, the 2025 industry scope expansion (data centers, urban renewal, specialized warehouses), and the December 2025 commercial REITs pilot (malls, hotels, offices).

## System Overview

This is a **multi-agent expert system** specializing in China's public REITs and real estate securitization full lifecycle management:

- **1 Master Agent**: `reits-expert` — The central orchestrator for task decomposition, complexity assessment, asset classification, and result integration
- **10 Sub-Agents**: Including 5 industry-vertical asset analysts + operations supervisor + structure designer + market researcher + ESG analyst + report writer

### Agent Architecture

```
┌─────────────────────────────────────────────────────┐
│              Gateway / User Interface                │
└────────────────────┬────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────┐
│              reits-expert (Master)                   │
│    REITs Senior Expert · Central Orchestrator       │
└──────┬─────┬─────┬─────┬─────┬─────┬─────┬─────┬───┘
       │     │     │     │     │     │     │     │
┌──────▼──┐ ┌▼────┐ ┌▼────┐ ┌▼────┐ ┌▼────┐ ┌▼────┐
│energy   │ │utility│ │transport│ │property│ │housing│
│-analyst │ │-analyst│ │-analyst │ │-analyst│ │-analyst│
└─────────┘ └──────┘ └───────┘ └───────┘ └───────┘
       │     │     │     │     │
┌──────▼─────▼─────▼─────▼─────▼─────────────────────┐
│     ops-supervisor · struct-designer               │
│     market-researcher · esg-analyst                │
│              report-writer                         │
└────────────────────────────────────────────────────┘
```

### Industry Coverage

| Agent                     | Asset Classes                                                  |
| ------------------------- | -------------------------------------------------------------- |
| `energy-asset-analyst`    | Wind power, PV, Hydro, Gas-fired power, Energy storage         |
| `utility-asset-analyst`   | Water supply, Wastewater, Heating, Gas supply, Waste-to-energy |
| `transport-asset-analyst` | Highways, Metro/Rail, Ports, Logistics warehouses              |
| `property-asset-analyst`  | Industrial parks, Data centers, Malls, Offices, Hotels, Urban renewal |
| `housing-asset-analyst`   | Affordable rental housing, Long-term rental apartments         |

**New in 2025 scope expansion**: Data centers, urban heating, farm produce markets, urban renewal projects, and specialized warehouses are now explicitly eligible under the NDRC 2025 Industry Scope List. Commercial REITs (malls, hotels, offices) launched pilot in December 2025.

## Installation

### Prerequisites

- [OpenClaw](https://github.com/openclaw) installed and configured
- Git (for cloning)

### Method 1: Quick Install (Recommended)

Clone this repository and run the install script:

**Linux/macOS:**

```bash
git clone https://github.com/ZHANGWEI232/openclaw-reits-expert.git
cd openclaw-reits-expert
chmod +x install.sh
./install.sh
```

**Windows (PowerShell):**

```powershell
git clone https://github.com/ZHANGWEI232/openclaw-reits-expert.git
cd openclaw-reits-expert
.\install.ps1
```

### Method 2: Manual Installation

1. **Clone the repository:**

```bash
git clone https://github.com/ZHANGWEI232/openclaw-reits-expert.git
cd openclaw-reits-expert
```

2. **Copy workspace directories to OpenClaw:**

```bash
# Linux/macOS
cp -r workspace-* ~/.openclaw/

# Windows PowerShell
Copy-Item -Path "workspace-*" -Destination "$env:USERPROFILE\.openclaw\" -Recurse -Force
```

3. **Register all agents:**

```bash
openclaw agents add reits-expert --workspace ~/.openclaw/workspace-reits-expert
openclaw agents add energy-asset-analyst --workspace ~/.openclaw/workspace-energy-asset-analyst
openclaw agents add utility-asset-analyst --workspace ~/.openclaw/workspace-utility-asset-analyst
openclaw agents add transport-asset-analyst --workspace ~/.openclaw/workspace-transport-asset-analyst
openclaw agents add property-asset-analyst --workspace ~/.openclaw/workspace-property-asset-analyst
openclaw agents add housing-asset-analyst --workspace ~/.openclaw/workspace-housing-asset-analyst
openclaw agents add ops-supervisor --workspace ~/.openclaw/workspace-ops-supervisor
openclaw agents add struct-designer --workspace ~/.openclaw/workspace-struct-designer
openclaw agents add market-researcher --workspace ~/.openclaw/workspace-market-researcher
openclaw agents add esg-analyst --workspace ~/.openclaw/workspace-esg-analyst
openclaw agents add report-writer --workspace ~/.openclaw/workspace-report-writer
```

4. **Configure master agent permissions:**

```bash
openclaw config set agents.list[0].subagents.allowAgents '["energy-asset-analyst","utility-asset-analyst","transport-asset-analyst","property-asset-analyst","housing-asset-analyst","ops-supervisor","struct-designer","market-researcher","esg-analyst","report-writer"]' --json
```

5. **Configure routing:**

```bash
openclaw config set bindings '[{"agentId": "reits-expert", "match": {}}]' --json
```

### Method 3: OpenClaw Plugin Install (Future)

If OpenClaw supports plugin installation from GitHub:

```bash
openclaw plugins install github.com/ZHANGWEI232/openclaw-reits-expert
```

## Verification

After installation, verify the setup:

```bash
# List all agents
openclaw agents list

# Check gateway status
openclaw gateway status

# Test with a simple query
openclaw chat --agent reits-expert
# Then type: "请对某10万千瓦风电项目进行估值分析"
```

## Project Structure

```
openclaw-reits-expert/
├── README.md                              # This file
├── install.sh                             # Linux/macOS install script
├── install.ps1                            # Windows install script
├── openclaw.json                          # OpenClaw configuration template
│
├── workspace-reits-expert/                # Master Agent
│   ├── SOUL.md                            # Identity & capabilities
│   └── AGENTS.md                          # Orchestration rules
│
├── workspace-energy-asset-analyst/        # Energy Asset Analyst
│   ├── SOUL.md
│   └── AGENTS.md
│
├── workspace-utility-asset-analyst/       # Utility Asset Analyst
│   ├── SOUL.md
│   └── AGENTS.md
│
├── workspace-transport-asset-analyst/     # Transport Asset Analyst
│   ├── SOUL.md
│   └── AGENTS.md
│
├── workspace-property-asset-analyst/      # Property Asset Analyst
│   ├── SOUL.md
│   └── AGENTS.md
│
├── workspace-housing-asset-analyst/       # Housing Asset Analyst
│   ├── SOUL.md
│   └── AGENTS.md
│
├── workspace-ops-supervisor/              # Operations Supervisor
│   ├── SOUL.md
│   └── AGENTS.md
│
├── workspace-struct-designer/             # Structure Designer
│   ├── SOUL.md
│   └── AGENTS.md
│
├── workspace-market-researcher/           # Market Researcher
│   ├── SOUL.md
│   └── AGENTS.md
│
├── workspace-esg-analyst/                 # ESG Analyst
│   ├── SOUL.md
│   └── AGENTS.md
│
└── workspace-report-writer/               # Report Writer
    ├── SOUL.md
    └── AGENTS.md
```

## Configuration Details

### Asset Classification Matrix

When the master agent receives an asset valuation task, it automatically routes to the appropriate industry analyst based on keywords:

| Keywords                                            | Target Agent              |
| --------------------------------------------------- | ------------------------- |
| Wind, PV, Hydro, Power plant, Energy storage        | `energy-asset-analyst`    |
| Water supply, Sewage, Heating, Gas, Waste-to-energy | `utility-asset-analyst`   |
| Highway, Metro, Port, Logistics warehouse           | `transport-asset-analyst` |
| Industrial park, Data center, Mall, Office, Hotel   | `property-asset-analyst`  |
| Affordable housing, Rental apartment                | `housing-asset-analyst`   |

### Task Complexity Levels

1. **Simple tasks**: Master agent answers directly
2. **Medium tasks**: Dispatches 1-2 relevant sub-agents in parallel
3. **Complex tasks**: Assembles full team with parallel + sequential execution

### Compliance Red Lines

The following items must be reviewed by the master agent personally and cannot be delegated to sub-agents:

- Investor suitability assessment
- Related party transaction identification
- Rating downgrade response decisions
- Bondholder meeting requirements
- Tax compliance judgments
- Legal clause review
- Information disclosure compliance
- Asset disposal/repurchase decisions
- Expansion target selection
- Public investor protection terms

## Usage Examples

### Example 1: Asset Valuation

```
User: "请对某10万千瓦风电项目进行估值"

Master Agent (reits-expert):
  1. Identifies "风电" → routes to energy-asset-analyst
  2. Spawns market-researcher for comparable transactions
  3. Spawns report-writer for final report formatting
```

### Example 2: Full Lifecycle Analysis

```
User: "我有一个产业园项目拟申报公募REITs，请出具完整方案"

Master Agent:
  1. market-researcher: Market environment & policy analysis
  2. property-asset-analyst: Asset valuation & modeling
  3. struct-designer: Transaction structure design
  4. ops-supervisor: Ongoing management plan
  5. esg-analyst: ESG integration assessment
  6. report-writer: Compile final report
```

## License

MIT License - see [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## Acknowledgments

- Built for [OpenClaw](https://github.com/openclaw) multi-agent framework
- Inspired by China's public REITs market development

***

## 中文说明

### 系统简介

这是一个专注于中国公募REITs及不动产证券化领域的多Agent专家系统，基于OpenClaw框架构建。

**核心架构**：1个主Agent + 10个子Agent，覆盖REITs全生命周期（发行前→存续期→退出）。

**5大行业垂直分析师**：

- 能源类：风电、光伏、水电、燃气发电、储能
- 公用事业：供水、污水、供热、供气、垃圾焚烧
- 交通物流：高速、地铁、港口、物流仓储
- 不动产：产业园、数据中心、商业、办公、酒店
- 租赁住房：保租房、长租公寓

### 快速安装

```bash
git clone https://github.com/ZHANGWEI232/openclaw-reits-expert.git
cd openclaw-reits-expert
chmod +x install.sh
./install.sh
```

### 验证安装

```bash
openclaw agents list
openclaw chat --agent reits-expert
```

输入测试指令："请对某10万千瓦风电项目进行估值分析"

系统应自动识别资产类别并调度对应的energy-asset-analyst执行估值。

***

**Maintainer**: ZHANGWEI232\
**Version**: 1.0.0\
**Last Updated**: 2026-05-19
