# ============================================================
# LR TECNOLOGIA
# Assistente Técnico
# Versão 1.4.0
# ============================================================

Clear-Host

while ($true) {

    Clear-Host

    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "             LR TECNOLOGIA" -ForegroundColor Cyan
    Write-Host "          ASSISTENTE TECNICO" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1 - Instalacao de Programas"
    Write-Host "2 - Instalar Office"
    Write-Host "3 - Diagnostico"
    Write-Host "0 - Sair"
    Write-Host ""
    Write-Host "Escolha uma opcao:" -ForegroundColor Yellow

    # ========================================================
    # LE UMA TECLA SEM PRECISAR PRESSIONAR ENTER
    # ========================================================

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

            Write-Host "Carregando modulo do Office..." -ForegroundColor Yellow
            Write-Host ""

            # ------------------------------------------------
            # URL DO OFFICE
            # ------------------------------------------------

            $UrlOffice = "https://github.com/leoklyvert/seattle/raw/refs/heads/main/office.ps1"

            try {

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
        # 3 - DIAGNOSTICO
        # ====================================================

        "3" {

            Clear-Host

            Write-Host ""
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host "          DIAGNOSTICO PREVENTIVO" -ForegroundColor Cyan
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host ""

            Write-Host "Carregando modulo de diagnostico..." -ForegroundColor Yellow
            Write-Host ""

            # ------------------------------------------------
            # URL DO MODULO DE DIAGNOSTICO
            # ------------------------------------------------

            $UrlDiagnostico = "https://github.com/leoklyvert/seattle/raw/refs/heads/main/manutencao.ps1"

            try {

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
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host "        ENCERRANDO LR TECNOLOGIA" -ForegroundColor Cyan
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host ""

            Write-Host "Até logo!" -ForegroundColor Green
            Write-Host ""

            # Sai do WHILE principal.
            # O break dentro do switch não era suficiente
            # para encerrar o menu corretamente.
            return
        }

        # ====================================================
        # TECLA INVALIDA
        # ====================================================

        default {

            # Ignora qualquer tecla diferente de
            # 1, 2, 3 ou 0.
        }
    }
}
