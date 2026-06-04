$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$flutter = 'C:\Users\BearOwner\AppData\Local\Android\Sdk\flutter\bin\flutter.bat'
$releaseDir = 'D:\YBS_Project\release_v1.0.0'

if (-not (Test-Path $flutter)) {
  throw "Flutter SDK not found: $flutter"
}

Set-Location $projectRoot

& $flutter analyze
& $flutter test
& $flutter build appbundle --release
& $flutter build apk --release --target-platform android-arm64

New-Item -ItemType Directory -Force -Path $releaseDir | Out-Null

Copy-Item -Force `
  "$projectRoot\build\app\outputs\bundle\release\app-release.aab" `
  "$releaseDir\app-release.aab"

Copy-Item -Force `
  "$projectRoot\build\app\outputs\flutter-apk\app-release.apk" `
  "$releaseDir\app-arm64-release.apk"

if (Test-Path "$projectRoot\RELEASE_NOTES.md") {
  Copy-Item -Force "$projectRoot\RELEASE_NOTES.md" "$releaseDir\RELEASE_NOTES.md"
}

Get-ChildItem $releaseDir |
  Where-Object { $_.Name -in @('app-release.aab', 'app-arm64-release.apk', 'RELEASE_NOTES.md') } |
  Select-Object Name, @{ Name = 'SizeMB'; Expression = { '{0:N1}' -f ($_.Length / 1MB) } }, LastWriteTime
