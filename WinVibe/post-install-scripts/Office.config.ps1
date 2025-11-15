<#
.SYNOPSIS
    Post-Install Configuration for Microsoft Office
.DESCRIPTION
    Script tự động cấu hình Microsoft Office sau khi cài đặt
.NOTES
    Version: 1.0.0
    QUAN TRỌNG: Script này chỉ là MẪU. Bạn cần tùy chỉnh theo nhu cầu.
#>

Write-Host "  🔧 Configuring Microsoft Office..." -ForegroundColor Cyan

try {
    # Ví dụ: Copy file settings hoặc templates
    # CẢNH BÁO: KHÔNG BAO GỒM CÔNG CỤ BẺ KHÓA hoặc KEYGEN

    # Ví dụ: Áp dụng registry settings cho Office
    $officeRegistryPath = "HKCU:\Software\Microsoft\Office\16.0\Common"

    if (Test-Path $officeRegistryPath) {
        # Disable First Run Movie
        Set-ItemProperty -Path "$officeRegistryPath\General" `
            -Name "ShownFirstRunOptin" -Value 1 -Type DWord -Force

        Write-Host "      ✅ Đã tắt First Run Movie" -ForegroundColor Green
    }

    # Ví dụ: Copy templates
    $templatesSource = "C:\WinVibe_Data\Office_Templates"
    $templatesTarget = "$env:APPDATA\Microsoft\Templates"

    if (Test-Path $templatesSource) {
        Copy-Item -Path "$templatesSource\*" -Destination $templatesTarget -Recurse -Force
        Write-Host "      ✅ Đã copy templates" -ForegroundColor Green
    }

    # Ví dụ: Import license key (NẾU BẠN CÓ LICENSE HỢP LỆ)
    # $licenseKeyFile = "C:\WinVibe_Data\Office_License.txt"
    # if (Test-Path $licenseKeyFile) {
    #     $licenseKey = Get-Content $licenseKeyFile -Raw
    #     # Sử dụng công cụ chính thống của Microsoft để activate
    #     # cscript "C:\Program Files\Microsoft Office\Office16\OSPP.VBS" /inpkey:$licenseKey
    # }

    Write-Host "      ✅ Office configuration hoàn thành!" -ForegroundColor Green
    Write-Host "      ℹ️  Lưu ý: Đây là script MẪU. Vui lòng tùy chỉnh theo nhu cầu." -ForegroundColor Yellow
}
catch {
    Write-Warning "      ⚠️  Lỗi khi cấu hình Office: $_"
}
