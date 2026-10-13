# Starts the complete local development environment and then opens the client.
# Run from PowerShell:
#   powershell -ExecutionPolicy Bypass -File .\scripts\Start-CabalLocal.ps1
[CmdletBinding()]
param(
    [switch]$NoClient,
    [string]$ClientExecutable
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
if (-not $ClientExecutable) {
    $ClientExecutable = Join-Path $repoRoot '.client\CabalMain.exe'
}
$credentials = Join-Path $repoRoot '.runtime\player-credentials.json'

function Invoke-ProjectAction([string]$action) {
    & powershell -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'docker.ps1') $action
    if ($LASTEXITCODE -ne 0) {
        throw "Ação local falhou: $action ($LASTEXITCODE)"
    }
}

Write-Host 'Iniciando MariaDB e serviços Cabal no Docker...'
Invoke-ProjectAction 'up'

Write-Host 'Validando banco, processos e portas...'
Invoke-ProjectAction 'smoke-test'

if (-not (Test-Path -LiteralPath $credentials)) {
    Write-Host 'Criando a conta localplayer...'
    Invoke-ProjectAction 'create-local-account'
}

Write-Host "Credenciais locais: $credentials"
if ($NoClient) {
    Write-Host 'Serviços ativos. Cliente não aberto por -NoClient.'
    exit 0
}

if (-not (Test-Path -LiteralPath $clientExecutable)) {
    throw "Cliente não encontrado: $clientExecutable"
}

Write-Host 'Abrindo cabalmain.exe...'
Start-Process -FilePath $clientExecutable -WorkingDirectory (Split-Path $clientExecutable)
