$ErrorActionPreference = 'Stop'
$env:ANDROID_SDK_ROOT = "$env:USERPROFILE\AppData\Local\Android\sdk"
$env:Path = $env:Path + ";" + $env:ANDROID_SDK_ROOT + "platform-tools;" + $env:ANDROID_SDK_ROOT + "cmdline-tools\\latest\\bin"
Write-Host "ANDROID_SDK_ROOT=$env:ANDROID_SDK_ROOT"
Write-Host "PATH contains platform-tools: " (Test-Path (Join-Path $env:ANDROID_SDK_ROOT 'platform-tools'))
flutter doctor -v
