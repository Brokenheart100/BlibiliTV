[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$AvdName = 'Mamba_TV_API36',
    [ValidateRange(5554, 5682)][int]$Port = 5556,
    [string]$AndroidSdk = $env:ANDROID_HOME
)

$ErrorActionPreference = 'Stop'
if ($Port % 2 -ne 0) { throw 'Emulator console port must be even.' }
if (-not $AndroidSdk) { $AndroidSdk = $env:ANDROID_SDK_ROOT }
if (-not $AndroidSdk) {
    $properties = Join-Path $PSScriptRoot '../android/local.properties'
    if (Test-Path -LiteralPath $properties) {
        $sdkLine = Get-Content -LiteralPath $properties |
            Where-Object { $_ -match '^sdk\.dir=' } | Select-Object -First 1
        if ($sdkLine) {
            $AndroidSdk = $sdkLine.Substring(8).Replace('\:', ':').Replace('\\', '\')
        }
    }
}
if (-not $AndroidSdk) { throw 'Set ANDROID_HOME or pass -AndroidSdk.' }
$emulator = Join-Path $AndroidSdk 'emulator/emulator.exe'
if (-not (Test-Path -LiteralPath $emulator)) { throw "Emulator not found: $emulator" }
if ($AvdName -notin @(& $emulator -list-avds)) { throw "AVD not found: $AvdName" }

# DirectSound restores host output on the verified Windows HDMI setup.
# Never stop another AVD, wipe data, save snapshots, or change host master volume.
$launchArgs = @(
    '-avd', $AvdName, '-port', "$Port",
    '-no-snapshot-load', '-no-snapshot-save',
    '-gpu', 'host', '-memory', '2048', '-cores', '4',
    '-audio', 'dsound'
)
if ($PSCmdlet.ShouldProcess("$AvdName on emulator-$Port", 'Launch with DirectSound')) {
    Start-Process -FilePath $emulator -ArgumentList $launchArgs -WindowStyle Hidden
    Write-Host "Starting $AvdName on emulator-$Port with DirectSound."
}
