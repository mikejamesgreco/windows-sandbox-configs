# Windows Sandbox Configurations

This repository contains various **Windows Sandbox configurations** (`.wsb` files) for different use cases. These sandboxes allow users to quickly spin up **isolated, disposable environments** with pre-configured settings, tools, and scripts.

## 📌 Features
- Predefined sandbox configurations for **development, security testing, secure browsing, and more**.
- **Auto-installation scripts** for software and utilities inside the sandbox.
- Easily customizable **sandbox settings** (networking, mapped folders, logon commands).
- Uses **Windows Sandbox**—no need for full virtual machines!

## 📂 Sandbox Configurations
| Sandbox Name           | Description |
|------------------------|-------------|
| **`base/`**           | A minimal sandbox with no extra configurations. |

## 🚀 Getting Started
### **Prerequisites**
- **Windows 10/11 Pro, Enterprise, or Education** (Windows Sandbox is not available on Home editions).
- **Windows Sandbox enabled**:  
  Run the following command in PowerShell as Administrator:
  ```powershell
  Enable-WindowsOptionalFeature -FeatureName "Containers-DisposableClientVM" -Online -NoRestart
