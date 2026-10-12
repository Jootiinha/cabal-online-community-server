# Starts every backend service through Docker Compose on Windows Docker Desktop.
[CmdletBinding()]
param(
    [switch]$FollowLogs
)

$ErrorActionPreference = 'Stop'
$dockerScript = Join-Path $PSScriptRoot 'scripts\docker.ps1'

function Invoke-BackendAction([string]$Action) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $dockerScript $Action
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao executar Docker Compose: $Action (codigo $LASTEXITCODE)"
    }
}

Write-Host 'Iniciando MariaDB, MasterServer, LoginServer e GameServer...'
Invoke-BackendAction 'up'
Invoke-BackendAction 'smoke-test'
Write-Host 'Todos os servicos do backend estao prontos.'

if ($FollowLogs) {
    Write-Host 'Acompanhando logs. Ctrl+C encerra o acompanhamento; os containers continuam ativos.'
    Invoke-BackendAction 'logs-follow'
}
