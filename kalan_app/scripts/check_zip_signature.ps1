$ErrorActionPreference = 'Stop'
Set-Location 'C:\Users\angen\Documents\kalan\kalan_app'
$path = Join-Path $PWD 'commandlinetools.zip'
if (-not (Test-Path $path)) { Write-Host "Zip not found: $path"; exit 1 }
$bytes = [System.IO.File]::ReadAllBytes($path)[0..3]
Write-Host ($bytes | ForEach-Object { $_.ToString('X2') })
Write-Host "Size: " ([System.IO.File]::GetLength($path))
