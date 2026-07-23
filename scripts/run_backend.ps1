$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $PSScriptRoot
$backendRoot = Join-Path $projectRoot "backend"
$envPath = Join-Path $backendRoot ".env"

if (-not (Test-Path -LiteralPath $envPath)) {
    throw "Create backend\.env from backend\.env.example and add ANTHROPIC_API_KEY first."
}

Set-Location -LiteralPath $backendRoot
uv sync
uv run uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
