# Stream logcat filtered for Nexus notification debugging.
# Use when `adb` is not on PATH (reads sdk.dir from android/local.properties).

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$localProps = Join-Path $root "android\local.properties"
if (-not (Test-Path $localProps)) {
    Write-Error "Missing $localProps"
}
$sdkLine = Get-Content $localProps | Where-Object { $_ -match '^\s*sdk\.dir=' } | Select-Object -First 1
if (-not $sdkLine) {
    Write-Error "sdk.dir not found in local.properties"
}
$sdkDir = ($sdkLine -replace '^\s*sdk\.dir=', '').Trim()
# Gradle file uses doubled backslashes (E:\\foo\\bar)
$sdkDir = $sdkDir -replace '\\+', '\'
if ($sdkDir -match '^[A-Za-z]:\\') { } else {
    Write-Error "Could not parse sdk.dir from: $sdkLine"
}
$adb = Join-Path $sdkDir "platform-tools\adb.exe"
if (-not (Test-Path $adb)) {
    Write-Error "adb not found at $adb - install Android SDK Platform-Tools."
}

Write-Host "Using: $adb" -ForegroundColor Cyan
Write-Host "Filter: NexusNotifNative, NexusNotif (flutter), ActionBroadcastReceiver" -ForegroundColor Cyan
& $adb logcat -s NexusNotifNative:I flutter:I ActionBroadcastReceiver:E ActionBroadcastReceiver:W ActionBroadcastReceiver:I
