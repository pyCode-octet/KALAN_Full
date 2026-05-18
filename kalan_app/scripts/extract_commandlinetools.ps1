$ErrorActionPreference = 'Stop'
$zip = Join-Path $PSScriptRoot '..\commandlinetools.zip' | Resolve-Path -ErrorAction SilentlyContinue
if (-not $zip) { Write-Error 'commandlinetools.zip not found in project root'; exit 1 }
$zipPath = $zip.Path
$dest = Join-Path $env:USERPROFILE 'AppData\Local\Android\sdk\cmdline-tools\\latest'
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Write-Host "Extracting $zipPath to $dest"
Expand-Archive -Path $zipPath -DestinationPath $dest -Force
# If extraction created an inner folder (cmdline-tools), move its contents up
$inner = Get-ChildItem $dest | Where-Object { $_.PSIsContainer } | Select-Object -First 1
if ($inner -and (Test-Path (Join-Path $inner.FullName 'bin\sdkmanager.bat') -PathType Leaf -ErrorAction SilentlyContinue)) {
    # already correct
} elseif ($inner) {
    Write-Host "Moving inner folder contents"
    Move-Item -Path (Join-Path $inner.FullName '\\*') -Destination $dest -Force
    Remove-Item -Path $inner.FullName -Recurse -Force
}
Write-Host "Listing dest contents:"
Get-ChildItem -Path $dest -Recurse | Select-Object FullName | Format-Table -AutoSize
