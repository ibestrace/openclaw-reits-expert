# OpenClaw REITs Expert System - Installation Script (Windows PowerShell)
# This script automates the installation of the REITs expert multi-agent system

$ErrorActionPreference = "Stop"

# Configuration
$SCRIPT_DIR = Split-Path -Parent $MyInvocation.MyCommand.Path
$OPENCLAW_DIR = Join-Path $env:USERPROFILE ".openclaw"
$WORKSPACES = @(
    "workspace-reits-expert",
    "workspace-energy-asset-analyst",
    "workspace-utility-asset-analyst",
    "workspace-transport-asset-analyst",
    "workspace-property-asset-analyst",
    "workspace-housing-asset-analyst",
    "workspace-ops-supervisor",
    "workspace-struct-designer",
    "workspace-market-researcher",
    "workspace-esg-analyst",
    "workspace-report-writer"
)

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  OpenClaw REITs Expert System Installer" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Check if OpenClaw is installed
Write-Host "🔍 Checking OpenClaw installation..." -ForegroundColor Yellow
try {
    $version = openclaw --version 2>$null
    Write-Host "✅ OpenClaw found: $version" -ForegroundColor Green
} catch {
    Write-Host "❌ Error: OpenClaw is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install OpenClaw first: https://github.com/openclaw" -ForegroundColor Red
    exit 1
}
Write-Host ""

# Detect OpenClaw workspace directory
Write-Host "📁 Detecting OpenClaw workspace..." -ForegroundColor Yellow
if (Test-Path $OPENCLAW_DIR) {
    Write-Host "✅ Found OpenClaw directory: $OPENCLAW_DIR" -ForegroundColor Green
} else {
    Write-Host "⚠️  OpenClaw directory not found at $OPENCLAW_DIR" -ForegroundColor Yellow
    Write-Host "   Creating directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $OPENCLAW_DIR -Force | Out-Null
    Write-Host "✅ Created: $OPENCLAW_DIR" -ForegroundColor Green
}
Write-Host ""

# Create workspace directories
Write-Host "📂 Creating workspace directories..." -ForegroundColor Yellow
foreach ($ws in $WORKSPACES) {
    $wsPath = Join-Path $OPENCLAW_DIR $ws
    if (!(Test-Path $wsPath)) {
        New-Item -ItemType Directory -Path $wsPath -Force | Out-Null
        Write-Host "  ✓ $ws" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ $ws (already exists)" -ForegroundColor Yellow
    }
}
Write-Host ""

# Copy configuration files
Write-Host "📋 Copying configuration files..." -ForegroundColor Yellow
foreach ($ws in $WORKSPACES) {
    $srcPath = Join-Path $SCRIPT_DIR $ws
    $destPath = Join-Path $OPENCLAW_DIR $ws
    
    $soulFile = Join-Path $srcPath "SOUL.md"
    $agentsFile = Join-Path $srcPath "AGENTS.md"
    
    if (Test-Path $soulFile) {
        Copy-Item $soulFile $destPath -Force
        Write-Host "  ✓ $ws/SOUL.md" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $ws/SOUL.md (not found in source)" -ForegroundColor Red
    }
    
    if (Test-Path $agentsFile) {
        Copy-Item $agentsFile $destPath -Force
        Write-Host "  ✓ $ws/AGENTS.md" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $ws/AGENTS.md (not found in source)" -ForegroundColor Red
    }
}
Write-Host ""

# Register agents with OpenClaw
Write-Host "🤖 Registering agents with OpenClaw..." -ForegroundColor Yellow

function Register-Agent {
    param($Name, $Workspace)
    
    try {
        $agentsList = openclaw agents list 2>$null
        if ($agentsList -match $Name) {
            Write-Host "  ⚠ $Name (already registered)" -ForegroundColor Yellow
        } else {
            openclaw agents add $Name --workspace $Workspace 2>$null
            Write-Host "  ✓ $Name" -ForegroundColor Green
        }
    } catch {
        Write-Host "  ✗ $Name (failed to register)" -ForegroundColor Red
    }
}

Register-Agent -Name "reits-expert" -Workspace (Join-Path $OPENCLAW_DIR "workspace-reits-expert")
Register-Agent -Name "energy-asset-analyst" -Workspace (Join-Path $OPENCLAW_DIR "workspace-energy-asset-analyst")
Register-Agent -Name "utility-asset-analyst" -Workspace (Join-Path $OPENCLAW_DIR "workspace-utility-asset-analyst")
Register-Agent -Name "transport-asset-analyst" -Workspace (Join-Path $OPENCLAW_DIR "workspace-transport-asset-analyst")
Register-Agent -Name "property-asset-analyst" -Workspace (Join-Path $OPENCLAW_DIR "workspace-property-asset-analyst")
Register-Agent -Name "housing-asset-analyst" -Workspace (Join-Path $OPENCLAW_DIR "workspace-housing-asset-analyst")
Register-Agent -Name "ops-supervisor" -Workspace (Join-Path $OPENCLAW_DIR "workspace-ops-supervisor")
Register-Agent -Name "struct-designer" -Workspace (Join-Path $OPENCLAW_DIR "workspace-struct-designer")
Register-Agent -Name "market-researcher" -Workspace (Join-Path $OPENCLAW_DIR "workspace-market-researcher")
Register-Agent -Name "esg-analyst" -Workspace (Join-Path $OPENCLAW_DIR "workspace-esg-analyst")
Register-Agent -Name "report-writer" -Workspace (Join-Path $OPENCLAW_DIR "workspace-report-writer")
Write-Host ""

