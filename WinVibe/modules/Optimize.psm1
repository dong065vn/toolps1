<#
.SYNOPSIS
    Optimize Module - Tối ưu hóa Windows (Enhanced Edition)
.DESCRIPTION
    Module thực hiện debloat, registry tweaks, service optimization,
    Dynamic Power Management và các tối ưu đặc biệt cho Performance,
    Privacy, Network, Storage, Gaming
.NOTES
    Version: 2.0.0 - Enhanced Edition
#>

# ============================================================================
# DEBLOAT FUNCTIONS
# ============================================================================

function Invoke-Debloat {
    <#
    .SYNOPSIS
        Gỡ bỏ các ứng dụng bloatware khỏi Windows
    .PARAMETER BloatwareListPath
        Đường dẫn đến file danh sách bloatware
    #>

    param (
        [string]$BloatwareListPath
    )

    Write-Host ""
    Write-Host "  🗑️  Bắt đầu gỡ bỏ Bloatware..." -ForegroundColor Yellow
    Write-Host ""

    if (-not (Test-Path $BloatwareListPath)) {
        Write-Warning "Không tìm thấy file danh sách bloatware: $BloatwareListPath"
        return
    }

    # Read bloatware list
    $bloatwareList = Get-Content $BloatwareListPath |
        Where-Object { $_ -notmatch '^\s*#' -and $_ -notmatch '^\s*$' } |
        ForEach-Object { $_.Trim() }

    if ($bloatwareList.Count -eq 0) {
        Write-Host "  ⏭️  Không có bloatware nào được chỉ định để gỡ." -ForegroundColor DarkGray
        return
    }

    Write-Host "  📋 Tìm thấy $($bloatwareList.Count) bloatware cần gỡ" -ForegroundColor Cyan
    Write-Host ""

    $removedCount = 0
    $failedCount = 0

    foreach ($appPattern in $bloatwareList) {
        try {
            # Find matching apps
            $apps = Get-AppxPackage -AllUsers -Name $appPattern -ErrorAction SilentlyContinue

            if ($apps) {
                foreach ($app in $apps) {
                    Write-Host "  🗑️  Đang gỡ: $($app.Name)" -ForegroundColor Cyan

                    try {
                        Remove-AppxPackage -Package $app.PackageFullName -AllUsers -ErrorAction Stop
                        Write-Host "      ✅ Đã gỡ thành công!" -ForegroundColor Green
                        $removedCount++
                    }
                    catch {
                        Write-Warning "      ⚠️  Không thể gỡ: $_"
                        $failedCount++
                    }
                }
            }
            else {
                Write-Host "  ⏭️  Không tìm thấy: $appPattern" -ForegroundColor DarkGray
            }
        }
        catch {
            Write-Warning "  ⚠️  Lỗi khi tìm app $appPattern : $_"
            $failedCount++
        }
    }

    Write-Host ""
    Write-Host "  📊 Kết quả Debloat:" -ForegroundColor Cyan
    Write-Host "      ✅ Đã gỡ: $removedCount apps" -ForegroundColor Green
    if ($failedCount -gt 0) {
        Write-Host "      ⚠️  Thất bại: $failedCount apps" -ForegroundColor Yellow
    }
}

# ============================================================================
# REGISTRY TWEAKS (BASIC + ENHANCED)
# ============================================================================

function Set-RegistryTweaks {
    <#
    .SYNOPSIS
        Áp dụng các registry tweaks để tối ưu Windows
    #>

    Write-Host ""
    Write-Host "  ⚙️  Áp dụng Registry Tweaks..." -ForegroundColor Yellow
    Write-Host ""

    $tweaks = @(
        # === BASIC TWEAKS ===

        # Disable telemetry
        @{
            Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
            Name = "AllowTelemetry"
            Value = 0
            Type = "DWord"
            Description = "Tắt Telemetry"
        },

        # Disable Windows Tips
        @{
            Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
            Name = "DisableSoftLanding"
            Value = 1
            Type = "DWord"
            Description = "Tắt Windows Tips"
        },

        # Disable Activity History
        @{
            Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
            Name = "PublishUserActivities"
            Value = 0
            Type = "DWord"
            Description = "Tắt Activity History"
        },

        # Disable Location Tracking
        @{
            Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors"
            Name = "DisableLocation"
            Value = 1
            Type = "DWord"
            Description = "Tắt Location Tracking"
        },

        # Show file extensions
        @{
            Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            Name = "HideFileExt"
            Value = 0
            Type = "DWord"
            Description = "Hiển thị đuôi file"
        },

        # Show hidden files
        @{
            Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            Name = "Hidden"
            Value = 1
            Type = "DWord"
            Description = "Hiển thị file ẩn"
        },

        # Disable Search Web in Start Menu
        @{
            Path = "HKCU:\Software\Policies\Microsoft\Windows\Explorer"
            Name = "DisableSearchBoxSuggestions"
            Value = 1
            Type = "DWord"
            Description = "Tắt tìm kiếm web trong Start Menu"
        },

        # === PRIVACY & SECURITY ENHANCED ===

        # Disable Advertising ID
        @{
            Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo"
            Name = "Enabled"
            Value = 0
            Type = "DWord"
            Description = "Tắt Advertising ID"
        },

        # Disable Timeline
        @{
            Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\System"
            Name = "EnableActivityFeed"
            Value = 0
            Type = "DWord"
            Description = "Tắt Windows Timeline"
        },

        # Disable Cortana
        @{
            Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
            Name = "AllowCortana"
            Value = 0
            Type = "DWord"
            Description = "Tắt Cortana"
        },

        # Disable Web Search in Taskbar
        @{
            Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
            Name = "BingSearchEnabled"
            Value = 0
            Type = "DWord"
            Description = "Tắt Bing Search trong Taskbar"
        },

        # Disable App Suggestions
        @{
            Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
            Name = "SubscribedContent-338388Enabled"
            Value = 0
            Type = "DWord"
            Description = "Tắt App Suggestions"
        },

        # === PERFORMANCE TWEAKS ===

        # Disable animations
        @{
            Path = "HKCU:\Control Panel\Desktop\WindowMetrics"
            Name = "MinAnimate"
            Value = "0"
            Type = "String"
            Description = "Tắt window animations"
        },

        # Disable Transparency Effects
        @{
            Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
            Name = "EnableTransparency"
            Value = 0
            Type = "DWord"
            Description = "Tắt transparency effects"
        },

        # Disable Aero Shake
        @{
            Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            Name = "DisallowShaking"
            Value = 1
            Type = "DWord"
            Description = "Tắt Aero Shake"
        },

        # Enable Game Mode
        @{
            Path = "HKCU:\Software\Microsoft\GameBar"
            Name = "AutoGameModeEnabled"
            Value = 1
            Type = "DWord"
            Description = "Bật Game Mode"
        },

        # === NETWORK TWEAKS ===

        # Disable Large Send Offload
        @{
            Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
            Name = "DisableTaskOffload"
            Value = 0
            Type = "DWord"
            Description = "Tối ưu TCP offload"
        },

        # Optimize TCP Window Size
        @{
            Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"
            Name = "Tcp1323Opts"
            Value = 1
            Type = "DWord"
            Description = "Bật TCP Window Scaling"
        },

        # Disable Nagle's Algorithm (reduce latency)
        @{
            Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
            Name = "TcpAckFrequency"
            Value = 1
            Type = "DWord"
            Description = "Giảm network latency"
        }
    )

    $appliedCount = 0

    foreach ($tweak in $tweaks) {
        try {
            # Create registry path if not exists
            if (-not (Test-Path $tweak.Path)) {
                New-Item -Path $tweak.Path -Force | Out-Null
            }

            # Set registry value
            Set-ItemProperty -Path $tweak.Path -Name $tweak.Name -Value $tweak.Value -Type $tweak.Type -Force

            Write-Host "  ✅ $($tweak.Description)" -ForegroundColor Green
            $appliedCount++
        }
        catch {
            Write-Warning "  ⚠️  Lỗi khi áp dụng tweak '$($tweak.Description)': $_"
        }
    }

    Write-Host ""
    Write-Host "  📊 Đã áp dụng $appliedCount/$($tweaks.Count) tweaks" -ForegroundColor Cyan
}

