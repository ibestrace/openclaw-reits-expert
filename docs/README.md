# 文档说明

> 此项目的权威 Agent 定义文件已全部迁移至 `workspace-<agent-id>/` 目录下。
>
> 请勿直接使用本目录下的任何历史文件作为配置来源。

## 权威文件位置

每个 Agent 的完整定义包含两个文件：

| 文件 | 作用 |
|------|------|
| `workspace-<agent-id>/SOUL.md` | Agent 身份、领域知识、资产覆盖范围、输出规范 |
| `workspace-<agent-id>/AGENTS.md` | 调度规则、行为规范、回传格式、异常处理 |

## 快速导航

- **主 Agent**: [`workspace-reits-expert/`](../workspace-reits-expert/)
- **行业分析师**:
  - 能源: [`workspace-energy-asset-analyst/`](../workspace-energy-asset-analyst/)
  - 市政: [`workspace-utility-asset-analyst/`](../workspace-utility-asset-analyst/)
  - 交通物流: [`workspace-transport-asset-analyst/`](../workspace-transport-asset-analyst/)
  - 产业: [`workspace-property-asset-analyst/`](../workspace-property-asset-analyst/)
  - 保租房: [`workspace-housing-asset-analyst/`](../workspace-housing-asset-analyst/)
- **功能专家**:
  - 运营督导: [`workspace-ops-supervisor/`](../workspace-ops-supervisor/)
  - 结构设计: [`workspace-struct-designer/`](../workspace-struct-designer/)
  - 市场研究: [`workspace-market-researcher/`](../workspace-market-researcher/)
  - ESG 分析: [`workspace-esg-analyst/`](../workspace-esg-analyst/)
  - 报告撰写: [`workspace-report-writer/`](../workspace-report-writer/)

## 安装与使用

请参考仓库根目录的 [`README.md`](../README.md) 和 [`install.sh`](../install.sh) / [`install.ps1`](../install.ps1)。
