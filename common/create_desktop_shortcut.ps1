param (
    [string]$ShortcutName,
    [string]$TargetPath,
    [string]$WorkingDirectory = "",
    [string]$Arguments = ""
)

# Get the desktop path
$DesktopPath = [System.Environment]::GetFolderPath("Desktop")

# Define full shortcut path
$ShortcutPath = [System.IO.Path]::Combine($DesktopPath, "$ShortcutName.lnk")

# Create WScript Shell Object
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutPath)

# Set target path
$Shortcut.TargetPath = $TargetPath

# Set working directory (defaults to the target's folder if not provided)
if ($WorkingDirectory -eq "") {
    $Shortcut.WorkingDirectory = [System.IO.Path]::GetDirectoryName($TargetPath)
} else {
    $Shortcut.WorkingDirectory = $WorkingDirectory
}

# Set arguments if provided
if ($Arguments -ne "") {
    $Shortcut.Arguments = $Arguments
}

# Save shortcut
$Shortcut.Save()