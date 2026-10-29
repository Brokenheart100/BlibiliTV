param(
    [string]$Device = 'emulator-5556',
    [string]$AdbPath = 'adb',
    [string]$LogPath = (Join-Path (Split-Path $PSScriptRoot) '.m0/m8-better-final.log')
)
$ErrorActionPreference = 'Stop'
if ((& $AdbPath -s $Device get-state) -ne 'device') {
    throw 'The selected ADB device is not ready.'
}
function Wait-M8Marker([string]$Marker) {
    $deadline = [DateTime]::UtcNow.AddMinutes(12)
    while ([DateTime]::UtcNow -lt $deadline) {
        $content = if (Test-Path -LiteralPath $LogPath) {
            Get-Content -LiteralPath $LogPath -Raw
        } else { '' }
        if ($content -and $content.Contains($Marker)) { return }
        if ($content -match 'Some tests failed|Gradle task .* failed|Test failed|BUILD FAILED') {
            throw 'Native validation failed before the expected host marker.'
        }
        Start-Sleep -Milliseconds 500
    }
    throw "Host marker timeout: $Marker"
}
for ($cycle = 0; $cycle -lt 10; $cycle++) {
    Wait-M8Marker "M8_HOME_WAIT_$cycle"
    & $AdbPath -s $Device shell input keyevent 3 | Out-Null
    # Restore independently of Flutter frames; the background app has no vsync.
    Start-Sleep -Seconds 2
    & $AdbPath -s $Device shell am start -W -n 'app.mamba.mambatv.validation/app.mamba.mambatv.MainActivity' | Out-Null
    Wait-M8Marker "M8_HOME_DONE_$cycle"
    Write-Output "HOME cycle $($cycle + 1) passed"
}
