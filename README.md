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
| **`common/`**          | Not a sandbox but rather a common folder for shared utilities |
| **`base/`**            | A minimal sandbox with winget, 7zip, jdk17 |
| **`java-minimal/`**    | A minimal sandbox with winget, 7zip, jdk17, git, eclipse |
| **`java-tomcat/`**    | A minimal sandbox with winget, 7zip, jdk17, git, eclipse, apache tomcat|
| **`java-maven-ant-tomcat/`**    | A modest sandbox with winget, 7zip, jdk17, git, eclipse, apache tomcat, apache maven, apache ant|

## 🚀 Getting Started
### **Prerequisites**
- **Windows 10/11 Pro, Enterprise, or Education** (Windows Sandbox is not available on Home editions).
- **Windows Sandbox enabled**:  
  Run the following command in PowerShell as Administrator:
  ```powershell
  Enable-WindowsOptionalFeature -FeatureName "Containers-DisposableClientVM" -Online -NoRestart

## ⚠️ Important: Git LFS Setup Required

This repository uses **Git Large File Storage (LFS)** for storing large files like installers. Before cloning the repo, you **must install Git LFS**:

```bash
git lfs install
```

Then, clone the repository normally:

```bash
git clone https://github.com/your-repo/windows-sandbox-configs.git
```

### 🛑 LFS Download Failures? Bandwidth May Be Exceeded
GitHub LFS has a **1GB monthly bandwidth limit**. If you see errors when downloading LFS-tracked files, it may be due to exceeding this limit. In this case, manually download the required files from their respective vendor or project site and place them in the appropriate `installers/` directory.

For example, if the Eclipse installer fails to download:
1. Go to the official Eclipse website: [https://www.eclipse.org/downloads/](https://www.eclipse.org/downloads/)
2. Download the required version.
3. Place it in the `installers/` directory manually.

This ensures your sandbox configurations work correctly even if GitHub LFS bandwidth is exceeded.

# Windows Sandbox Proxy Setup

This script (`setup_sandbox_proxy.bat`) configures a **port proxy** using Windows `netsh` to forward traffic from your **local machine (laptop)** to a **Windows Sandbox running Tomcat**.

## 🛠️ How It Works
- Reads the **Sandbox IP** from `C:\common\sandbox_ip_address.txt`.
- Detects the **Laptop’s Local IP Address** automatically.
- Uses **Windows `netsh`** to forward port `8080` from the laptop to the sandbox.
- Supports **adding, removing, and checking the proxy status**.

## 🚀 Usage

### **1️⃣ Add the Proxy Route**
This will forward `192.168.50.111:8080` to the **sandbox's IP and port**.
```sh
C:\common\setup_sandbox_proxy.bat add (or remove)
