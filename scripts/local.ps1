param([ValidateSet('check-prerequisites','build','db-init','start-local','stop-local','smoke-test','test','backup','integration-test','restore-test','create-local-account')][string]$Action = 'check-prerequisites')
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$windowsPath = $repo.Replace('\', '/')
$resolved = & wsl -d Ubuntu-24.04 -- wslpath -a $windowsPath
if ($LASTEXITCODE -ne 0) { throw 'Falha ao resolver caminho WSL' }
$linux = ($resolved -join '').Trim()
if ($Action -in @('db-init','integration-test','restore-test')) {
    & wsl -d Ubuntu-24.04 -u root -- bash "$linux/scripts/$Action.sh"
} else {
    & wsl -d Ubuntu-24.04 -- bash "$linux/scripts/$Action.sh"
}
if ($LASTEXITCODE -ne 0) { throw "Falha: $Action ($LASTEXITCODE)" }