# Configure master agent permissions
Write-Host "⚙️  Configuring master agent permissions..." -ForegroundColor Yellow

# Resolve master agent index dynamically (do not assume reits-expert is at index 0,
# since the user may have pre-existing agents registered ahead of it).
$MASTER_INDEX = $null

# Strategy 1: parse `openclaw config get agents.list` as JSON
try {
    $agentsJson = openclaw config get agents.list 2>$null
    if ($agentsJson) {
        $agents = $agentsJson | ConvertFrom-Json -ErrorAction Stop
        for ($i = 0; $i -lt $agents.Count; $i++) {
            if ($agents[$i].agentId -eq "reits-expert") {
                $MASTER_INDEX = $i
                break
            }
        }
    }
} catch {
    # JSON parsing failed - fall through to strategy 2
}

# Strategy 2: fall back to scraping `openclaw agents list` row position
if ($null -eq $MASTER_INDEX) {
    try {
        $agentsList = openclaw agents list 2>$null
        if ($agentsList) {
            $lines = $agentsList -split "`n"
            for ($i = 0; $i -lt $lines.Count; $i++) {
                if ($lines[$i] -match "\breits-expert\b") {
                    $MASTER_INDEX = $i
                    break
                }
            }
        }
    } catch {
        # Both strategies failed
    }
}

# Strategy 3: last-resort default
if ($null -eq $MASTER_INDEX) {
    Write-Host "⚠️  Could not auto-detect master agent index. Defaulting to 0." -ForegroundColor Yellow
    Write-Host "   If reits-expert is not at index 0, run the manual command shown below." -ForegroundColor Yellow
    $MASTER_INDEX = 0
} else {
    Write-Host "   Detected reits-expert at index $MASTER_INDEX" -ForegroundColor Green
}

$SUBAGENTS = '["energy-asset-analyst","utility-asset-analyst","transport-asset-analyst","property-asset-analyst","housing-asset-analyst","ops-supervisor","struct-designer","market-researcher","esg-analyst","report-writer"]'

try {
    openclaw config set "agents.list[$MASTER_INDEX].subagents.allowAgents" $SUBAGENTS --json 2>$null
    Write-Host "✅ Master agent permissions configured (index=$MASTER_INDEX)" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Could not configure permissions automatically" -ForegroundColor Yellow
    Write-Host "   Please run manually:" -ForegroundColor Yellow
    Write-Host "   openclaw config set agents.list[$MASTER_INDEX].subagents.allowAgents '$SUBAGENTS' --json" -ForegroundColor Cyan
}
Write-Host ""

# Configure routing
Write-Host "🌐 Configuring routing..." -ForegroundColor Yellow
try {
    openclaw config set bindings '[{"agentId": "reits-expert", "match": {}}]' --json 2>$null
    Write-Host "✅ Routing configured" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Could not configure routing automatically" -ForegroundColor Yellow
    Write-Host "   Please run manually:" -ForegroundColor Yellow
    Write-Host "   openclaw config set bindings '[{`"agentId`": `"reits-expert`", `"match`": {}}]' --json" -ForegroundColor Cyan
}
Write-Host ""

# Verify installation
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "  Installation Summary" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✅ REITs Expert System installation complete!" -ForegroundColor Green
Write-Host ""

# Show registered agents
Write-Host "📊 Registered Agents:" -ForegroundColor Yellow
try {
    openclaw agents list 2>$null
} catch {
    Write-Host "   (Unable to list agents - please check manually)" -ForegroundColor Yellow
}
Write-Host ""

# Test instructions
Write-Host "🧪 Test Commands:" -ForegroundColor Cyan
Write-Host "   openclaw agents list" -ForegroundColor Green
Write-Host "   openclaw gateway status" -ForegroundColor Green
Write-Host "   openclaw chat --agent reits-expert" -ForegroundColor Green
Write-Host ""
Write-Host "💡 Example Test Query:" -ForegroundColor Cyan
Write-Host "   '请对某10万千瓦风电项目进行估值分析'" -ForegroundColor Yellow
Write-Host "   '分析某产业园区REITs的存续期管理方案'" -ForegroundColor Yellow
Write-Host ""
Write-Host "🎉 Setup complete! Happy analyzing!" -ForegroundColor Green

# Pause at the end (only in interactive shells; skip in CI / non-interactive runs)
$isInteractive = [Environment]::UserInteractive -and ($Host.Name -eq "ConsoleHost") -and (-not $env:CI)
if ($isInteractive) {
    Write-Host ""
    Write-Host "Press any key to continue..." -ForegroundColor Gray
    try {
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    } catch {
        # ReadKey not supported in this host (e.g. ISE) - skip silently
    }
}
