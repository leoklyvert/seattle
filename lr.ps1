# ============================================================
# LR TECNOLOGIA
# Assistente Técnico
# ============================================================

Clear-Host

while ($true) {

    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "             LR TECNOLOGIA" -ForegroundColor Cyan
    Write-Host "          ASSISTENTE TECNICO" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1 - Instalacao de Programas"
    Write-Host "2 - Instalar Office"
    Write-Host "0 - Sair"
    Write-Host ""
    Write-Host "Escolha uma opcao:" -ForegroundColor Yellow

    # Aguarda apenas uma tecla.
    # Nao precisa pressionar ENTER.
    $Tecla = [System.Console]::ReadKey($true)

    switch ($Tecla.KeyChar) {

        "1" {

            Clear-Host

            Write-Host ""
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host "       INSTALACAO DE PROGRAMAS" -ForegroundColor Cyan
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host ""

            $UrlProgramas = "https://github.com/leoklyvert/seattle/raw/refs/heads/main/programas.ps1"

            try {

                $ScriptProgramas = Invoke-RestMethod `
                    -Uri $UrlProgramas `
                    -ErrorAction Stop

                Invoke-Expression $ScriptProgramas

            }
            catch {

                Write-Host ""
                Write-Host "ERRO AO CARREGAR O MODULO DE PROGRAMAS." -ForegroundColor Red
                Write-Host ""
                Write-Host $_.Exception.Message -ForegroundColor Red
                Write-Host ""
            }

            Write-Host ""
            Write-Host "Pressione qualquer tecla para voltar ao menu..." -ForegroundColor Yellow
            [System.Console]::ReadKey($true) | Out-Null
        }

        "2" {

    Clear-Host

    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "             INSTALAR OFFICE" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""

    $UrlOfficeScript = "https://github.com/leoklyvert/seattle/raw/refs/heads/main/office.ps1"

    try {

        Write-Host "Carregando modulo do Office..." -ForegroundColor Yellow
        Write-Host ""

        $ScriptOffice = Invoke-RestMethod `
            -Uri $UrlOfficeScript `
            -ErrorAction Stop

        Invoke-Expression $ScriptOffice

    }
    catch {

        Write-Host ""
        Write-Host "ERRO AO CARREGAR O MODULO DO OFFICE." -ForegroundColor Red
        Write-Host ""
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host ""
    }

    Write-Host ""
    Write-Host "Pressione qualquer tecla para voltar ao menu..." -ForegroundColor Yellow
    [System.Console]::ReadKey($true) | Out-Null
}

        "0" {

            Clear-Host

            Write-Host ""
            Write-Host "Encerrando LR Tecnologia..." -ForegroundColor Cyan
            Write-Host ""

            break
        }

        default {

            # Tecla diferente de 1, 2 ou 0:
            # simplesmente ignora.
        }
    }
}
