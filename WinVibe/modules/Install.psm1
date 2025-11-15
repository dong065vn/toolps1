<#
.SYNOPSIS
    Install Module - Cài đặt phần mềm tự động
.DESCRIPTION
    Module thực hiện cài đặt phần mềm qua Winget và chạy post-install configuration
.NOTES
    Version: 1.0.0
#>

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Test-WingetAvailable {
    <#
    .SYNOPSIS
        Kiểm tra xem Winget có sẵn hay không
    #>

    try {
        $wingetVersion = winget --version 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ Winget đã sẵn sàng (Version: $wingetVersion)" -ForegroundColor Green
            return $true
        }
        else {
            return $false
        }
    }
    catch {
        return $false
    }
}

function Install-Winget {
    <#
    .SYNOPSIS
        Cài đặt Winget nếu chưa có
    #>

    Write-Host "  📦 Winget chưa được cài đặt. Đang cài đặt..." -ForegroundColor Yellow

    try {
        # Download and install App Installer (contains winget)
        $progressPreference = 'SilentlyContinue'

        Write-Host "  🔽 Đang tải App Installer..." -ForegroundColor Cyan

        $appInstallerUrl = "https://aka.ms/getwinget"
        $appInstallerPath = "$env:TEMP\Microsoft.DesktopAppInstaller.msixbundle"

        Invoke-WebRequest -Uri $appInstallerUrl -OutFile $appInstallerPath -UseBasicParsing

        Write-Host "  📦 Đang cài đặt App Installer..." -ForegroundColor Cyan
        Add-AppxPackage -Path $appInstallerPath -ErrorAction Stop

        Write-Host "  ✅ Winget đã được cài đặt thành công!" -ForegroundColor Green

        # Cleanup
        Remove-Item $appInstallerPath -Force -ErrorAction SilentlyContinue

        return $true
    }
    catch {
        Write-Warning "  ⚠️  Không thể cài đặt Winget tự động: $_"
        Write-Host ""
        Write-Host "  ℹ️  Vui lòng cài đặt Winget thủ công từ Microsoft Store (App Installer)" -ForegroundColor Yellow
        return $false
    }
}

function Test-SoftwareInstalled {
    <#
    .SYNOPSIS
        Kiểm tra xem phần mềm đã được cài đặt hay chưa
    .PARAMETER WingetId
        Winget package ID
    #>

    param (
        [string]$WingetId
    )

    try {
        $output = winget list --id $WingetId --exact 2>&1

        if ($output -match $WingetId) {
            return $true
        }

        return $false
    }
    catch {
        return $false
    }
}

# ============================================================================
# INSTALLATION FUNCTIONS
# ============================================================================

function Install-Software {
    <#
    .SYNOPSIS
        Cài đặt một phần mềm qua Winget
    .PARAMETER WingetId
        Winget package ID
    .PARAMETER Name
        Tên hiển thị của phần mềm
    #>

    param (
        [string]$WingetId,
        [string]$Name
    )

    Write-Host ""
    Write-Host "  📦 Đang cài đặt: $Name" -ForegroundColor Cyan
    Write-Host "      └─ Winget ID: $WingetId" -ForegroundColor DarkGray

    try {
        # Check if already installed
        if (Test-SoftwareInstalled -WingetId $WingetId) {
            Write-Host "      ⏭️  Phần mềm đã được cài đặt, bỏ qua..." -ForegroundColor Yellow
            return @{
                Success = $true
                AlreadyInstalled = $true
                Name = $Name
            }
        }

        # Install via winget
        $arguments = @(
            "install",
            "--id", $WingetId,
            "--silent",
            "--accept-source-agreements",
            "--accept-package-agreements",
            "--disable-interactivity"
        )

        Write-Host "      🔨 Đang cài đặt..." -ForegroundColor Cyan

        $process = Start-Process -FilePath "winget" -ArgumentList $arguments -Wait -PassThru -NoNewWindow

        if ($process.ExitCode -eq 0) {
            Write-Host "      ✅ Cài đặt thành công: $Name" -ForegroundColor Green
            return @{
                Success = $true
                AlreadyInstalled = $false
                Name = $Name
            }
        }
        else {
            Write-Warning "      ⚠️  Cài đặt thất bại (Exit code: $($process.ExitCode))"
            return @{
                Success = $false
                AlreadyInstalled = $false
                Name = $Name
                Error = "Exit code: $($process.ExitCode)"
            }
        }
    }
    catch {
        Write-Warning "      ⚠️  Lỗi khi cài đặt: $_"
        return @{
            Success = $false
            AlreadyInstalled = $false
            Name = $Name
            Error = $_
        }
    }
}

