# =============================================================================
# CNCF Tech Advisor MCP - Installation Script for Claude Desktop (Windows)
# =============================================================================

Write-Host "🚀 CNCF Tech Advisor MCP - Claude Desktop Installation" -ForegroundColor Cyan
Write-Host "==================================================================" -ForegroundColor Cyan

# Configuration path
$configPath = "$env:APPDATA\Claude\claude_desktop_config.json"

Write-Host "📁 Configuration path: $configPath" -ForegroundColor Blue

# Create backup if file exists
if (Test-Path $configPath) {
    Write-Host "💾 Creating backup..." -ForegroundColor Yellow
    $backupPath = "$configPath.backup.$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $configPath $backupPath
    Write-Host "✅ Backup created: $backupPath" -ForegroundColor Green
}

# Create directory if it doesn't exist
$configDir = Split-Path $configPath -Parent
if (!(Test-Path $configDir)) {
    New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}

# Create/update configuration
Write-Host "⚙️  Creating configuration..." -ForegroundColor Yellow

# Check if cncf-tech-advisor already exists
if (Test-Path $configPath) {
    $content = Get-Content $configPath -Raw
    if ($content -match "cncf-tech-advisor") {
        Write-Host "⚠️  CNCF Tech Advisor MCP already configured" -ForegroundColor Yellow
        Write-Host "📝 Current configuration:" -ForegroundColor Blue
        $content | Select-String -Pattern "cncf-tech-advisor" -Context 2
    } else {
        Write-Host "➕ Adding to existing configuration..." -ForegroundColor Blue
        Write-Host "⚠️  Manual merge required. Please add the following to your existing configuration:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host @'
{
  "mcpServers": {
    "cncf-tech-advisor": {
      "command": "npx",
      "args": [
        "-y",
        "cncf-tech-advisor@latest"
      ]
    }
  }
}
'@ -ForegroundColor White
    }
} else {
    Write-Host "📝 Creating new configuration..." -ForegroundColor Blue

    $configContent = @'
{
  "mcpServers": {
    "cncf-tech-advisor": {
      "command": "npx",
      "args": [
        "-y",
        "cncf-tech-advisor@latest"
      ]
    }
  }
}
'@

    $configContent | Out-File -FilePath $configPath -Encoding UTF8
    Write-Host "✅ Configuration created" -ForegroundColor Green
}

Write-Host ""
Write-Host "🎉 Installation completed!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Cyan
Write-Host "1. Restart Claude Desktop" -ForegroundColor Blue
Write-Host "2. Open Claude Desktop and check for CNCF Tech Advisor tools" -ForegroundColor Blue
Write-Host "3. Try asking: 'Search for Kubernetes projects in CNCF'" -ForegroundColor Blue
Write-Host ""
Write-Host "🧪 Test the MCP server:" -ForegroundColor Cyan
Write-Host "   • 'Show me all CNCF orchestration projects'" -ForegroundColor White
Write-Host "   • 'Get details about the Prometheus project'" -ForegroundColor White
Write-Host "   • 'List all CNCF categories'" -ForegroundColor White
Write-Host "   • 'Find CNCF projects related to service mesh'" -ForegroundColor White
Write-Host ""
Write-Host "📚 Available tools:" -ForegroundColor Blue
Write-Host "   • search_cncf - Search CNCF projects" -ForegroundColor White
Write-Host "   • get_cncf_project - Get project details" -ForegroundColor White
Write-Host "   • list_cncf_categories - List categories" -ForegroundColor White
Write-Host "   • refresh_cncf_data - Refresh data from CNCF Landscape" -ForegroundColor White
Write-Host ""
Write-Host "✨ CNCF Tech Advisor MCP is now ready to use!" -ForegroundColor Green