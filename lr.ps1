# ============================================================
# LR TECNOLOGIA
# ASSISTENTE TÉCNICO
# Versão: 1.2.0
# ============================================================

Clear-Host

# ============================================================
# CONFIGURAÇÕES
# ============================================================

$BaseURL = "https://github.com/leoklyvert/seattle/raw/refs/heads/main"

$UrlProgramas = "$BaseURL/programas.ps1"
$UrlOffice = "$BaseURL/office.ps1"
$UrlPersonalizacao = "$BaseURL/personalizacao.ps1"

# ============================================================
# FUNÇÃO - EXECUTAR MÓDULO
# ============================================================

function Executar-Modulo {

    param (
        [string]$NomeModulo,
        [string]$UrlModulo
    )

    Clear-Host

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "                  LR TECNOLOGIA" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Modulo: $NomeModulo" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Carregando modulo..." -ForegroundColor Cyan
    Write-Host ""

    try {

        # Baixa o conteúdo do script
        $Script = Invoke-RestMethod `
            -Uri $UrlModulo `
            -UseBasicParsing `
            -ErrorAction Stop

        if ([string]::IsNullOrWhiteSpace($Script)) {

            throw "O arquivo retornado pelo GitHub está vazio."
        }

        Write-Host "Modulo carregado com sucesso." -ForegroundColor Green
        Write-Host ""
        Write-Host "Iniciando..." -ForegroundColor Cyan
        Write-Host ""

        # Executa o conteúdo recebido
        Invoke-Expression $Script

    }
    catch {

        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Red
        Write-Host "ERRO AO EXECUTAR O MODULO" -ForegroundColor Red
        Write-Host "============================================================" -ForegroundColor Red
        Write-Host ""
        Write-Host "Modulo: $NomeModulo" -ForegroundColor Yellow
        Write-Host ""
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host ""
    }
}

# ============================================================
# MENU PRINCIPAL
# ============================================================

while ($true) {

    Clear-Host

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "                       LR TECNOLOGIA" -ForegroundColor Cyan
    Write-Host "                    ASSISTENTE TECNICO" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1 - Instalacao de Programas" -ForegroundColor White
    Write-Host "2 - Instalar Office" -ForegroundColor White
    Write-Host "3 - Personalizacao" -ForegroundColor White
    Write-Host "0 - Sair" -ForegroundColor White
    Write-Host ""
    Write-Host "Escolha uma opcao:" -ForegroundColor Yellow

    # ========================================================
    # LÊ UMA ÚNICA TECLA
    # Não precisa pressionar ENTER
    # ========================================================

    $Tecla = [System.Console]::ReadKey($true)

    switch ($Tecla.KeyChar) {

        # ====================================================
        # OPÇÃO 1 - PROGRAMAS
        # ====================================================

        "1" {

            Executar-Modulo `
                -NomeModulo "Instalacao de Programas" `
                -UrlModulo $UrlProgramas

            Write-Host ""
            Write-Host "Pressione qualquer tecla para voltar ao menu..." -ForegroundColor Yellow

            [System.Console]::ReadKey($true) | Out-Null
        }

        # ====================================================
        # OPÇÃO 2 - OFFICE
        # ====================================================

        "2" {

            Executar-Modulo `
                -NomeModulo "Instalacao do Office" `
                -UrlModulo $UrlOffice

            Write-Host ""
            Write-Host "Pressione qualquer tecla para voltar ao menu..." -ForegroundColor Yellow

            [System.Console]::ReadKey($true) | Out-Null
        }

        # ====================================================
        # OPÇÃO 3 - PERSONALIZAÇÃO
        # ====================================================

        "3" {

            Executar-Modulo `
                -NomeModulo "Personalizacao" `
                -UrlModulo $UrlPersonalizacao

            Write-Host ""
            Write-Host "Pressione qualquer tecla para voltar ao menu..." -ForegroundColor Yellow

            [System.Console]::ReadKey($true) | Out-Null
        }

        # ====================================================
        # OPÇÃO 0 - SAIR
        # ====================================================

        "0" {

            Clear-Host

            Write-Host ""
            Write-Host "============================================================" -ForegroundColor Cyan
            Write-Host "              ENCERRANDO LR TECNOLOGIA" -ForegroundColor Cyan
            Write-Host "============================================================" -ForegroundColor Cyan
            Write-Host ""

            Start-Sleep -Seconds 1

            # Sai do while
            break
        }

        # ====================================================
        # OUTRAS TECLAS
        # ====================================================

        default {

            # Ignora qualquer outra tecla.
        }
    }

    # ========================================================
    # GARANTE QUE O LOOP NÃO CONTINUE APÓS O 0
    # ========================================================

    if ($Tecla.KeyChar -eq "0") {
        break
    }
}
