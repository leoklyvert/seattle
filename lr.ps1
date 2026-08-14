function Executar-Diagnostico {

    param(
        [string]$Cliente,
        [string]$TipoCliente
    )

    Clear-Host

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "                 DIAGNÓSTICO PREVENTIVO" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Cliente      : " -NoNewline
    Write-Host $Cliente -ForegroundColor Yellow

    Write-Host "Tipo         : " -NoNewline
    Write-Host $TipoCliente -ForegroundColor Yellow

    Write-Host "Computador   : " -NoNewline
    Write-Host $env:COMPUTERNAME -ForegroundColor Yellow

    Write-Host ""

    if (!(Test-Path $ModuloManutencao)) {

        Write-Host "ERRO: manutencao.ps1 não encontrado." -ForegroundColor Red
        Write-Host $ModuloManutencao -ForegroundColor Yellow

        Pausar
        return
    }

    try {

        & $ModuloManutencao `
            -Cliente $Cliente `
            -TipoCliente $TipoCliente

    }
    catch {

        Write-Host ""
        Write-Host "ERRO AO EXECUTAR DIAGNÓSTICO" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Write-Host ""

        Pausar
    }
}
