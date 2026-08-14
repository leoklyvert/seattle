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
    Write-Host "2 - Office"
    Write-Host "0 - Sair"
    Write-Host ""

    $opcao = Read-Host "Escolha uma opcao"

    switch ($opcao) {

        "1" {
            Write-Host ""
            Write-Host "Iniciando instalacao de programas..." -ForegroundColor Yellow
            Write-Host ""

            $urlProgramas = "https://github.com/leoklyvert/seattle/raw/refs/heads/main/programas.ps1"

            try {
                $script = Invoke-RestMethod -Uri $urlProgramas -ErrorAction Stop
                Invoke-Expression $script
            }
            catch {
                Write-Host ""
                Write-Host "ERRO ao carregar o modulo de programas." -ForegroundColor Red
                Write-Host $_.Exception.Message -ForegroundColor Red
            }

            Write-Host ""
            Read-Host "Pressione ENTER para voltar ao menu"
        }

        "2" {
            Write-Host ""
            Write-Host "Modulo Office ainda nao configurado." -ForegroundColor Yellow
            Write-Host ""
            Read-Host "Pressione ENTER para voltar ao menu"
        }

        "0" {
            Write-Host ""
            Write-Host "Encerrando LR Tecnologia..." -ForegroundColor Cyan
            Write-Host ""
            break
        }

        default {
            Write-Host ""
            Write-Host "Opcao invalida." -ForegroundColor Red
            Start-Sleep -Seconds 2
        }
    }
}
