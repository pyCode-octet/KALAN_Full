$sdkRoot = Join-Path $env:USERPROFILE "AppData\Local\Android\sdk"
$cmdlineToolsRoot = Join-Path $sdkRoot "cmdline-tools"
$latestPath = Join-Path $cmdlineToolsRoot "latest"
$zipFile = "C:\Users\angen\Documents\kalan\kalan_app\commandlinetools.zip"

Write-Host "Checking for ZIP file..."
if (-not (Test-Path $zipFile)) {
    Write-Error "Zip file not found at $zipFile"
    exit 1
}

Write-Host "Cleaning up old cmdline-tools..."
if (Test-Path $cmdlineToolsRoot) {
    Remove-Item -Recurse -Force $cmdlineToolsRoot
}

Write-Host "Creating directory structure..."
New-Item -ItemType Directory -Force -Path $cmdlineToolsRoot | Out-Null

Write-Host "Extracting ZIP..."
$tempExtract = Join-Path $cmdlineToolsRoot "temp"
New-Item -ItemType Directory -Force -Path $tempExtract | Out-Null
Expand-Archive -Path $zipFile -DestinationPath $tempExtract -Force

Write-Host "Organizing files..."
# The zip usually contains a 'cmdline-tools' folder
$innerFolder = Get-ChildItem $tempExtract | Where-Object { $_.PSIsContainer -and $_.Name -eq "cmdline-tools" } | Select-Object -First 1

if ($innerFolder) {
    Write-Host "Found inner cmdline-tools folder, moving to 'latest'..."
    Move-Item -Path $innerFolder.FullName -Destination $latestPath
    Remove-Item -Recurse -Force $tempExtract
} else {
    Write-Host "No inner cmdline-tools folder found, renaming temp to 'latest'..."
    Move-Item -Path $tempExtract -Destination $latestPath
}

$sdkManager = Join-Path $latestPath "bin\sdkmanager.bat"
if (Test-Path $sdkManager) {
    Write-Host "SUCCESS: sdkmanager.bat found at $sdkManager"
    
    Write-Host "Installing platform-tools and android-33..."
    & $sdkManager --sdk_root=$sdkRoot "platform-tools" "platforms;android-33" "build-tools;33.0.2"
    
    Write-Host "Accepting licenses..."
    # Note: this might hang if it asks for input. We try to pipe 'y'
    # but flutter doctor --android-licenses is better for user interaction.
} else {
    Write-Error "FAILURE: sdkmanager.bat NOT found at $sdkManager"
    Get-ChildItem -Path $latestPath -Recurse | Select-Object FullName
}
