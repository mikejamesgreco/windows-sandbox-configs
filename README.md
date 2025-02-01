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

