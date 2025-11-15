# 🚀 WinVibe - Windows Auto-Setup Tool

**WinVibe** là công cụ tự động hóa mạnh mẽ giúp thiết lập, tối ưu và dọn dẹp Windows một cách nhanh chóng và hiệu quả. Tiết kiệm hàng giờ đồng hồ khi thiết lập máy tính mới!

## ✨ Tính năng chính

### 🔧 1. Tối ưu Windows (Optimize)

- **Debloat**: Tự động gỡ bỏ bloatware và ứng dụng không cần thiết
- **Registry Tweaks**: Tối ưu registry để tăng hiệu suất và bảo mật
  - Tắt Telemetry, Activity History
  - Tắt Location Tracking
  - Hiển thị file extensions và hidden files
- **Service Optimization**: Vô hiệu hóa các services không cần thiết
- **⚡ Dynamic Power Plan**: Tự động chuyển đổi power plan thông minh
  - 🔌 **Cắm sạc**: Chuyển sang High Performance
  - 🔋 **Rút sạc**: Chuyển sang Balanced (tối ưu pin nhưng không lag)

### 📦 2. Cài đặt Phần mềm (Install)

- Tự động cài đặt phần mềm qua **Winget**
- Hỗ trợ cài đặt hàng loạt với priority
- Chạy post-install scripts để tự động cấu hình
- Kiểm tra phần mềm đã cài, tránh cài trùng
- Tự động dọn dẹp cache sau khi cài

### 🧹 3. Dọn dẹp Hệ thống (Clean)

- Dọn temp files (Windows Temp, User Temp, Prefetch)
- Dọn Windows Update cache
- Dọn WinSxS với DISM
- Dọn cache của trình duyệt (Chrome, Edge, Firefox)
- Chạy Disk Cleanup Manager tự động

## 📋 Yêu cầu hệ thống

- **OS**: Windows 10 (1809+) hoặc Windows 11
- **PowerShell**: PowerShell 7+ (khuyến nghị)
- **Quyền**: Administrator rights
- **Winget**: Tự động cài đặt nếu chưa có

## 🚀 Cài đặt

### Bước 1: Tải WinVibe

```bash
# Clone repository hoặc tải ZIP
git clone https://github.com/yourusername/WinVibe.git
cd WinVibe
```

### Bước 2: Chạy tool

```powershell
# Chuột phải vào main.ps1 -> Run with PowerShell
# Hoặc chạy từ terminal:
pwsh -ExecutionPolicy Bypass -File main.ps1
```

Tool sẽ tự động:
- Kiểm tra quyền Admin (yêu cầu UAC nếu cần)
- Set Execution Policy cho session
- Load các modules
- Hiển thị menu

## 🎯 Cách sử dụng

### Menu chính

Khi chạy `main.ps1`, bạn sẽ thấy menu:

```
╔═══════════════════════════════════════════════════════════╗
║                    🚀 WINVIBE v1.0                        ║
║         Windows Auto-Setup & Optimization Tool            ║
╚═══════════════════════════════════════════════════════════╝

  [1] 🔧 Tối ưu Windows (Optimize)
  [2] 📦 Cài đặt Phần mềm (Install)
  [3] 🧹 Dọn dẹp Hệ thống (Clean)
  [4] ⚡ Thực hiện TẤT CẢ (All-in-One)
  [0] ❌ Thoát (Exit)
```

### Sử dụng lần đầu (Khuyến nghị)

```
Chọn [4] - Thực hiện TẤT CẢ
```

Tool sẽ tự động:
1. Tối ưu Windows → 2. Cài phần mềm → 3. Dọn dẹp hệ thống

## ⚙️ Cấu hình

### 📁 Cấu trúc thư mục

```
WinVibe/
├── main.ps1                      # File chính (chạy file này)
├── modules/                      # PowerShell modules
│   ├── Optimize.psm1            # Module tối ưu
│   ├── Install.psm1             # Module cài đặt
│   └── Clean.psm1               # Module dọn dẹp
├── config/                       # File cấu hình
│   ├── config.json              # Cấu hình chung
│   ├── software_list.json       # Danh sách phần mềm
│   ├── bloatware_list.txt       # Danh sách bloatware
│   └── cleanup_paths.json       # Đường dẫn cleanup
├── post-install-scripts/         # Scripts chạy sau cài đặt
│   ├── VSCode.config.ps1
│   └── Office.config.ps1
└── README.md
```

### 🔧 Tùy chỉnh danh sách phần mềm

Chỉnh sửa `config/software_list.json`:

```json
[
  {
    "name": "Visual Studio Code",
    "wingetId": "Microsoft.VisualStudioCode",
    "postInstallScript": "post-install-scripts/VSCode.config.ps1",
    "priority": 1
  },
  {
    "name": "Your Software Here",
    "wingetId": "Publisher.SoftwareName",
    "postInstallScript": null,
    "priority": 2
  }
]
```

**Lưu ý**:
- Tìm Winget ID: `winget search "tên phần mềm"`
- Priority: 1 = cao nhất, 2 = trung bình, 3 = thấp

### 🗑️ Tùy chỉnh Bloatware

Chỉnh sửa `config/bloatware_list.txt`:

```txt
# Bỏ dấu # ở đầu dòng để enable gỡ app đó
Microsoft.BingNews
Microsoft.XboxApp
*CandyCrush*

# Thêm app của bạn ở đây
# Your.Bloatware.AppName
```