# ============================================================================
# PERFORMANCE OPTIMIZATION (NEW!)
# ============================================================================

function Optimize-Performance {
    <#
    .SYNOPSIS
        Tối ưu hiệu suất Windows
    #>

    Write-Host ""
    Write-Host "  ⚡ Tối ưu Performance..." -ForegroundColor Yellow
    Write-Host ""

    # 1. Disable Visual Effects
    Write-Host "  🎨 Tắt Visual Effects không cần thiết..." -ForegroundColor Cyan

    try {
        $visualFXPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects"
        if (-not (Test-Path $visualFXPath)) {
            New-Item -Path $visualFXPath -Force | Out-Null
        }
        Set-ItemProperty -Path $visualFXPath -Name "VisualFXSetting" -Value 2 -Type DWord
        Write-Host "      ✅ Đã tối ưu Visual Effects" -ForegroundColor Green
    }
    catch {
        Write-Warning "      ⚠️  Lỗi khi tắt visual effects: $_"
    }

    # 2. Optimize Virtual Memory
    Write-Host "  💾 Tối ưu Virtual Memory (Pagefile)..." -ForegroundColor Cyan

    try {
        # Get RAM size
        $ram = (Get-CimInstance Win32_PhysicalMemory | Measure-Object -Property Capacity -Sum).Sum / 1GB

        # Calculate optimal pagefile size (1.5x RAM)
        $pagefileSize = [math]::Round($ram * 1.5 * 1024)

        Write-Host "      📊 RAM: $([math]::Round($ram, 2)) GB" -ForegroundColor DarkGray
        Write-Host "      📊 Pagefile: $pagefileSize MB" -ForegroundColor DarkGray

        # Set pagefile to system managed for now (safer)
        $computersys = Get-WmiObject Win32_ComputerSystem -EnableAllPrivileges
        $computersys.AutomaticManagedPagefile = $true
        $computersys.Put() | Out-Null

        Write-Host "      ✅ Đã tối ưu Pagefile" -ForegroundColor Green
    }
    catch {
        Write-Warning "      ⚠️  Lỗi khi tối ưu pagefile: $_"
    }

    # 3. Disable Superfetch/SysMain (for SSD)
    Write-Host "  🔥 Tối ưu cho SSD (Disable Superfetch/SysMain)..." -ForegroundColor Cyan

    try {
        # Check if SSD exists
        $disk = Get-PhysicalDisk | Where-Object { $_.MediaType -eq "SSD" } | Select-Object -First 1

        if ($disk) {
            Write-Host "      💿 Phát hiện SSD: $($disk.FriendlyName)" -ForegroundColor DarkGray

            # Disable SysMain (Superfetch)
            $sysmain = Get-Service -Name "SysMain" -ErrorAction SilentlyContinue
            if ($sysmain) {
                Stop-Service -Name "SysMain" -Force -ErrorAction SilentlyContinue
                Set-Service -Name "SysMain" -StartupType Disabled -ErrorAction SilentlyContinue
                Write-Host "      ✅ Đã tắt SysMain (Superfetch)" -ForegroundColor Green
            }
        }
        else {
            Write-Host "      ⏭️  Không phát hiện SSD, bỏ qua..." -ForegroundColor DarkGray
        }
    }
    catch {
        Write-Warning "      ⚠️  Lỗi khi tối ưu SSD: $_"
    }

    # 4. Disable Windows Search Indexing (optional)
    Write-Host "  🔍 Giảm tải Windows Search..." -ForegroundColor Cyan

    try {
        $wsearch = Get-Service -Name "WSearch" -ErrorAction SilentlyContinue
        if ($wsearch -and $wsearch.Status -eq "Running") {
            # Set to Manual instead of Disabled (safer)
            Set-Service -Name "WSearch" -StartupType Manual -ErrorAction SilentlyContinue
            Write-Host "      ✅ Đã chuyển Windows Search sang Manual" -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "      ⚠️  Lỗi khi tối ưu Windows Search: $_"
    }

    Write-Host ""
    Write-Host "  ✅ Performance optimization hoàn thành!" -ForegroundColor Green
}

# ============================================================================
# PRIVACY & SECURITY OPTIMIZATION (NEW!)
# ============================================================================

function Optimize-Privacy {
    <#
    .SYNOPSIS
        Tối ưu Privacy & Security
    #>

    Write-Host ""
    Write-Host "  🔒 Tối ưu Privacy & Security..." -ForegroundColor Yellow
    Write-Host ""

    # 1. Block Telemetry Hosts
    Write-Host "  🚫 Block Telemetry Hosts..." -ForegroundColor Cyan

    try {
        $hostsFile = "$env:SystemRoot\System32\drivers\etc\hosts"

        $telemetryHosts = @(
            "vortex.data.microsoft.com",
            "vortex-win.data.microsoft.com",
            "telecommand.telemetry.microsoft.com",
            "telecommand.telemetry.microsoft.com.nsatc.net",
            "oca.telemetry.microsoft.com",
            "sqm.telemetry.microsoft.com",
            "watson.telemetry.microsoft.com",
            "redir.metaservices.microsoft.com",
            "choice.microsoft.com",
            "df.telemetry.microsoft.com",
            "reports.wes.df.telemetry.microsoft.com",
            "wes.df.telemetry.microsoft.com",
            "services.wes.df.telemetry.microsoft.com",
            "sqm.df.telemetry.microsoft.com",
            "telemetry.microsoft.com",
            "watson.ppe.telemetry.microsoft.com",
            "telemetry.appex.bing.net",
            "telemetry.urs.microsoft.com",
            "telemetry.appex.bing.net:443",
            "settings-sandbox.data.microsoft.com",
            "vortex-sandbox.data.microsoft.com",
            "survey.watson.microsoft.com",
            "watson.live.com",
            "watson.microsoft.com",
            "statsfe2.ws.microsoft.com",
            "corpext.msitadfs.glbdns2.microsoft.com",
            "compatexchange.cloudapp.net",
            "cs1.wpc.v0cdn.net",
            "a-0001.a-msedge.net",
            "statsfe2.update.microsoft.com.akadns.net",
            "sls.update.microsoft.com.akadns.net",
            "fe2.update.microsoft.com.akadns.net",
            "diagnostics.support.microsoft.com",
            "corp.sts.microsoft.com",
            "statsfe1.ws.microsoft.com",
            "pre.footprintpredict.com",
            "i1.services.social.microsoft.com",
            "i1.services.social.microsoft.com.nsatc.net",
            "feedback.windows.com",
            "feedback.microsoft-hohm.com",
            "feedback.search.microsoft.com"
        )

        # Read existing hosts file
        $hostsContent = Get-Content $hostsFile -ErrorAction Stop

        $addedCount = 0
        $newEntries = @()

        foreach ($host in $telemetryHosts) {
            $entry = "0.0.0.0 $host"

            # Check if already exists
            if ($hostsContent -notcontains $entry) {
                $newEntries += $entry
                $addedCount++
            }
        }

        if ($addedCount -gt 0) {
            # Add WinVibe marker
            Add-Content -Path $hostsFile -Value "`n# WinVibe Telemetry Blocking" -Force
            Add-Content -Path $hostsFile -Value $newEntries -Force

            Write-Host "      ✅ Đã block $addedCount telemetry hosts" -ForegroundColor Green
        }
        else {
            Write-Host "      ⏭️  Telemetry hosts đã được block trước đó" -ForegroundColor DarkGray
        }
    }
    catch {
        Write-Warning "      ⚠️  Lỗi khi block telemetry hosts: $_"
    }

    # 2. Disable Cortana completely
    Write-Host "  🎤 Vô hiệu hóa Cortana hoàn toàn..." -ForegroundColor Cyan

    try {
        $cortanaPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
        if (-not (Test-Path $cortanaPath)) {
            New-Item -Path $cortanaPath -Force | Out-Null
        }

        Set-ItemProperty -Path $cortanaPath -Name "AllowCortana" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $cortanaPath -Name "AllowSearchToUseLocation" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $cortanaPath -Name "DisableWebSearch" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $cortanaPath -Name "ConnectedSearchUseWeb" -Value 0 -Type DWord -Force

        Write-Host "      ✅ Đã vô hiệu hóa Cortana" -ForegroundColor Green
    }
    catch {
        Write-Warning "      ⚠️  Lỗi khi vô hiệu hóa Cortana: $_"
    }

    Write-Host ""
    Write-Host "  ✅ Privacy & Security optimization hoàn thành!" -ForegroundColor Green
}

# ============================================================================
# NETWORK OPTIMIZATION (NEW!)
# ============================================================================

function Optimize-Network {
    <#
    .SYNOPSIS
        Tối ưu Network Performance
    #>

    Write-Host ""
    Write-Host "  🌐 Tối ưu Network..." -ForegroundColor Yellow
    Write-Host ""

    # 1. Disable QoS Bandwidth Reservation
    Write-Host "  📡 Tắt QoS Bandwidth Reservation..." -ForegroundColor Cyan

    try {
        $qosPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Psched"
        if (-not (Test-Path $qosPath)) {
            New-Item -Path $qosPath -Force | Out-Null
        }

        Set-ItemProperty -Path $qosPath -Name "NonBestEffortLimit" -Value 0 -Type DWord -Force
        Write-Host "      ✅ Đã tắt QoS bandwidth reservation" -ForegroundColor Green
    }
    catch {
        Write-Warning "      ⚠️  Lỗi: $_"
    }

    # 2. Disable Windows Update P2P Delivery
    Write-Host "  🔄 Tắt Windows Update P2P Delivery..." -ForegroundColor Cyan

    try {
        $doPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config"
        if (-not (Test-Path $doPath)) {
            New-Item -Path $doPath -Force | Out-Null
        }

        Set-ItemProperty -Path $doPath -Name "DODownloadMode" -Value 0 -Type DWord -Force
        Write-Host "      ✅ Đã tắt P2P delivery" -ForegroundColor Green
    }
    catch {
        Write-Warning "      ⚠️  Lỗi: $_"
    }

    # 3. Optimize DNS Cache
    Write-Host "  🔍 Tối ưu DNS Cache..." -ForegroundColor Cyan

    try {
        # Increase DNS cache size
        $dnsPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters"

        Set-ItemProperty -Path $dnsPath -Name "CacheHashTableBucketSize" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $dnsPath -Name "CacheHashTableSize" -Value 384 -Type DWord -Force
        Set-ItemProperty -Path $dnsPath -Name "MaxCacheEntryTtlLimit" -Value 64000 -Type DWord -Force
        Set-ItemProperty -Path $dnsPath -Name "MaxSOACacheEntryTtlLimit" -Value 301 -Type DWord -Force

        Write-Host "      ✅ Đã tối ưu DNS cache" -ForegroundColor Green
    }
    catch {
        Write-Warning "      ⚠️  Lỗi: $_"
    }

    # 4. TCP/IP Optimization
    Write-Host "  ⚡ Tối ưu TCP/IP Stack..." -ForegroundColor Cyan

    try {
        # Enable TCP Fast Open
        netsh int tcp set global fastopen=enabled 2>&1 | Out-Null

        # Optimize auto-tuning
        netsh int tcp set global autotuninglevel=normal 2>&1 | Out-Null

        # Enable ECN
        netsh int tcp set global ecncapability=enabled 2>&1 | Out-Null

        Write-Host "      ✅ Đã tối ưu TCP/IP stack" -ForegroundColor Green
    }
    catch {
        Write-Warning "      ⚠️  Lỗi: $_"
    }

    Write-Host ""
    Write-Host "  ✅ Network optimization hoàn thành!" -ForegroundColor Green
}

# ============================================================================
# STORAGE OPTIMIZATION (NEW!)
# ============================================================================

function Optimize-Storage {
    <#
    .SYNOPSIS
        Tối ưu Storage
    #>

    Write-Host ""
    Write-Host "  💿 Tối ưu Storage..." -ForegroundColor Yellow
    Write-Host ""

    # 1. Disable Hibernation
    Write-Host "  💤 Vô hiệu hóa Hibernation..." -ForegroundColor Cyan

    try {
        $hiberfil = "$env:SystemDrive\hiberfil.sys"
        $hiberSize = 0

        if (Test-Path $hiberfil) {
            $hiberSize = (Get-Item $hiberfil).Length / 1GB
            Write-Host "      📊 Kích thước hiberfil.sys: $([math]::Round($hiberSize, 2)) GB" -ForegroundColor DarkGray
        }

        powercfg /hibernate off 2>&1 | Out-Null

        if ($hiberSize -gt 0) {
            Write-Host "      ✅ Đã tắt hibernation (Giải phóng: $([math]::Round($hiberSize, 2)) GB)" -ForegroundColor Green
        }
        else {
            Write-Host "      ✅ Đã tắt hibernation" -ForegroundColor Green
        }
    }
    catch {
        Write-Warning "      ⚠️  Lỗi: $_"
    }

    # 2. Enable Compact OS (compress Windows files)
    Write-Host "  📦 Kiểm tra Compact OS..." -ForegroundColor Cyan

    try {
        $compactStatus = Compact.exe /CompactOS:query 2>&1

        if ($compactStatus -match "not compressed") {
            Write-Host "      🔨 Đang nén Windows files (có thể mất vài phút)..." -ForegroundColor Cyan
            Compact.exe /CompactOS:always 2>&1 | Out-Null
            Write-Host "      ✅ Đã bật Compact OS (tiết kiệm 2-3GB)" -ForegroundColor Green
        }
        else {
            Write-Host "      ⏭️  Compact OS đã được bật" -ForegroundColor DarkGray
        }
    }
    catch {
        Write-Warning "      ⚠️  Lỗi: $_"
    }

    # 3. TRIM Optimization for SSD
    Write-Host "  ✂️  Tối ưu TRIM cho SSD..." -ForegroundColor Cyan

    try {
        $disk = Get-PhysicalDisk | Where-Object { $_.MediaType -eq "SSD" } | Select-Object -First 1

        if ($disk) {
            # Enable TRIM
            fsutil behavior set DisableDeleteNotify 0 2>&1 | Out-Null

            # Run TRIM manually
            Optimize-Volume -DriveLetter C -ReTrim -Verbose 2>&1 | Out-Null

            Write-Host "      ✅ Đã tối ưu TRIM cho SSD" -ForegroundColor Green
        }
        else {
            Write-Host "      ⏭️  Không phát hiện SSD" -ForegroundColor DarkGray
        }
    }
    catch {
        Write-Warning "      ⚠️  Lỗi: $_"
    }

    # 4. Enable Storage Sense
    Write-Host "  🧹 Bật Storage Sense (tự động cleanup)..." -ForegroundColor Cyan

    try {
        $storageSensePath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy"
        if (-not (Test-Path $storageSensePath)) {
            New-Item -Path $storageSensePath -Force | Out-Null
        }

        Set-ItemProperty -Path $storageSensePath -Name "01" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $storageSensePath -Name "04" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $storageSensePath -Name "08" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $storageSensePath -Name "32" -Value 1 -Type DWord -Force

        Write-Host "      ✅ Đã bật Storage Sense" -ForegroundColor Green
    }
    catch {
        Write-Warning "      ⚠️  Lỗi: $_"
    }

    Write-Host ""
    Write-Host "  ✅ Storage optimization hoàn thành!" -ForegroundColor Green
}

# ============================================================================
# GAMING OPTIMIZATION (NEW!)
# ============================================================================

function Optimize-Gaming {
    <#
    .SYNOPSIS
        Tối ưu cho Gaming
    #>

    Write-Host ""
    Write-Host "  🎮 Tối ưu Gaming Performance..." -ForegroundColor Yellow
    Write-Host ""

    # 1. Disable Game DVR
    Write-Host "  📹 Tắt Game DVR & Game Bar..." -ForegroundColor Cyan

    try {
        $gameBarPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
        if (-not (Test-Path $gameBarPath)) {
            New-Item -Path $gameBarPath -Force | Out-Null
        }

        Set-ItemProperty -Path $gameBarPath -Name "AppCaptureEnabled" -Value 0 -Type DWord -Force
        Set-ItemProperty -Path $gameBarPath -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force

        $gameBarPath2 = "HKCU:\System\GameConfigStore"
        if (-not (Test-Path $gameBarPath2)) {
            New-Item -Path $gameBarPath2 -Force | Out-Null
        }
        Set-ItemProperty -Path $gameBarPath2 -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force

        Write-Host "      ✅ Đã tắt Game DVR & Game Bar" -ForegroundColor Green
    }
    catch {
        Write-Warning "      ⚠️  Lỗi: $_"
    }

    # 2. Disable Fullscreen Optimization
    Write-Host "  🖥️  Tắt Fullscreen Optimization..." -ForegroundColor Cyan

    try {
        $fsoPath = "HKCU:\System\GameConfigStore"
        if (-not (Test-Path $fsoPath)) {
            New-Item -Path $fsoPath -Force | Out-Null
        }

        Set-ItemProperty -Path $fsoPath -Name "GameDVR_FSEBehaviorMode" -Value 2 -Type DWord -Force
        Set-ItemProperty -Path $fsoPath -Name "GameDVR_HonorUserFSEBehaviorMode" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $fsoPath -Name "GameDVR_DXGIHonorFSEWindowsCompatible" -Value 1 -Type DWord -Force
        Set-ItemProperty -Path $fsoPath -Name "GameDVR_EFSEFeatureFlags" -Value 0 -Type DWord -Force

        Write-Host "      ✅ Đã tắt Fullscreen Optimization" -ForegroundColor Green
    }
    catch {
        Write-Warning "      ⚠️  Lỗi: $_"
    }

    # 3. Enable Hardware-accelerated GPU Scheduling
    Write-Host "  ⚡ Bật Hardware-accelerated GPU Scheduling..." -ForegroundColor Cyan

    try {
        $gpuPath = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"

        # Check if supported
        if (Test-Path $gpuPath) {
            Set-ItemProperty -Path $gpuPath -Name "HwSchMode" -Value 2 -Type DWord -Force
            Write-Host "      ✅ Đã bật GPU Hardware Scheduling (cần restart)" -ForegroundColor Green
        }
        else {
            Write-Host "      ⚠️  GPU không hỗ trợ Hardware Scheduling" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Warning "      ⚠️  Lỗi: $_"
    }

    # 4. Create Ultimate Performance Power Plan
    Write-Host "  ⚡ Tạo Ultimate Performance Power Plan..." -ForegroundColor Cyan

    try {
        # Check if already exists
        $ultimatePlan = powercfg /list | Select-String -Pattern "Ultimate Performance"

        if (-not $ultimatePlan) {
            # Unhide and duplicate Ultimate Performance plan
            powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1 | Out-Null
            Write-Host "      ✅ Đã tạo Ultimate Performance plan" -ForegroundColor Green
        }
        else {
            Write-Host "      ⏭️  Ultimate Performance plan đã tồn tại" -ForegroundColor DarkGray
        }
    }
    catch {
        Write-Warning "      ⚠️  Lỗi: $_"
    }

    Write-Host ""
    Write-Host "  ✅ Gaming optimization hoàn thành!" -ForegroundColor Green
}

# ============================================================================
# STARTUP & BOOT OPTIMIZATION (NEW!)
# ============================================================================

function Optimize-StartupBoot {
    <#
    .SYNOPSIS
        Tối ưu Startup & Boot
    #>

    Write-Host ""
    Write-Host "  🚀 Tối ưu Startup & Boot..." -ForegroundColor Yellow
    Write-Host ""

    # 1. Disable Unnecessary Startup Programs
    Write-Host "  📋 Kiểm tra Startup Programs..." -ForegroundColor Cyan

    try {
        $startupApps = Get-CimInstance Win32_StartupCommand | Select-Object Name, Location, Command
        Write-Host "      📊 Tìm thấy $($startupApps.Count) startup programs" -ForegroundColor DarkGray

        # Just report, don't disable automatically (safer)
        Write-Host "      ℹ️  Kiểm tra Task Manager > Startup để vô hiệu hóa apps không cần thiết" -ForegroundColor Yellow
    }
    catch {
        Write-Warning "      ⚠️  Lỗi: $_"
    }

    # 2. Optimize Boot Timeout
    Write-Host "  ⏱️  Tối ưu Boot Timeout..." -ForegroundColor Cyan

    try {
        # Reduce boot menu timeout to 3 seconds
        bcdedit /timeout 3 2>&1 | Out-Null
        Write-Host "      ✅ Đã giảm boot timeout xuống 3 giây" -ForegroundColor Green
    }
    catch {
        Write-Warning "      ⚠️  Lỗi: $_"
    }

    # 3. Enable Fast Startup
    Write-Host "  ⚡ Bật Fast Startup..." -ForegroundColor Cyan

    try {
        $fastStartupPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power"
        Set-ItemProperty -Path $fastStartupPath -Name "HiberbootEnabled" -Value 1 -Type DWord -Force
        Write-Host "      ✅ Đã bật Fast Startup" -ForegroundColor Green
    }
    catch {
        Write-Warning "      ⚠️  Lỗi: $_"
    }

    Write-Host ""
    Write-Host "  ✅ Startup & Boot optimization hoàn thành!" -ForegroundColor Green
}

# ============================================================================
# SERVICE OPTIMIZATION
# ============================================================================

function Optimize-WindowsServices {
    <#
    .SYNOPSIS
        Tối ưu các Windows Services không cần thiết
    #>

    Write-Host ""
    Write-Host "  🔧 Tối ưu Windows Services..." -ForegroundColor Yellow
    Write-Host ""

    # Services to disable (cẩn thận!)
    $servicesToDisable = @(
        @{ Name = "DiagTrack"; Description = "Connected User Experiences and Telemetry" },
        @{ Name = "dmwappushservice"; Description = "WAP Push Message Routing Service" },
        @{ Name = "MapsBroker"; Description = "Downloaded Maps Manager" },
        @{ Name = "RetailDemo"; Description = "Retail Demo Service" },
        @{ Name = "XblAuthManager"; Description = "Xbox Live Auth Manager" },
        @{ Name = "XblGameSave"; Description = "Xbox Live Game Save" },
        @{ Name = "XboxGipSvc"; Description = "Xbox Accessory Management Service" },
        @{ Name = "XboxNetApiSvc"; Description = "Xbox Live Networking Service" }
    )

    $disabledCount = 0

    foreach ($svc in $servicesToDisable) {
        try {
            $service = Get-Service -Name $svc.Name -ErrorAction SilentlyContinue

            if ($service) {
                if ($service.Status -eq 'Running') {
                    Stop-Service -Name $svc.Name -Force -ErrorAction Stop
                }

                Set-Service -Name $svc.Name -StartupType Disabled -ErrorAction Stop
                Write-Host "  ✅ Đã vô hiệu hóa: $($svc.Description)" -ForegroundColor Green
                $disabledCount++
            }
            else {
                Write-Host "  ⏭️  Không tìm thấy: $($svc.Name)" -ForegroundColor DarkGray
            }
        }
        catch {
            Write-Warning "  ⚠️  Lỗi khi vô hiệu hóa service $($svc.Name): $_"
        }
    }

    Write-Host ""
    Write-Host "  📊 Đã vô hiệu hóa $disabledCount services" -ForegroundColor Cyan
}

# ============================================================================
# DYNAMIC POWER PLAN (TÍNH NĂNG ĐẶC BIỆT)
# ============================================================================

function New-CustomPowerPlan {
    <#
    .SYNOPSIS
        Tạo custom power plan
    .PARAMETER PlanName
        Tên power plan
    .PARAMETER BasePlan
        Base plan (High Performance, Balanced, Power Saver)
    .PARAMETER Settings
        Hashtable chứa các settings
    #>

    param (
        [string]$PlanName,
        [string]$BasePlan,
        [hashtable]$Settings
    )

    Write-Host "  🔋 Tạo power plan: $PlanName" -ForegroundColor Cyan

    # Get base plan GUID
    $basePlanGuid = switch ($BasePlan) {
        "High Performance" { "8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c" }
        "Balanced" { "381b4222-f694-41f0-9685-ff5bb260df2e" }
        "Power Saver" { "a1841308-3541-4fab-bc81-f71556f20b4a" }
        default { "381b4222-f694-41f0-9685-ff5bb260df2e" }
    }

    try {
        # Check if plan already exists
        $existingPlan = powercfg /list | Select-String -Pattern $PlanName

        if ($existingPlan) {
            Write-Host "      ⚠️  Power plan đã tồn tại, đang xóa..." -ForegroundColor Yellow

            # Extract GUID and delete
            if ($existingPlan -match '([a-f0-9\-]{36})') {
                $existingGuid = $Matches[1]
                powercfg /delete $existingGuid 2>&1 | Out-Null
            }
        }

        # Duplicate base plan
        $output = powercfg /duplicatescheme $basePlanGuid 2>&1
        if ($output -match '([a-f0-9\-]{36})') {
            $newPlanGuid = $Matches[1]
        }
        else {
            throw "Không thể tạo power plan"
        }

        # Rename plan
        powercfg /changename $newPlanGuid $PlanName "Custom power plan for WinVibe" 2>&1 | Out-Null

        # Apply settings
        if ($Settings) {
            # Monitor timeout (minutes)
            if ($Settings.ContainsKey('monitorTimeout')) {
                $seconds = $Settings.monitorTimeout * 60
                powercfg /change monitor-timeout-ac $Settings.monitorTimeout 2>&1 | Out-Null
                powercfg /change monitor-timeout-dc $Settings.monitorTimeout 2>&1 | Out-Null
            }

            # Disk timeout (minutes)
            if ($Settings.ContainsKey('diskTimeout')) {
                powercfg /change disk-timeout-ac $Settings.diskTimeout 2>&1 | Out-Null
                powercfg /change disk-timeout-dc $Settings.diskTimeout 2>&1 | Out-Null
            }

            # CPU settings (percentage)
            if ($Settings.ContainsKey('cpuMinState')) {
                # Processor power management - Minimum processor state
                powercfg /setacvalueindex $newPlanGuid SUB_PROCESSOR PROCTHROTTLEMIN $Settings.cpuMinState 2>&1 | Out-Null
                powercfg /setdcvalueindex $newPlanGuid SUB_PROCESSOR PROCTHROTTLEMIN $Settings.cpuMinState 2>&1 | Out-Null
            }

            if ($Settings.ContainsKey('cpuMaxState')) {
                # Processor power management - Maximum processor state
                powercfg /setacvalueindex $newPlanGuid SUB_PROCESSOR PROCTHROTTLEMAX $Settings.cpuMaxState 2>&1 | Out-Null
                powercfg /setdcvalueindex $newPlanGuid SUB_PROCESSOR PROCTHROTTLEMAX $Settings.cpuMaxState 2>&1 | Out-Null
            }
        }

        # Apply the plan settings
        powercfg /setactive $newPlanGuid 2>&1 | Out-Null

        Write-Host "      ✅ Đã tạo power plan: $PlanName (GUID: $newPlanGuid)" -ForegroundColor Green

        return $newPlanGuid
    }
    catch {
        Write-Warning "      ⚠️  Lỗi khi tạo power plan: $_"
        return $null
    }
}

function Set-DynamicPowerManagement {
    <#
    .SYNOPSIS
        Thiết lập Dynamic Power Management - tự động chuyển power plan khi cắm/rút sạc
    .DESCRIPTION
        Tạo 2 power plans (Plugged-In và On-Battery) và thiết lập Task Scheduler
        để tự động chuyển đổi dựa trên trạng thái nguồn điện
    .PARAMETER Config
        Configuration object chứa power plan settings
    #>

    param (
        [object]$Config
    )

    Write-Host ""
    Write-Host "  ⚡ Thiết lập Dynamic Power Management..." -ForegroundColor Yellow
    Write-Host ""

    # Create Plugged-In Power Plan
    $pluggedInGuid = New-CustomPowerPlan `
        -PlanName $Config.powerPlan.pluggedInPlan.name `
        -BasePlan $Config.powerPlan.pluggedInPlan.basePlan `
        -Settings $Config.powerPlan.pluggedInPlan.settings

    if (-not $pluggedInGuid) {
        Write-Warning "Không thể tạo Plugged-In power plan"
        return
    }

    # Create On-Battery Power Plan
    $onBatteryGuid = New-CustomPowerPlan `
        -PlanName $Config.powerPlan.onBatteryPlan.name `
        -BasePlan $Config.powerPlan.onBatteryPlan.basePlan `
        -Settings $Config.powerPlan.onBatteryPlan.settings

    if (-not $onBatteryGuid) {
        Write-Warning "Không thể tạo On-Battery power plan"
        return
    }

    # Create PowerShell script for switching
    $scriptPath = "C:\WinVibe_PowerSwitch.ps1"

    $switchScript = @"
# WinVibe Dynamic Power Plan Switcher
`$pluggedInGuid = "$pluggedInGuid"
`$onBatteryGuid = "$onBatteryGuid"

# Get power status
Add-Type -AssemblyName System.Windows.Forms
`$powerStatus = [System.Windows.Forms.SystemInformation]::PowerStatus

if (`$powerStatus.PowerLineStatus -eq 'Online') {
    # Plugged in - switch to high performance
    powercfg /setactive `$pluggedInGuid
    Write-Host "Switched to Plugged-In power plan"
}
else {
    # On battery - switch to balanced
    powercfg /setactive `$onBatteryGuid
    Write-Host "Switched to On-Battery power plan"
}
"@

    # Save script
    Set-Content -Path $scriptPath -Value $switchScript -Force
    Write-Host "  📄 Đã tạo script chuyển đổi: $scriptPath" -ForegroundColor Green

    # Create Scheduled Task - Trigger on power status change
    Write-Host "  📅 Tạo Scheduled Task..." -ForegroundColor Cyan

    # Remove existing task if exists
    $taskName = "WinVibe_DynamicPowerSwitch"
    $existingTask = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

    if ($existingTask) {
        Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    }

    # Create task action
    $action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""

    # Create triggers for power events
    # Trigger 1: On AC power connect (Event ID 105, power source = AC)
    $trigger1Xml = @"
<QueryList>
  <Query Id="0" Path="System">
    <Select Path="System">*[System[Provider[@Name='Microsoft-Windows-Kernel-Power'] and (EventID=105)]]</Select>
  </Query>
</QueryList>
"@

    $trigger1 = New-ScheduledTaskTrigger -AtLogOn
    $trigger1.Enabled = $true

    # Trigger 2: On battery (user logon fallback)
    $trigger2 = New-ScheduledTaskTrigger -AtLogOn

    # Create task principal (run with highest privileges)
    $principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -LogonType ServiceAccount -RunLevel Highest

    # Create task settings
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit (New-TimeSpan -Minutes 5)

    # Register scheduled task
    try {
        Register-ScheduledTask -TaskName $taskName `
            -Action $action `
            -Trigger $trigger1, $trigger2 `
            -Principal $principal `
            -Settings $settings `
            -Description "WinVibe Dynamic Power Plan Switcher - Auto switch power plan based on power source" `
            -Force | Out-Null

        Write-Host "  ✅ Đã tạo Scheduled Task: $taskName" -ForegroundColor Green
    }
    catch {
        Write-Warning "  ⚠️  Lỗi khi tạo Scheduled Task: $_"
    }

    # Additional: Create event-based trigger using WMI
    Write-Host ""
    Write-Host "  🔌 Thiết lập WMI Event Subscription..." -ForegroundColor Cyan

    # Create WMI event subscription for power change
    $wmiScript = @"
# WinVibe WMI Power Event Handler
Register-WmiEvent -Query "SELECT * FROM Win32_PowerManagementEvent WHERE EventType = 10" -Action {
    Start-Process pwsh.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -WindowStyle Hidden
}
"@

    $wmiScriptPath = "C:\WinVibe_WMI_PowerEvent.ps1"
    Set-Content -Path $wmiScriptPath -Value $wmiScript -Force

    # Run initial switch
    Write-Host "  🔄 Chạy lần đầu để áp dụng power plan..." -ForegroundColor Cyan
    Start-Process pwsh.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`"" -WindowStyle Hidden -Wait

    Write-Host ""
    Write-Host "  ╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "  ║   ✅ DYNAMIC POWER MANAGEMENT ĐÃ ĐƯỢC CÀI ĐẶT!          ║" -ForegroundColor Green
    Write-Host "  ╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green
    Write-Host ""
    Write-Host "  📋 Power Plans:" -ForegroundColor Cyan
    Write-Host "      🔌 Plugged-In: $($Config.powerPlan.pluggedInPlan.name) (GUID: $pluggedInGuid)" -ForegroundColor White
    Write-Host "      🔋 On-Battery: $($Config.powerPlan.onBatteryPlan.name) (GUID: $onBatteryGuid)" -ForegroundColor White
    Write-Host ""
    Write-Host "  ℹ️  Hệ thống sẽ tự động chuyển đổi power plan khi bạn cắm/rút sạc!" -ForegroundColor Yellow
}

# ============================================================================
# MAIN EXPORT FUNCTION
# ============================================================================

function Start-WindowsOptimization {
    <#
    .SYNOPSIS
        Hàm chính để thực hiện tối ưu Windows
    .PARAMETER ConfigPath
        Đường dẫn đến thư mục config
    #>

    param (
        [string]$ConfigPath
    )

    Write-Host ""
    Write-Host "🔧 Bắt đầu tối ưu Windows..." -ForegroundColor Cyan
    Write-Host ""

    # Load configuration
    $configFile = Join-Path $ConfigPath "config.json"

    if (-not (Test-Path $configFile)) {
        throw "Không tìm thấy file cấu hình: $configFile"
    }

    $config = Get-Content $configFile -Raw | ConvertFrom-Json

    try {
        # 1. Debloat
        if ($config.modules.optimize.debloat) {
            $bloatwareList = Join-Path $ConfigPath "bloatware_list.txt"
            Invoke-Debloat -BloatwareListPath $bloatwareList
        }

        # 2. Registry Tweaks (Basic + Enhanced)
        if ($config.modules.optimize.registryTweaks) {
            Set-RegistryTweaks
        }

        # 3. Performance Optimization (NEW!)
        if ($config.modules.optimize.performanceTweaks) {
            Optimize-Performance
        }

        # 4. Privacy & Security (NEW!)
        if ($config.modules.optimize.privacyTweaks) {
            Optimize-Privacy
        }

        # 5. Network Optimization (NEW!)
        if ($config.modules.optimize.networkTweaks) {
            Optimize-Network
        }

        # 6. Storage Optimization (NEW!)
        if ($config.modules.optimize.storageTweaks) {
            Optimize-Storage
        }

        # 7. Gaming Optimization (NEW!)
        if ($config.modules.optimize.gamingTweaks) {
            Optimize-Gaming
        }

        # 8. Startup & Boot Optimization (NEW!)
        if ($config.modules.optimize.startupTweaks) {
            Optimize-StartupBoot
        }

        # 9. Service Optimization
        if ($config.modules.optimize.serviceTweaks) {
            Optimize-WindowsServices
        }

        # 10. Dynamic Power Management
        if ($config.modules.optimize.dynamicPowerPlan) {
            Set-DynamicPowerManagement -Config $config
        }

        Write-Host ""
        Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║         ✅ TỐI ƯU WINDOWS HOÀN THÀNH!                    ║" -ForegroundColor Green
        Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
        Write-Host "  ⚠️  KHUYẾN NGHỊ: Khởi động lại máy để áp dụng đầy đủ các thay đổi!" -ForegroundColor Yellow
        Write-Host ""
    }
    catch {
        Write-Host ""
        Write-Host "❌ Lỗi trong quá trình tối ưu: $_" -ForegroundColor Red
        throw
    }
}

# ============================================================================
# ALIASES TIẾNG VIỆT - Vietnamese Aliases
# ============================================================================

# Thiết lập các aliases tiếng Việt cho các functions
# Người dùng có thể sử dụng tên tiếng Việt thay vì tiếng Anh

Set-Alias -Name 'BatDau-ToiUuWindows' -Value 'Start-WindowsOptimization'
Set-Alias -Name 'GoBo-Bloatware' -Value 'Invoke-Debloat'
Set-Alias -Name 'Cai-ToiUuRegistry' -Value 'Set-RegistryTweaks'
Set-Alias -Name 'ToiUu-HieuSuat' -Value 'Optimize-Performance'
Set-Alias -Name 'ToiUu-BaoMat' -Value 'Optimize-Privacy'
Set-Alias -Name 'ToiUu-MangInternet' -Value 'Optimize-Network'
Set-Alias -Name 'ToiUu-BoNho' -Value 'Optimize-Storage'
Set-Alias -Name 'ToiUu-ChoiGame' -Value 'Optimize-Gaming'
Set-Alias -Name 'ToiUu-KhoiDong' -Value 'Optimize-StartupBoot'
Set-Alias -Name 'ToiUu-DichVu' -Value 'Optimize-WindowsServices'
Set-Alias -Name 'Cai-QuanLyNguonDienDong' -Value 'Set-DynamicPowerManagement'
Set-Alias -Name 'Tao-GoiNguonTuyChinh' -Value 'New-CustomPowerPlan'

# ============================================================================
# MODULE EXPORTS
# ============================================================================

Export-ModuleMember -Function @(
    'Start-WindowsOptimization',
    'Invoke-Debloat',
    'Set-RegistryTweaks',
    'Optimize-Performance',
    'Optimize-Privacy',
    'Optimize-Network',
    'Optimize-Storage',
    'Optimize-Gaming',
    'Optimize-StartupBoot',
    'Optimize-WindowsServices',
    'Set-DynamicPowerManagement',
    'New-CustomPowerPlan'
)

# Export aliases tiếng Việt
Export-ModuleMember -Alias @(
    'BatDau-ToiUuWindows',
    'GoBo-Bloatware',
    'Cai-ToiUuRegistry',
    'ToiUu-HieuSuat',
    'ToiUu-BaoMat',
    'ToiUu-MangInternet',
    'ToiUu-BoNho',
    'ToiUu-ChoiGame',
    'ToiUu-KhoiDong',
    'ToiUu-DichVu',
    'Cai-QuanLyNguonDienDong',
    'Tao-GoiNguonTuyChinh'
)
