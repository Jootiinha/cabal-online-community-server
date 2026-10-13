[CmdletBinding()]
param(
    [ValidateSet('init','build','up','down','status','logs','logs-follow','smoke-test','create-local-account','backup','migrate','test')]
    [string]$Action = 'up'
)
$ErrorActionPreference = 'Stop'
$repo = Split-Path $PSScriptRoot -Parent
$candidates = @(
    "$env:LOCALAPPDATA\Programs\DockerDesktop\resources\bin\docker.exe",
    "$env:ProgramFiles\Docker\Docker\resources\bin\docker.exe"
)
$dockerCommand = Get-Command docker.exe -ErrorAction SilentlyContinue
if ($dockerCommand) { $docker = $dockerCommand.Source }
else { $docker = $candidates | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1 }
if (-not $docker) { throw 'Docker Desktop nao encontrado. Instale e inicie o Docker Desktop.' }
$originalPath = $env:PATH
$env:PATH = (Split-Path $docker -Parent) + ';' + $env:PATH

function Invoke-Compose {
    & $docker --context desktop-linux compose --project-directory $repo --file (Join-Path $repo 'compose.yaml') @args
    if ($LASTEXITCODE -ne 0) { throw "Docker Compose falhou (codigo $LASTEXITCODE). Verifique se o Docker Desktop esta iniciado com containers Linux." }
}
function Initialize-Environment {
    $envPath = Join-Path $repo '.env'
    $text = if (Test-Path -LiteralPath $envPath) { [IO.File]::ReadAllText($envPath) } else { '' }
    foreach ($key in @('DB_PASSWORD','DB_ROOT_PASSWORD')) {
        $match = [regex]::Match($text, "(?m)^$key=([^\r\n]*)")
        if ($match.Success -and $match.Groups[1].Value) {
            if ($match.Groups[1].Value -notmatch '^[A-Za-z0-9@#]{12,128}$') { throw "$key deve conter 12..128 caracteres: letras, numeros, @ ou #." }
            continue
        }
        $bytes = New-Object byte[] 24
        $rng = [Security.Cryptography.RandomNumberGenerator]::Create()
        try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
        $value = ([BitConverter]::ToString($bytes)).Replace('-','').ToLowerInvariant()
        if ($match.Success) { $text = [regex]::Replace($text, "(?m)^$key=[^\r\n]*", "$key=$value") }
        else { $text = $text.TrimEnd() + "`n$key=$value`n" }
    }
    [IO.File]::WriteAllText($envPath, $text, (New-Object Text.UTF8Encoding $false))
    New-Item -ItemType Directory -Path (Join-Path $repo '.runtime') -Force | Out-Null
}

Push-Location $repo
try {
    switch ($Action) {
        'init' { Initialize-Environment }
        'build' { Initialize-Environment; Invoke-Compose build }
        'up' { Initialize-Environment; Invoke-Compose up -d --build --wait --wait-timeout 180 }
        'down' { Invoke-Compose down }
        'status' { Invoke-Compose ps }
        'logs' { Invoke-Compose logs --tail=100 }
        'logs-follow' { Invoke-Compose logs --follow --tail=100 }
        'smoke-test' {
            Invoke-Compose ps
            foreach ($service in @('database','masterserver','loginserver','gameserver')) {
                $id = Invoke-Compose ps -q $service
                if (-not $id) { throw "Container ausente: $service" }
                $health = & $docker --context desktop-linux inspect -f '{{.State.Health.Status}}' $id
                if ($LASTEXITCODE -ne 0 -or $health -ne 'healthy') { throw "Servico nao saudavel: $service" }
            }
            foreach ($port in @(38101,38111)) {
                $client = New-Object Net.Sockets.TcpClient
                try {
                    if (-not $client.ConnectAsync('127.0.0.1',$port).Wait(5000)) { throw "Timeout na porta $port" }
                    Write-Host "Windows TCP OK: $port"
                } finally { $client.Dispose() }
            }
        }
        'create-local-account' { Invoke-Compose run --rm localaccount }
        'backup' {
            $backupDir = Join-Path $repo '.runtime\backups'
            New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
            $dump = Invoke-Compose exec -T database sh -c 'MYSQL_PWD=$MARIADB_ROOT_PASSWORD exec mariadb-dump --skip-ssl -uroot --single-transaction --databases cabal_login cabal_world'
            $target = Join-Path $backupDir ("desktop-" + (Get-Date -Format 'yyyyMMdd-HHmmss') + '.sql')
            [IO.File]::WriteAllLines($target, [string[]]$dump, (New-Object Text.UTF8Encoding $false))
            Write-Host "Backup: $target"
        }
        'migrate' {
            Initialize-Environment
            Invoke-Compose build
            Invoke-Compose up -d database --wait --wait-timeout 180
            $linux = (& wsl -d Ubuntu-24.04 -- wslpath -a $repo.Replace('\','/') | Out-String).Trim()
            if ($LASTEXITCODE -ne 0) { throw 'Falha ao resolver caminho WSL.' }
            $linuxDocker = (& wsl -d Ubuntu-24.04 -- wslpath -a $docker.Replace('\','/') | Out-String).Trim()
            if ($LASTEXITCODE -ne 0) { throw 'Falha ao resolver cliente Docker Desktop.' }
            & wsl -d Ubuntu-24.04 -- python3 "$linux/scripts/transfer-desktop.py" $linuxDocker
            if ($LASTEXITCODE -ne 0) { throw 'Falha na transferencia do banco para Docker Desktop.' }
            Invoke-Compose up -d --wait --wait-timeout 180
        }
        'test' {
            & $docker --context desktop-linux build --target build -t cabal-builder:local $repo
            if ($LASTEXITCODE -ne 0) { throw 'Falha ao construir builder.' }
            & $docker --context desktop-linux run --rm -v "${repo}\backend:/src" -w /src cabal-builder:local go test ./...
            if ($LASTEXITCODE -ne 0) { throw 'Falha nos testes Go.' }
        }
    }
} finally { Pop-Location; $env:PATH = $originalPath }
