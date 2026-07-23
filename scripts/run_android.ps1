param(
    [Parameter(Mandatory = $true)]
    [string]$DeviceId,

    [Parameter(Mandatory = $true)]
    [string]$PcLanIp
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$mobileRoot = Join-Path $projectRoot "mobile"
$apiBaseUrl = "http://${PcLanIp}:8000"

Set-Location -LiteralPath $mobileRoot
flutter pub get
flutter run -d $DeviceId --dart-define="API_BASE_URL=$apiBaseUrl"
