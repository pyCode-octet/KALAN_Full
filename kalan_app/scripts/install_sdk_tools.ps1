$ErrorActionPreference = 'Stop'
$sdkRoot = $env:ANDROID_SDK_ROOT
if (-not $sdkRoot) { $sdkRoot = "$env:USERPROFILE\AppData\Local\Android\sdk" }
New-Item -ItemType Directory -Force -Path $sdkRoot | Out-Null
$zipUrl = 'https://dl.google.com/android/repository/commandlinetools-win-9477386_latest.zip'
$zipFile = Join-Path $PWD 'commandlinetools.zip'
Write-Host "Downloading $zipUrl to $zipFile"
Invoke-WebRequest -Uri $zipUrl -OutFile $zipFile
$dest = Join-Path $sdkRoot 'cmdline-tools\latest'
if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
New-Item -ItemType Directory -Force -Path $dest | Out-Null
Write-Host "Extracting to $dest"
Expand-Archive -Path $zipFile -DestinationPath $dest -Force
if (-not (Test-Path (Join-Path $dest 'bin\sdkmanager.bat'))) {
    $inner = Get-ChildItem $dest | Where-Object { $_.PSIsContainer } | Select-Object -First 1
    Move-Item -Path (Join-Path $dest $inner.Name '\*') -Destination $dest
    Remove-Item (Join-Path $dest $inner.Name) -Recurse -Force
}
$sdkb = Join-Path $dest 'bin\sdkmanager.bat'
Write-Host "Running sdkmanager: $sdkb"
& $sdkb --sdk_root=$sdkRoot 'platform-tools' 'platforms;android-33' 'build-tools;33.0.2'
Write-Host "Done installing SDK components."
