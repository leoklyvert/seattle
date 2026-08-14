# ============================================================
# LR TECNOLOGIA
# Assistente Técnico
# Versão 1.2.0
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
    Write-Host "3 - Personalizacao"
    Write-Host "4 - Diagnostico"
    Write-Host "0 - Sair"
    Write-Host ""
    Write-Host "Escolha uma opcao:" -ForegroundColor Yellow

    # Aguarda somente uma tecla.
    # Não é necessário pressionar ENTER.
    $Tecla = [System.Console]::ReadKey($true)

    switch ($Tecla.KeyChar) {

        # ====================================================
        # 1 - PROGRAMAS
        # ====================================================

        "1" {

            Clear-Host

            Write-Host ""
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host "       INSTALACAO DE PROGRAMAS" -ForegroundColor Cyan
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host ""

            $UrlProgramas = "https://github.com/leoklyvert/seattle/raw/refs/heads/main/programas.ps1"

            try {

                Write-Host "Carregando modulo de programas..." -ForegroundColor Yellow
                Write-Host ""

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


        # ====================================================
        # 2 - OFFICE
        # ====================================================

        "2" {

            Clear-Host

            Write-Host ""
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host "             INSTALAR OFFICE" -ForegroundColor Cyan
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host ""

            $UrlOffice = "https://github.com/leoklyvert/seattle/raw/refs/heads/main/office.ps1"

            try {

                Write-Host "Carregando modulo do Office..." -ForegroundColor Yellow
                Write-Host ""

                $ScriptOffice = Invoke-RestMethod `
                    -Uri $UrlOffice `
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


        # ====================================================
        # 3 - PERSONALIZACAO
        # ====================================================

        "3" {

            Clear-Host

            Write-Host ""
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host "              PERSONALIZACAO" -ForegroundColor Cyan
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host ""

            $UrlPersonalizacao = "https://github.com/leoklyvert/seattle/raw/refs/heads/main/personalizacao.ps1"

            try {

                Write-Host "Carregando modulo de personalizacao..." -ForegroundColor Yellow
                Write-Host ""

                $ScriptPersonalizacao = Invoke-RestMethod `
                    -Uri $UrlPersonalizacao `
                    -ErrorAction Stop

                Invoke-Expression $ScriptPersonalizacao

            }
            catch {

                Write-Host ""
                Write-Host "ERRO AO CARREGAR O MODULO DE PERSONALIZACAO." -ForegroundColor Red
                Write-Host ""
                Write-Host $_.Exception.Message -ForegroundColor Red
                Write-Host ""
            }

            Write-Host ""
            Write-Host "Pressione qualquer tecla para voltar ao menu..." -ForegroundColor Yellow
            [System.Console]::ReadKey($true) | Out-Null
        }


        # ====================================================
        # 4 - DIAGNOSTICO
        # ====================================================

        "4" {

            Clear-Host

            Write-Host ""
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host "                DIAGNOSTICO" -ForegroundColor Cyan
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host ""

            $UrlDiagnostico = "https://github.com/leoklyvert/seattle/raw/refs/heads/main/diagnostico.ps1"

            try {

                Write-Host "Carregando modulo de diagnostico..." -ForegroundColor Yellow
                Write-Host ""

                $ScriptDiagnostico = Invoke-RestMethod `
                    -Uri $UrlDiagnostico `
                    -ErrorAction Stop

                Invoke-Expression $ScriptDiagnostico

            }
            catch {

                Write-Host ""
                Write-Host "ERRO AO CARREGAR O MODULO DE DIAGNOSTICO." -ForegroundColor Red
                Write-Host ""
                Write-Host $_.Exception.Message -ForegroundColor Red
                Write-Host ""
            }

            Write-Host ""
            Write-Host "Pressione qualquer tecla para voltar ao menu..." -ForegroundColor Yellow
            [System.Console]::ReadKey($true) | Out-Null
        }


        # ====================================================
        # 0 - SAIR
        # ====================================================

        "0" {

            Clear-Host

            Write-Host ""
            Write-Host "Encerrando LR Tecnologia..." -ForegroundColor Cyan
            Write-Host ""

            return
        }


        # ====================================================
        # TECLA INVALIDA
        # ====================================================

        default {

            # Ignora qualquer outra tecla.
        }
    }
}
