param(
    [string]$Device = 'emulator-5554',
    [string]$AdbPath = 'adb',
    [ValidateSet('app.mamba.mambatv', 'app.mamba.mambatv.validation')]
    [string]$ApplicationId = 'app.mamba.mambatv.validation',
    [string]$LogPath = (Join-Path (Split-Path $PSScriptRoot) '.m0/m5-native-profile.log')
)

$ErrorActionPreference = 'Stop'
if ((& $AdbPath -s $Device get-state) -ne 'device') {
    throw 'The selected ADB device is not ready.'
}

function Wait-M5Marker([string]$Marker) {
    $deadline = [DateTime]::UtcNow.AddMinutes(12)
    while ([DateTime]::UtcNow -lt $deadline) {
        # Get-Content shares the log with Flutter's writer on Windows.
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

try {
    foreach ($mode in @('HOME', 'SLEEP')) {
        for ($cycle = 0; $cycle -lt 10; $cycle++) {
            Wait-M5Marker "M5_${mode}_WAIT_$cycle"
            $key = if ($mode -eq 'HOME') { '3' } else { '223' }
            & $AdbPath -s $Device shell input keyevent $key | Out-Null
            if ($mode -eq 'HOME') {
                Wait-M5Marker "M5_${mode}_PAUSED_$cycle"
            } else {
                # No vsync is expected while asleep; wake independently of a frame.
                Start-Sleep -Seconds 2
                & $AdbPath -s $Device shell input keyevent 224 | Out-Null
            }
            & $AdbPath -s $Device shell am start -W -n "$ApplicationId/app.mamba.mambatv.MainActivity" | Out-Null
            Wait-M5Marker "M5_${mode}_DONE_$cycle"
            Write-Output "$mode cycle $($cycle + 1) passed"
        }
    }
} finally {
    & $AdbPath -s $Device shell input keyevent 224 | Out-Null
}
