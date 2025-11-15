<#
.SYNOPSIS
    WinVibe - Windows Auto-Setup Tool
.DESCRIPTION
    Tool tự động hóa việc tối ưu, cài đặt phần mềm và dọn dẹp Windows
.NOTES
    Author: WinVibe Team
    Version: 1.0.0
    Requires: PowerShell 7+, Windows 10/11, Admin Rights
#>

#Requires -Version 7.0

# ============================================================================
# SCRIPT CONFIGURATION
# ============================================================================
$ErrorActionPreference = "Stop"
$ScriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigPath = Join-Path $ScriptPath "config"
$ModulesPath = Join-Path $ScriptPath "modules"

# ============================================================================
# ADMIN PRIVILEGE CHECK
# ============================================================================
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Request-AdminPrivilege {
    if (-not (Test-Administrator)) {
        Write-Host "⚠️  Tool cần quyền Administrator để chạy!" -ForegroundColor Yellow
        Write-Host "🔄 Đang yêu cầu nâng quyền (UAC)..." -ForegroundColor Cyan

        $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$($MyInvocation.MyCommand.Path)`""
        Start-Process pwsh -Verb RunAs -ArgumentList $arguments
        exit
    }
}

# ============================================================================
# LOGGING FUNCTIONS
# ============================================================================
function Start-WinVibeLogging {
    param (
        [string]$LogPath = "C:\WinVibe_Log.txt"
    )

    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
        $logFile = $LogPath -replace "\.txt$", "_$timestamp.txt"

        Start-Transcript -Path $logFile -Append -ErrorAction Stop
        Write-Host "📝 Logging started: $logFile" -ForegroundColor Green
        return $logFile
    }
    catch {
        Write-Warning "Không thể khởi tạo logging: $_"
        return $null
    }
}

# ============================================================================
# CONFIGURATION LOADER
# ============================================================================
function Get-WinVibeConfig {
    param (
        [string]$ConfigFile = "config.json"
    )

    $configFilePath = Join-Path $ConfigPath $ConfigFile

    if (-not (Test-Path $configFilePath)) {
        throw "Không tìm thấy file cấu hình: $configFilePath"
    }

    try {
        $config = Get-Content $configFilePath -Raw | ConvertFrom-Json
        return $config
    }
    catch {
        throw "Lỗi khi đọc file cấu hình: $_"
    }
}

# ============================================================================
# MODULE LOADER
# ============================================================================
function Import-WinVibeModules {
    $moduleFiles = @(
        "Clean.psm1",
        "Optimize.psm1",
        "Install.psm1"
    )

    foreach ($moduleFile in $moduleFiles) {
        $modulePath = Join-Path $ModulesPath $moduleFile

        if (Test-Path $modulePath) {
            try {
                Import-Module $modulePath -Force -ErrorAction Stop
                Write-Host "✅ Module loaded: $moduleFile" -ForegroundColor Green
            }
            catch {
                Write-Warning "Không thể load module $moduleFile: $_"
            }
        }
        else {
            Write-Warning "Không tìm thấy module: $modulePath"
        }
    }
}

# ============================================================================
# MENU DISPLAY
# ============================================================================
function Show-WinVibeMenu {
    Clear-Host
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
    Write-Host "║                                                           ║" -ForegroundColor Cyan
    Write-Host "║                    🚀 WINVIBE v1.0                        ║" -ForegroundColor Cyan
    Write-Host "║         Windows Auto-Setup & Optimization Tool            ║" -ForegroundColor Cyan
    Write-Host "║                                                           ║" -ForegroundColor Cyan
    Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] 🔧 Tối ưu Windows (Optimize)" -ForegroundColor Yellow
    Write-Host "      └─ Debloat, Registry tweaks, Dynamic Power Plan" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [2] 📦 Cài đặt Phần mềm (Install)" -ForegroundColor Yellow
    Write-Host "      └─ Tự động cài đặt qua Winget + Post-config" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [3] 🧹 Dọn dẹp Hệ thống (Clean)" -ForegroundColor Yellow
    Write-Host "      └─ Temp files, Cache, Windows Update cleanup" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [4] ⚡ Thực hiện TẤT CẢ (All-in-One)" -ForegroundColor Green
    Write-Host "      └─ Optimize → Install → Clean" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [0] ❌ Thoát (Exit)" -ForegroundColor Red
    Write-Host ""
    Write-Host "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Host ""
}

# ============================================================================
# MAIN EXECUTION FUNCTION
# ============================================================================
function Invoke-WinVibe {
    param (
        [switch]$Optimize,
        [switch]$Install,
        [switch]$Clean,
        [switch]$All
    )

    # Load configuration
    $config = Get-WinVibeConfig

    # Start logging if enabled
    if ($config.general.enableLogging) {
        $logFile = Start-WinVibeLogging -LogPath $config.general.logPath
    }

    Write-Host ""
    Write-Host "🚀 Bắt đầu WinVibe..." -ForegroundColor Cyan
    Write-Host "⏰ Thời gian: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Gray
    Write-Host ""

    try {
        # Execute Optimize
        if ($Optimize -or $All) {
            if ($config.modules.optimize.enabled) {
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
                Write-Host "🔧 BƯỚC 1: TỐI ƯU WINDOWS" -ForegroundColor Yellow
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
                Start-WindowsOptimization -ConfigPath $ConfigPath
            }
        }

        # Execute Install
        if ($Install -or $All) {
            if ($config.modules.install.enabled) {
                Write-Host ""
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
                Write-Host "📦 BƯỚC 2: CÀI ĐẶT PHẦN MỀM" -ForegroundColor Yellow
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
                Start-SoftwareInstallation -ConfigPath $ConfigPath
            }
        }

        # Execute Clean
        if ($Clean -or $All) {
            if ($config.modules.clean.enabled) {
                Write-Host ""
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
                Write-Host "🧹 BƯỚC 3: DỌN DẸP HỆ THỐNG" -ForegroundColor Yellow
                Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Cyan
                Start-SystemCleanup -ConfigPath $ConfigPath
            }
        }

        Write-Host ""
        Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║                                                           ║" -ForegroundColor Green
        Write-Host "║           ✅ HOÀN THÀNH! WinVibe đã chạy xong!            ║" -ForegroundColor Green
        Write-Host "║                                                           ║" -ForegroundColor Green
        Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""

        if ($logFile) {
            Write-Host "📝 Log file: $logFile" -ForegroundColor Cyan
        }
    }
    catch {
        Write-Host ""
        Write-Host "❌ LỖI: $_" -ForegroundColor Red
        Write-Host "Stack Trace: $($_.ScriptStackTrace)" -ForegroundColor DarkRed
    }
    finally {
        if ($config.general.enableLogging) {
            Stop-Transcript
        }
    }
}

# ============================================================================
# MENU HANDLER
# ============================================================================
function Start-MenuHandler {
    while ($true) {
        Show-WinVibeMenu
        $choice = Read-Host "Chọn chức năng (0-4)"

        switch ($choice) {
            "1" {
                Invoke-WinVibe -Optimize
                Read-Host "`nNhấn Enter để tiếp tục"
            }
            "2" {
                Invoke-WinVibe -Install
                Read-Host "`nNhấn Enter để tiếp tục"
            }
            "3" {
                Invoke-WinVibe -Clean
                Read-Host "`nNhấn Enter để tiếp tục"
            }
            "4" {
                Invoke-WinVibe -All
                Read-Host "`nNhấn Enter để tiếp tục"
            }
            "0" {
                Write-Host "`n👋 Tạm biệt! Cảm ơn đã sử dụng WinVibe." -ForegroundColor Cyan
                exit 0
            }
            default {
                Write-Host "`n⚠️  Lựa chọn không hợp lệ! Vui lòng chọn từ 0-4." -ForegroundColor Red
                Start-Sleep -Seconds 2
            }
        }
    }
}

# ============================================================================
# SCRIPT ENTRY POINT
# ============================================================================

# Check and request admin privilege
Request-AdminPrivilege

# Set execution policy for this session
Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass -Force

# Import modules
Import-WinVibeModules

# Start menu
Start-MenuHandler
