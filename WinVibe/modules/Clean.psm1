<#
.SYNOPSIS
    Clean Module - Dọn dẹp hệ thống Windows
.DESCRIPTION
    Module thực hiện dọn dẹp temp files, cache, Windows Update, và tối ưu storage
.NOTES
    Version: 1.0.0
#>

# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

function Remove-PathSafely {
    param (
        [string]$Path,
        [switch]$Recurse
    )

    try {
        # Expand environment variables
        $expandedPath = [Environment]::ExpandEnvironmentVariables($Path)

        # Check if path exists
        if (-not (Test-Path $expandedPath)) {
            Write-Host "  ⏭️  Đường dẫn không tồn tại: $expandedPath" -ForegroundColor DarkGray
            return
        }

        # Get items to delete
        if ($Recurse) {
            $items = Get-ChildItem -Path $expandedPath -Recurse -Force -ErrorAction SilentlyContinue
        }
        else {
            $items = Get-ChildItem -Path $expandedPath -Force -ErrorAction SilentlyContinue
        }

        $totalSize = ($items | Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum / 1MB
        $itemCount = $items.Count

        if ($itemCount -eq 0) {
            Write-Host "  ⏭️  Thư mục trống: $expandedPath" -ForegroundColor DarkGray
            return
        }

        Write-Host "  🗑️  Đang xóa: $expandedPath" -ForegroundColor Cyan
        Write-Host "      └─ Items: $itemCount | Size: $([math]::Round($totalSize, 2)) MB" -ForegroundColor DarkGray

        # Delete items
        $items | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue

        Write-Host "  ✅ Hoàn thành: $expandedPath" -ForegroundColor Green
        return @{
            Path = $expandedPath
            DeletedItems = $itemCount
            FreedSpace = [math]::Round($totalSize, 2)
        }
    }
    catch {
        Write-Warning "  ⚠️  Lỗi khi xóa $expandedPath : $_"
        return $null
    }
}

function Get-FolderSize {
    param (
        [string]$Path
    )

    try {
        $expandedPath = [Environment]::ExpandEnvironmentVariables($Path)
        if (Test-Path $expandedPath) {
            $size = (Get-ChildItem -Path $expandedPath -Recurse -Force -ErrorAction SilentlyContinue |
                Measure-Object -Property Length -Sum -ErrorAction SilentlyContinue).Sum
            return [math]::Round($size / 1MB, 2)
        }
        return 0
    }
    catch {
        return 0
    }
}

# ============================================================================
# MAIN CLEANUP FUNCTIONS
# ============================================================================

function Clear-TemporaryFiles {
    <#
    .SYNOPSIS
        Dọn dẹp các file tạm thời của Windows và User
    #>

    Write-Host ""
    Write-Host "  📂 Dọn dẹp Temporary Files..." -ForegroundColor Yellow
    Write-Host ""

    $tempPaths = @(
        $env:TEMP,
        "C:\Windows\Temp",
        "C:\Windows\Prefetch",
        "$env:LOCALAPPDATA\Temp"
    )

    $totalFreed = 0

    foreach ($path in $tempPaths) {
        $result = Remove-PathSafely -Path $path -Recurse
        if ($result) {
            $totalFreed += $result.FreedSpace
        }
    }

    Write-Host ""
    Write-Host "  💾 Tổng dung lượng giải phóng: $([math]::Round($totalFreed, 2)) MB" -ForegroundColor Green
}

function Clear-WindowsUpdateCache {
    <#
    .SYNOPSIS
        Dọn dẹp cache của Windows Update
    #>

    Write-Host ""
    Write-Host "  🔄 Dọn dẹp Windows Update Cache..." -ForegroundColor Yellow
    Write-Host ""

    try {
        # Get size before cleanup
        $sizeBefore = Get-FolderSize -Path "C:\Windows\SoftwareDistribution\Download"
        Write-Host "  📊 Kích thước hiện tại: $sizeBefore MB" -ForegroundColor Cyan

        # Stop Windows Update service
        Write-Host "  ⏸️  Đang dừng Windows Update service..." -ForegroundColor Cyan
        Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2

        # Delete download cache
        $result = Remove-PathSafely -Path "C:\Windows\SoftwareDistribution\Download" -Recurse

        # Restart Windows Update service
        Write-Host "  ▶️  Đang khởi động lại Windows Update service..." -ForegroundColor Cyan
        Start-Service -Name wuauserv -ErrorAction SilentlyContinue

        if ($result) {
            Write-Host "  ✅ Đã giải phóng: $($result.FreedSpace) MB" -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "  ⚠️  Lỗi khi dọn Windows Update cache: $_"

        # Make sure to restart the service
        try {
            Start-Service -Name wuauserv -ErrorAction SilentlyContinue
        }
        catch { }
    }
}

function Clear-SystemComponents {
    <#
    .SYNOPSIS
        Dọn dẹp WinSxS và các component hệ thống
    #>

    Write-Host ""
    Write-Host "  🔧 Dọn dẹp System Components (WinSxS)..." -ForegroundColor Yellow
    Write-Host "  ⚠️  Quá trình này có thể mất vài phút..." -ForegroundColor DarkYellow
    Write-Host ""

    try {
        # Get WinSxS size before
        $winsxsSize = Get-FolderSize -Path "C:\Windows\WinSxS"
        Write-Host "  📊 Kích thước WinSxS hiện tại: $winsxsSize MB" -ForegroundColor Cyan

        # Run DISM cleanup
        Write-Host "  🔨 Đang chạy DISM cleanup..." -ForegroundColor Cyan
        $dismOutput = Dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-Host "  ✅ DISM cleanup hoàn thành!" -ForegroundColor Green

            # Get size after
            $winsxsSizeAfter = Get-FolderSize -Path "C:\Windows\WinSxS"
            $freed = $winsxsSize - $winsxsSizeAfter

            if ($freed -gt 0) {
                Write-Host "  💾 Đã giải phóng: $([math]::Round($freed, 2)) MB" -ForegroundColor Green
            }
        }
        else {
            Write-Warning "  ⚠️  DISM có thể gặp lỗi. Exit code: $LASTEXITCODE"
        }
    }
    catch {
        Write-Warning "  ⚠️  Lỗi khi chạy DISM: $_"
    }
}

function Clear-UserCache {
    <#
    .SYNOPSIS
        Dọn dẹp cache của các ứng dụng người dùng
    #>

    Write-Host ""
    Write-Host "  👤 Dọn dẹp User Cache..." -ForegroundColor Yellow
    Write-Host ""

    $cachePaths = @(
        # Thumbnail cache
        "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db",

        # IE/Edge cache
        "$env:LOCALAPPDATA\Microsoft\Windows\INetCache",
        "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache",

        # Chrome cache
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache",
        "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Code Cache",

        # Firefox cache
        "$env:LOCALAPPDATA\Mozilla\Firefox\Profiles\*.default*\cache2"
    )

    $totalFreed = 0

    foreach ($path in $cachePaths) {
        # Handle wildcard paths
        if ($path -match '\*') {
            $basePath = Split-Path $path -Parent
            $pattern = Split-Path $path -Leaf

            if (Test-Path $basePath) {
                $matchingPaths = Get-ChildItem -Path $basePath -Filter $pattern -Recurse -ErrorAction SilentlyContinue

                foreach ($matchPath in $matchingPaths) {
                    $result = Remove-PathSafely -Path $matchPath.FullName -Recurse
                    if ($result) {
                        $totalFreed += $result.FreedSpace
                    }
                }
            }
        }
        else {
            $result = Remove-PathSafely -Path $path -Recurse
            if ($result) {
                $totalFreed += $result.FreedSpace
            }
        }
    }

    Write-Host ""
    Write-Host "  💾 Tổng dung lượng giải phóng: $([math]::Round($totalFreed, 2)) MB" -ForegroundColor Green
}

function Invoke-DiskCleanup {
    <#
    .SYNOPSIS
        Chạy Disk Cleanup Manager
    #>

    Write-Host ""
    Write-Host "  🧹 Chạy Disk Cleanup Manager..." -ForegroundColor Yellow
    Write-Host ""

    try {
        # Check if cleanmgr exists
        $cleanmgrPath = "$env:SystemRoot\System32\cleanmgr.exe"

        if (-not (Test-Path $cleanmgrPath)) {
            Write-Warning "  ⚠️  Không tìm thấy cleanmgr.exe"
            return
        }

        # Set cleanup options via registry
        $stateFlags = "StateFlags0001"
        $volCachePath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches"

        # Enable cleanup options
        $cleanupOptions = @(
            "Active Setup Temp Folders",
            "Downloaded Program Files",
            "Internet Cache Files",
            "Recycle Bin",
            "Temporary Files",
            "Temporary Setup Files",
            "Thumbnail Cache",
            "Windows Error Reporting Files"
        )

        foreach ($option in $cleanupOptions) {
            $optionPath = Join-Path $volCachePath $option

            if (Test-Path $optionPath) {
                Set-ItemProperty -Path $optionPath -Name $stateFlags -Value 2 -Type DWord -ErrorAction SilentlyContinue
            }
        }

        # Run cleanmgr silently
        Write-Host "  🔨 Đang chạy Disk Cleanup..." -ForegroundColor Cyan
        Start-Process -FilePath $cleanmgrPath -ArgumentList "/sagerun:1" -Wait -WindowStyle Hidden

        Write-Host "  ✅ Disk Cleanup hoàn thành!" -ForegroundColor Green
    }
    catch {
        Write-Warning "  ⚠️  Lỗi khi chạy Disk Cleanup: $_"
    }
}

# ============================================================================
# MAIN EXPORT FUNCTION
# ============================================================================

function Start-SystemCleanup {
    <#
    .SYNOPSIS
        Hàm chính để thực hiện dọn dẹp hệ thống
    .PARAMETER ConfigPath
        Đường dẫn đến thư mục config
    #>

    param (
        [string]$ConfigPath
    )

    Write-Host ""
    Write-Host "🧹 Bắt đầu dọn dẹp hệ thống..." -ForegroundColor Cyan
    Write-Host ""

    # Load cleanup configuration
    $cleanupConfigFile = Join-Path $ConfigPath "cleanup_paths.json"

    if (-not (Test-Path $cleanupConfigFile)) {
        Write-Warning "Không tìm thấy file cấu hình: $cleanupConfigFile"
        Write-Host "Sử dụng cấu hình mặc định..." -ForegroundColor Yellow
    }
    else {
        try {
            $cleanupConfig = Get-Content $cleanupConfigFile -Raw | ConvertFrom-Json
            Write-Host "✅ Đã load cấu hình cleanup" -ForegroundColor Green
        }
        catch {
            Write-Warning "Lỗi khi đọc file cấu hình: $_"
        }
    }

    # Execute cleanup tasks
    $startTime = Get-Date

    try {
        # 1. Clean temporary files
        Clear-TemporaryFiles

        # 2. Clean Windows Update cache
        Clear-WindowsUpdateCache

        # 3. Clean user cache
        Clear-UserCache

        # 4. Clean system components (DISM)
        Clear-SystemComponents

        # 5. Run Disk Cleanup
        Invoke-DiskCleanup

        $endTime = Get-Date
        $duration = $endTime - $startTime

        Write-Host ""
        Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║         ✅ DỌN DẸP HỆ THỐNG HOÀN THÀNH!                  ║" -ForegroundColor Green
        Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
        Write-Host "⏱️  Thời gian thực hiện: $($duration.Minutes) phút $($duration.Seconds) giây" -ForegroundColor Cyan
        Write-Host ""
    }
    catch {
        Write-Host ""
        Write-Host "❌ Lỗi trong quá trình dọn dẹp: $_" -ForegroundColor Red
        throw
    }
}

# ============================================================================
# ALIASES TIẾNG VIỆT - Vietnamese Aliases
# ============================================================================

# Thiết lập các aliases tiếng Việt cho các functions
Set-Alias -Name 'BatDau-DonDepHeThong' -Value 'Start-SystemCleanup'
Set-Alias -Name 'DonDep-FileTamThoi' -Value 'Clear-TemporaryFiles'
Set-Alias -Name 'DonDep-BonhoDemWindowsUpdate' -Value 'Clear-WindowsUpdateCache'
Set-Alias -Name 'DonDep-ThanhPhanHeThong' -Value 'Clear-SystemComponents'
Set-Alias -Name 'DonDep-BonhoDemNguoiDung' -Value 'Clear-UserCache'
Set-Alias -Name 'ChayDonDep-OiaCung' -Value 'Invoke-DiskCleanup'

# ============================================================================
# MODULE EXPORTS
# ============================================================================

Export-ModuleMember -Function @(
    'Start-SystemCleanup',
    'Clear-TemporaryFiles',
    'Clear-WindowsUpdateCache',
    'Clear-SystemComponents',
    'Clear-UserCache',
    'Invoke-DiskCleanup'
)

# Export aliases tiếng Việt
Export-ModuleMember -Alias @(
    'BatDau-DonDepHeThong',
    'DonDep-FileTamThoi',
    'DonDep-BonhoDemWindowsUpdate',
    'DonDep-ThanhPhanHeThong',
    'DonDep-BonhoDemNguoiDung',
    'ChayDonDep-OiaCung'
)
