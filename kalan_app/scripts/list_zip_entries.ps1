Add-Type -AssemblyName System.IO.Compression.FileSystem
$zipPath = Join-Path $PSScriptRoot '..\commandlinetools.zip' -Resolve
if (-not (Test-Path $zipPath)) { Write-Error "Zip not found: $zipPath"; exit 1 }
[System.IO.Compression.ZipFile]::OpenRead($zipPath).Entries | ForEach-Object { Write-Output $_.FullName }