function Invoke-PostInstallScript {
    <#
    .SYNOPSIS
        Chạy script cấu hình sau khi cài đặt
    .PARAMETER ScriptPath
        Đường dẫn đến post-install script
    .PARAMETER SoftwareName
        Tên phần mềm
    #>

    param (
        [string]$ScriptPath,
        [string]$SoftwareName
    )

    if ([string]::IsNullOrWhiteSpace($ScriptPath)) {
        return
    }

    Write-Host "      🔧 Chạy post-install configuration..." -ForegroundColor Cyan

    # Get full path
    $scriptDir = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
    $fullScriptPath = Join-Path $scriptDir $ScriptPath

    if (-not (Test-Path $fullScriptPath)) {
        Write-Warning "      ⚠️  Không tìm thấy post-install script: $fullScriptPath"
        return
    }

    try {
        # Execute post-install script
        & $fullScriptPath

        Write-Host "      ✅ Post-install configuration hoàn thành" -ForegroundColor Green
    }
    catch {
        Write-Warning "      ⚠️  Lỗi khi chạy post-install script: $_"
    }
}

# ============================================================================
# CLEANUP FUNCTIONS
# ============================================================================

function Clear-WingetCache {
    <#
    .SYNOPSIS
        Dọn dẹp cache của Winget
    #>

    Write-Host ""
    Write-Host "  🧹 Dọn dẹp Winget cache..." -ForegroundColor Yellow

    try {
        # Reset winget source
        winget source reset --force 2>&1 | Out-Null

        # Clear temp files
        $wingetTemp = "$env:LOCALAPPDATA\Packages\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe\LocalCache"

        if (Test-Path $wingetTemp) {
            $sizeBefore = (Get-ChildItem -Path $wingetTemp -Recurse -Force -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum / 1MB

            Get-ChildItem -Path $wingetTemp -Recurse -Force -ErrorAction SilentlyContinue |
                Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

            Write-Host "      ✅ Đã dọn dẹp cache (Giải phóng: $([math]::Round($sizeBefore, 2)) MB)" -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "      ⚠️  Lỗi khi dọn cache: $_"
    }
}

# ============================================================================
# MAIN EXPORT FUNCTION
# ============================================================================

function Start-SoftwareInstallation {
    <#
    .SYNOPSIS
        Hàm chính để cài đặt phần mềm
    .PARAMETER ConfigPath
        Đường dẫn đến thư mục config
    #>

    param (
        [string]$ConfigPath
    )

    Write-Host ""
    Write-Host "📦 Bắt đầu cài đặt phần mềm..." -ForegroundColor Cyan
    Write-Host ""

    # Check and install Winget
    if (-not (Test-WingetAvailable)) {
        $installed = Install-Winget

        if (-not $installed) {
            Write-Host ""
            Write-Host "❌ Không thể tiếp tục mà không có Winget" -ForegroundColor Red
            return
        }
    }

    # Load software list
    $softwareListFile = Join-Path $ConfigPath "software_list.json"

    if (-not (Test-Path $softwareListFile)) {
        Write-Warning "Không tìm thấy danh sách phần mềm: $softwareListFile"
        return
    }

    try {
        $softwareList = Get-Content $softwareListFile -Raw | ConvertFrom-Json
        Write-Host "  📋 Tìm thấy $($softwareList.Count) phần mềm trong danh sách" -ForegroundColor Cyan
        Write-Host ""
    }
    catch {
        Write-Host "❌ Lỗi khi đọc danh sách phần mềm: $_" -ForegroundColor Red
        return
    }

    # Sort by priority
    $softwareList = $softwareList | Sort-Object -Property priority

    # Installation statistics
    $stats = @{
        Total = $softwareList.Count
        Installed = 0
        Skipped = 0
        Failed = 0
    }

    # Install each software
    foreach ($software in $softwareList) {
        Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray

        $result = Install-Software -WingetId $software.wingetId -Name $software.name

        if ($result.Success) {
            if ($result.AlreadyInstalled) {
                $stats.Skipped++
            }
            else {
                $stats.Installed++

                # Run post-install script if available
                if ($software.postInstallScript) {
                    Invoke-PostInstallScript -ScriptPath $software.postInstallScript -SoftwareName $software.name
                }
            }
        }
        else {
            $stats.Failed++
        }

        Start-Sleep -Milliseconds 500
    }

    # Cleanup
    Clear-WingetCache

    # Display summary
    Write-Host ""
    Write-Host "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "║      ✅ CÀI ĐẶT PHẦN MỀM HOÀN THÀNH!                     ║" -ForegroundColor Green
    Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "  📊 Thống kê:" -ForegroundColor Cyan
    Write-Host "      📦 Tổng số: $($stats.Total)" -ForegroundColor White
    Write-Host "      ✅ Đã cài: $($stats.Installed)" -ForegroundColor Green
    Write-Host "      ⏭️  Bỏ qua: $($stats.Skipped)" -ForegroundColor Yellow

    if ($stats.Failed -gt 0) {
        Write-Host "      ❌ Thất bại: $($stats.Failed)" -ForegroundColor Red
    }

    Write-Host ""

    # Recommend restart if needed
    if ($stats.Installed -gt 0) {
        Write-Host "  ℹ️  Khuyến nghị: Khởi động lại máy tính để hoàn tất cài đặt" -ForegroundColor Yellow
        Write-Host ""
    }
}

# ============================================================================
# MODULE EXPORTS
# ============================================================================

Export-ModuleMember -Function @(
    'Start-SoftwareInstallation',
    'Test-WingetAvailable',
    'Install-Winget',
    'Install-Software',
    'Invoke-PostInstallScript',
    'Clear-WingetCache'
)
