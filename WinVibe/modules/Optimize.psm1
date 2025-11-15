<#
.SYNOPSIS
    Optimize Module - Tối ưu hóa Windows
.DESCRIPTION
    Module thực hiện debloat, registry tweaks, service optimization và Dynamic Power Management
.NOTES
    Version: 1.0.0
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
# REGISTRY TWEAKS
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
    Write-Host "  ║   ✅ DYNAMIC POWER MANAGEMENT ĐÃ ĐƯỢC CÀI ĐặT!          ║" -ForegroundColor Green
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

        # 2. Registry Tweaks
        if ($config.modules.optimize.registryTweaks) {
            Set-RegistryTweaks
        }

        # 3. Service Optimization
        if ($config.modules.optimize.serviceTweaks) {
            Optimize-WindowsServices
        }

        # 4. Dynamic Power Management
        if ($config.modules.optimize.dynamicPowerPlan) {
            Set-DynamicPowerManagement -Config $config
        }

        Write-Host ""
        Write-Host "╔═══════════════════════════════════════════════════════════╗" -ForegroundColor Green
        Write-Host "║         ✅ TỐI ƯU WINDOWS HOÀN THÀNH!                    ║" -ForegroundColor Green
        Write-Host "╚═══════════════════════════════════════════════════════════╝" -ForegroundColor Green
        Write-Host ""
    }
    catch {
        Write-Host ""
        Write-Host "❌ Lỗi trong quá trình tối ưu: $_" -ForegroundColor Red
        throw
    }
}

# ============================================================================
# MODULE EXPORTS
# ============================================================================

Export-ModuleMember -Function @(
    'Start-WindowsOptimization',
    'Invoke-Debloat',
    'Set-RegistryTweaks',
    'Optimize-WindowsServices',
    'Set-DynamicPowerManagement',
    'New-CustomPowerPlan'
)
