<#
.SYNOPSIS
    Post-Install Configuration for Visual Studio Code
.DESCRIPTION
    Script tự động cấu hình VS Code sau khi cài đặt
.NOTES
    Version: 1.0.0
#>

Write-Host "  🔧 Configuring Visual Studio Code..." -ForegroundColor Cyan

try {
    # Tìm đường dẫn VS Code
    $vscodePath = Get-Command code -ErrorAction SilentlyContinue

    if (-not $vscodePath) {
        Write-Warning "      ⚠️  Không tìm thấy VS Code trong PATH. Có thể cần khởi động lại."
        return
    }

    # Cài đặt extensions phổ biến
    $extensions = @(
        "ms-python.python",                    # Python
        "ms-vscode.cpptools",                  # C/C++
        "ms-vscode.powershell",                # PowerShell
        "esbenp.prettier-vscode",              # Prettier
        "dbaeumer.vscode-eslint",              # ESLint
        "eamodio.gitlens",                     # GitLens
        "pkief.material-icon-theme",           # Material Icon Theme
        "github.copilot"                       # GitHub Copilot
    )

    Write-Host "      📦 Đang cài đặt extensions..." -ForegroundColor Cyan

    foreach ($ext in $extensions) {
        Write-Host "          └─ Installing: $ext" -ForegroundColor DarkGray
        code --install-extension $ext --force 2>&1 | Out-Null
    }

    # Tạo settings.json mẫu (nếu chưa có)
    $settingsPath = "$env:APPDATA\Code\User\settings.json"
    $settingsDir = Split-Path $settingsPath -Parent

    if (-not (Test-Path $settingsDir)) {
        New-Item -Path $settingsDir -ItemType Directory -Force | Out-Null
    }

    if (-not (Test-Path $settingsPath)) {
        $defaultSettings = @{
            "editor.fontSize" = 14
            "editor.fontFamily" = "Consolas, 'Courier New', monospace"
            "editor.tabSize" = 4
            "editor.wordWrap" = "on"
            "editor.minimap.enabled" = $true
            "files.autoSave" = "afterDelay"
            "terminal.integrated.fontSize" = 13
            "workbench.iconTheme" = "material-icon-theme"
            "git.autofetch" = $true
        } | ConvertTo-Json -Depth 10

        Set-Content -Path $settingsPath -Value $defaultSettings -Force
        Write-Host "      ✅ Đã tạo settings.json mặc định" -ForegroundColor Green
    }

    Write-Host "      ✅ VS Code configuration hoàn thành!" -ForegroundColor Green
}
catch {
    Write-Warning "      ⚠️  Lỗi khi cấu hình VS Code: $_"
}