### ⚡ Tùy chỉnh Power Plans

Chỉnh sửa `config/config.json`:

```json
{
  "powerPlan": {
    "pluggedInPlan": {
      "name": "Vibe_PluggedIn",
      "settings": {
        "cpuMinState": 100,
        "cpuMaxState": 100
      }
    },
    "onBatteryPlan": {
      "name": "Vibe_OnBattery",
      "settings": {
        "cpuMinState": 5,
        "cpuMaxState": 85
      }
    }
  }
}
```

## 📝 Viết Post-Install Script

Tạo file mới trong `post-install-scripts/`:

```powershell
# YourApp.config.ps1

Write-Host "  🔧 Configuring Your App..." -ForegroundColor Cyan

try {
    # Copy settings
    Copy-Item "C:\WinVibe_Data\YourApp\settings.json" `
              "$env:APPDATA\YourApp\settings.json" -Force

    # Apply registry
    Set-ItemProperty -Path "HKCU:\Software\YourApp" `
                     -Name "Setting" -Value 1 -Type DWord

    Write-Host "      ✅ Configuration complete!" -ForegroundColor Green
}
catch {
    Write-Warning "      ⚠️  Error: $_"
}
```

Sau đó thêm vào `software_list.json`:

```json
{
  "name": "Your App",
  "wingetId": "Publisher.YourApp",
  "postInstallScript": "post-install-scripts/YourApp.config.ps1",
  "priority": 1
}
```

## 🔋 Dynamic Power Plan - Cách hoạt động

Tool tạo 2 power plans tùy chỉnh:

1. **Vibe_PluggedIn** (High Performance)
   - CPU: 100% min/max
   - Disk: Không tắt
   - Monitor: 15 phút

2. **Vibe_OnBattery** (Balanced Optimized)
   - CPU: 5% min, 85% max (không lag như Power Saver)
   - Disk: 10 phút
   - Monitor: 5 phút

**Tự động chuyển đổi qua:**
- Scheduled Task kích hoạt bởi Power Events
- WMI Event Subscription
- Script: `C:\WinVibe_PowerSwitch.ps1`

## ❓ FAQ

### 1. Tool có an toàn không?

✅ **Có!** Tool 100% open-source, bạn có thể review toàn bộ code. Không chứa bất kỳ:
- Malware, virus
- Công cụ bẻ khóa, keygen
- Backdoor, telemetry

### 2. Tool có làm hỏng Windows không?

⚠️ Tool sử dụng các API chính thống của Windows. Tuy nhiên:
- **Khuyến nghị**: Test trên máy ảo trước
- **Backup**: Tạo System Restore Point trước khi chạy
- **Cẩn thận**: Đọc kỹ bloatware list trước khi gỡ

### 3. Tôi có thể tắt một module không?

✅ **Có!** Chỉnh sửa `config/config.json`:

```json
{
  "modules": {
    "optimize": {
      "enabled": false,  // Tắt module optimize
      "debloat": false,  // Hoặc tắt từng tính năng
      "dynamicPowerPlan": true
    }
  }
}
```

### 4. Winget không hoạt động?

Tool sẽ tự động cài Winget nếu chưa có. Nếu vẫn lỗi:

```powershell
# Cài thủ công từ Microsoft Store: "App Installer"
# Hoặc dùng lệnh:
winget source reset --force
```

### 5. Log file ở đâu?

Mặc định: `C:\WinVibe_Log_[timestamp].txt`

Thay đổi trong `config.json`:

```json
{
  "general": {
    "logPath": "D:\\MyLogs\\WinVibe.txt"
  }
}
```

### 6. Tôi muốn thêm driver tự động?

Hiện tại tool chưa hỗ trợ. Bạn có thể:

1. Thêm vào `software_list.json`:
```json
{
  "name": "Dell Command Update",
  "wingetId": "Dell.CommandUpdate",
  "postInstallScript": null,
  "priority": 1
}
```

2. Hoặc viết post-install script gọi driver installer

### 7. Tool có hoạt động trên Windows Server không?

⚠️ **Chưa test**. Tool được thiết kế cho Windows 10/11 desktop. Một số tính năng (như debloat AppX) không khả dụng trên Server.

## 🛡️ Bảo mật & Pháp lý

- ✅ Tool này **KHÔNG** chứa bất kỳ công cụ bẻ khóa nào
- ✅ Chỉ hỗ trợ cài đặt phần mềm hợp pháp qua Winget
- ✅ Post-install scripts chỉ copy settings/configs hợp lệ
- ⚠️ Người dùng tự chịu trách nhiệm về license phần mềm

## 📜 License

MIT License - Xem file [LICENSE](LICENSE) để biết thêm chi tiết.

## 🤝 Đóng góp

Contributions are welcome! Vui lòng:

1. Fork repo
2. Tạo branch mới (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Tạo Pull Request

## 📧 Liên hệ

- **Issues**: [GitHub Issues](https://github.com/yourusername/WinVibe/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/WinVibe/discussions)

## 🙏 Credits

- Developed with ❤️ by WinVibe Team
- Powered by PowerShell 7+ và Winget
- Inspired by Windows optimization community

---

**⭐ Nếu tool hữu ích, hãy cho repo một Star nhé!**
