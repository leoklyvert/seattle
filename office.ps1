# ============================================================
# LR TECNOLOGIA
# INSTALAÇÃO DO OFFICE
# ============================================================

function Mostrar-Cabecalho {

    Clear-Host

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "                    LR TECNOLOGIA" -ForegroundColor Cyan
    Write-Host "                 INSTALACAO DO OFFICE" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Pausar {

    Write-Host ""
    Write-Host "Pressione qualquer tecla para continuar..." -ForegroundColor Yellow
    [System.Console]::ReadKey($true) | Out-Null
}

function Instalar-Office {

    $PastaOffice = Join-Path $env:TEMP "LR-Office"
    $ArquivoZip = Join-Path $env:TEMP "LR-Office.zip"
    $UrlOffice = "https://lrtecnologia.net.br/seattle/office/Office.zip"
    $ArquivoBat = $null

    try {

        Mostrar-Cabecalho

        Write-Host "Preparando instalacao..." -ForegroundColor Cyan
        Write-Host ""

        if (Test-Path $PastaOffice) {
            Remove-Item $PastaOffice -Recurse -Force -ErrorAction SilentlyContinue
        }

        if (Test-Path $ArquivoZip) {
            Remove-Item $ArquivoZip -Force -ErrorAction SilentlyContinue
        }

        New-Item `
            -ItemType Directory `
            -Path $PastaOffice `
            -Force `
            -ErrorAction Stop | Out-Null

        Write-Host "Baixando arquivos do Office..." -ForegroundColor Cyan

        Invoke-WebRequest `
            -Uri $UrlOffice `
            -OutFile $ArquivoZip `
            -UseBasicParsing `
            -ErrorAction Stop

        if (-not (Test-Path $ArquivoZip)) {
            throw "O arquivo Office.zip nao foi baixado."
        }

        Write-Host "Download concluido." -ForegroundColor Green
        Write-Host ""

        Write-Host "Extraindo arquivos..." -ForegroundColor Cyan

        Expand-Archive `
            -Path $ArquivoZip `
            -DestinationPath $PastaOffice `
            -Force `
            -ErrorAction Stop

        $ArquivoBat = Get-ChildItem `
            -Path $PastaOffice `
            -Filter "office.bat" `
            -File `
            -Recurse `
            -ErrorAction SilentlyContinue |
            Select-Object -First 1

        if ($null -eq $ArquivoBat) {
            throw "O arquivo office.bat nao foi encontrado apos a extracao."
        }

        $PastaBat = $ArquivoBat.Directory.FullName

        Write-Host "Arquivos extraidos." -ForegroundColor Green
        Write-Host "Arquivo de instalacao localizado." -ForegroundColor Green
        Write-Host ""

        Write-Host "Iniciando instalacao do Office..." -ForegroundColor Cyan
        Write-Host ""

        $ArgumentosBat = '/d /c call "' + $ArquivoBat.FullName + '"'

        $ProcessoBat = Start-Process `
            -FilePath "cmd.exe" `
            -ArgumentList $ArgumentosBat `
            -WorkingDirectory $PastaBat `
            -Wait `
            -PassThru `
            -ErrorAction Stop

        if ($ProcessoBat.ExitCode -ne 0) {
            throw "O instalador retornou o codigo $($ProcessoBat.ExitCode)."
        }

        Write-Host ""
        Write-Host "Processo de instalacao concluido." -ForegroundColor Green
        Write-Host ""

        if (Test-Path $ArquivoZip) {
            Remove-Item $ArquivoZip -Force -ErrorAction SilentlyContinue
        }

        Write-Host "Limpando arquivos temporarios..." -ForegroundColor Cyan

        if (Test-Path $PastaOffice) {
            Remove-Item $PastaOffice -Recurse -Force -ErrorAction SilentlyContinue
        }

        Write-Host "Arquivos temporarios removidos." -ForegroundColor Green
        Write-Host ""
        Write-Host "Instalacao do Office finalizada." -ForegroundColor Green
    }
    catch {

        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Red
        Write-Host "           ERRO AO INSTALAR O OFFICE" -ForegroundColor Red
        Write-Host "============================================================" -ForegroundColor Red
        Write-Host ""
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host ""

        Write-Host "Os arquivos temporarios foram mantidos para diagnostico." -ForegroundColor Yellow
    }

    Pausar
}

Instalar-Office
