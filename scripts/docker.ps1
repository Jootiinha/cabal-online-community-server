[CmdletBinding()]
param(
    [ValidateSet('init','build','up','down','status','logs','smoke-test','create-local-account','backup','migrate','test')]
    [string]$Action = 'up'
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$resolved = & wsl -d Ubuntu-24.04 -- wslpath -a $repo.Replace('\', '/')
if ($LASTEXITCODE -ne 0) { throw 'Falha ao resolver caminho WSL' }
$linux = ($resolved -join '').Trim()
& wsl -d Ubuntu-24.04 -- bash "$linux/scripts/docker-local.sh" $Action
if ($LASTEXITCODE -ne 0) { throw "Docker: falha em $Action ($LASTEXITCODE)" }
