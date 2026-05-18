$ErrorActionPreference = 'Stop'
Set-Location 'C:\Users\angen\Documents\kalan\kalan_app'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipPath = (Resolve-Path '.\commandlinetools.zip').Path
Write-Host "Archive path: $zipPath"
try {
    $archive = [System.IO.Compression.ZipFile]::OpenRead($zipPath)
    Write-Host "Archive entries count: $($archive.Entries.Count)"
    foreach ($entry in $archive.Entries) {
        Write-Host "ENTRY: $($entry.FullName)"
    }
    $archive.Dispose()
} catch {
    Write-Host "Archive inspection failed: $_"
}
Write-Host '---'
$cmdDir = 'C:\Users\angen\AppData\Local\Android\sdk\cmdline-tools'
Write-Host "cmdline-tools exists: " (Test-Path $cmdDir)
if (Test-Path $cmdDir) {
    Get-ChildItem -Path $cmdDir -Force | ForEach-Object { Write-Host "SDKDIR: $($_.FullName)" }
}
