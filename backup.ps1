# Módulo de backup e restauração do Seattle
$ErrorActionPreference = 'Stop'
$GitHubBase = 'https://raw.githubusercontent.com/leoklyvert/seattle/main'
$TempRoot = Join-Path $env:TEMP ('Seattle-Backup-' + [guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $TempRoot -Force

function Pausar-Backup {
    Write-Host ''
    Write-Host 'Pressione qualquer tecla para voltar ao Seattle...' -ForegroundColor DarkGray
    [void][System.Console]::ReadKey($true)
}

function Abrir-FerramentaBackup {
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('Backup', 'Restaurar')]
        [string]$Acao
    )

    $fileName = if ($Acao -eq 'Backup') { 'Backup-Perfil-Windows.ps1' } else { 'Restaurar-Perfil-Windows.ps1' }
    $url = "$GitHubBase/$fileName"
    $localScript = Join-Path $TempRoot $fileName

    try {
        Write-Host ''
        Write-Host "Baixando ferramenta de $($Acao.ToLower())..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $url -OutFile $localScript -UseBasicParsing -TimeoutSec 60 -ErrorAction Stop
        if (-not (Test-Path -LiteralPath $localScript) -or (Get-Item -LiteralPath $localScript).Length -eq 0) {
            throw 'O arquivo da ferramenta não foi baixado corretamente.'
        }

        $powershellExe = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'
        $arguments = '-NoProfile -STA -ExecutionPolicy Bypass -File "{0}"' -f $localScript
        $process = Start-Process -FilePath $powershellExe -ArgumentList $arguments -WindowStyle Normal -Wait -PassThru
        if ($process.ExitCode -ne 0) {
            Write-Host "A ferramenta terminou com código $($process.ExitCode)." -ForegroundColor Yellow
            Pausar-Backup
        }
    }
    catch {
        Write-Host ''
        Write-Host "Não foi possível abrir a ferramenta: $($_.Exception.Message)" -ForegroundColor Red
        Pausar-Backup
    }
}

try {
    do {
        Clear-Host
        Write-Host ''
        Write-Host '============================================================' -ForegroundColor Cyan
        Write-Host '       BACKUP E RESTAURAÇÃO - SEATTLE / LR TECNOLOGIA' -ForegroundColor Cyan
        Write-Host '============================================================' -ForegroundColor Cyan
        Write-Host ''
        Write-Host '1 - Fazer backup para HD externo'
        Write-Host '2 - Restaurar backup para este computador'
        Write-Host '0 - Voltar ao menu principal'
        Write-Host ''

        $option = [System.Console]::ReadKey($true).KeyChar
        switch ($option) {
            '1' { Abrir-FerramentaBackup -Acao 'Backup' }
            '2' { Abrir-FerramentaBackup -Acao 'Restaurar' }
            '0' { return }
        }
    } while ($true)
}
finally {
    Remove-Item -LiteralPath $TempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

