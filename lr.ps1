# ============================================================
# SEATTLE - LR TECNOLOGIA
# Módulo principal
# Criado e desenvolvido por Leonardo M. Batista
# ============================================================

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# CONFIGURAÇÃO
# ------------------------------------------------------------

$GitHubBase = "https://raw.githubusercontent.com/leoklyvert/seattle/main"

$UrlManutencao     = "$GitHubBase/manuten%C3%A7%C3%A3o.ps1"
$UrlDiagnostico    = "$GitHubBase/diagn%C3%B3stico.ps1"
$UrlPersonalizacao = "$GitHubBase/personalizacao.ps1"
$UrlProgramas      = "$GitHubBase/programas.ps1"
$UrlOffice         = "$GitHubBase/office.ps1"


# ------------------------------------------------------------
# FUNÇÕES GERAIS
# ------------------------------------------------------------

function Pausar {
    Write-Host ""
    Write-Host "Pressione qualquer tecla para continuar..." -ForegroundColor DarkGray
    [void][System.Console]::ReadKey($true)
}


function Limpar-Tela {
    Clear-Host
}


function Mostrar-Cabecalho {

    Limpar-Tela

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "              Módulo Seattle by LR Tecnologia" -ForegroundColor Cyan
    Write-Host "        Criado e desenvolvido por Leonardo M. Batista" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
}


# ------------------------------------------------------------
# DOWNLOAD DO MÓDULO
# ------------------------------------------------------------

function Obter-Modulo {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $true)]
        [string]$Nome
    )

    try {

        Write-Host ""
        Write-Host "Carregando $Nome..." -ForegroundColor Yellow

        $Codigo = Invoke-RestMethod `
            -Uri $Url `
            -Method Get `
            -UseBasicParsing `
            -TimeoutSec 60

        if ([string]::IsNullOrWhiteSpace($Codigo)) {
            throw "O arquivo retornado está vazio."
        }

        return $Codigo
    }
    catch {

        Write-Host ""
        Write-Host "ERRO AO CARREGAR MÓDULO" -ForegroundColor Red
        Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "Módulo: $Nome" -ForegroundColor White
        Write-Host "URL   : $Url" -ForegroundColor White
        Write-Host ""
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host ""

        return $null
    }
}


function Executar-Modulo {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $true)]
        [string]$Nome
    )

    $Codigo = Obter-Modulo -Url $Url -Nome $Nome

    if ($null -eq $Codigo) {
        Pausar
        return
    }

    try {

        Write-Host ""

        Invoke-Expression $Codigo
    }
    catch {

        Write-Host ""
        Write-Host "ERRO DURANTE A EXECUÇÃO DO MÓDULO" -ForegroundColor Red
        Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host ""

        Pausar
    }
}


# ------------------------------------------------------------
# DIAGNÓSTICO
# ------------------------------------------------------------

function Executar-Diagnostico {

    param(
        [string]$Cliente,
        [string]$TipoCliente
    )

    $Codigo = Obter-Modulo `
        -Url $UrlDiagnostico `
        -Nome "Diagnóstico Preventivo"

    if ($null -eq $Codigo) {
        Pausar
        return
    }

    try {

        # Disponibiliza as informações para o módulo diagnóstico.ps1
        $env:LR_CLIENTE = $Cliente
        $env:LR_TIPO_CLIENTE = $TipoCliente

        Invoke-Expression $Codigo
    }
    catch {

        Write-Host ""
        Write-Host "ERRO DURANTE O DIAGNÓSTICO" -ForegroundColor Red
        Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host ""

        Pausar
    }
    finally {

        Remove-Item Env:\LR_CLIENTE -ErrorAction SilentlyContinue
        Remove-Item Env:\LR_TIPO_CLIENTE -ErrorAction SilentlyContinue
    }
}


# ------------------------------------------------------------
# MENU DIAGNÓSTICO
# ------------------------------------------------------------

function Menu-Diagnostico {

    do {

        Mostrar-Cabecalho

        Write-Host "DIAGNÓSTICO" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "1 - Cliente Existente"
        Write-Host "2 - Cliente Novo"
        Write-Host "0 - Voltar"
        Write-Host ""

        $Opcao = [System.Console]::ReadKey($true).KeyChar

        switch ($Opcao) {

            "1" {
                Menu-ClienteExistente
            }

            "2" {
                Executar-Diagnostico `
                    -Cliente "Cliente Novo" `
                    -TipoCliente "Novo"
            }

            "0" {
                return
            }
        }

    } while ($true)
}


# ------------------------------------------------------------
# CLIENTE EXISTENTE
# ------------------------------------------------------------

function Menu-ClienteExistente {

    do {

        Mostrar-Cabecalho

        Write-Host "CLIENTE EXISTENTE" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "1 - Contrato Mensal"
        Write-Host "2 - Sem Contrato / Particular"
        Write-Host "0 - Voltar"
        Write-Host ""

        $Opcao = [System.Console]::ReadKey($true).KeyChar

        switch ($Opcao) {

            "1" {
                Menu-ContratoMensal
            }

            "2" {

                Mostrar-Cabecalho

                Write-Host "CLIENTE PARTICULAR" -ForegroundColor Yellow
                Write-Host ""

                $Cliente = Read-Host "Nome do cliente"

                if ([string]::IsNullOrWhiteSpace($Cliente)) {
                    $Cliente = "Cliente Particular"
                }

                Executar-Diagnostico `
                    -Cliente $Cliente `
                    -TipoCliente "Sem Contrato / Particular"
            }

            "0" {
                return
            }
        }

    } while ($true)
}


# ------------------------------------------------------------
# CONTRATO MENSAL
# ------------------------------------------------------------

function Menu-ContratoMensal {

    do {

        Mostrar-Cabecalho

        Write-Host "CLIENTES COM CONTRATO MENSAL" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "1 - A Casa do Panificador"
        Write-Host "2 - Escritório Real de Contabilidade"
        Write-Host "3 - Impacto Contabilidade"
        Write-Host "4 - Futura Contabilidade"
        Write-Host "0 - Voltar"
        Write-Host ""

        $Opcao = [System.Console]::ReadKey($true).KeyChar

        switch ($Opcao) {

            "1" {
                Executar-Diagnostico `
                    -Cliente "A Casa do Panificador" `
                    -TipoCliente "Contrato Mensal"
            }

            "2" {
                Executar-Diagnostico `
                    -Cliente "Escritório Real de Contabilidade" `
                    -TipoCliente "Contrato Mensal"
            }

            "3" {
                Executar-Diagnostico `
                    -Cliente "Impacto Contabilidade" `
                    -TipoCliente "Contrato Mensal"
            }

            "4" {
                Executar-Diagnostico `
                    -Cliente "Futura Contabilidade" `
                    -TipoCliente "Contrato Mensal"
            }

            "0" {
                return
            }
        }

    } while ($true)
}


# ------------------------------------------------------------
# MENU PRINCIPAL
# ------------------------------------------------------------

function Menu-Principal {

    do {

        Mostrar-Cabecalho

        Write-Host "MENU PRINCIPAL" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "1 - Manutenção"
        Write-Host "2 - Personalização"
        Write-Host "3 - Programas"
        Write-Host "4 - Office"
        Write-Host "5 - Diagnóstico"
        Write-Host "0 - Sair"
        Write-Host ""

        $Opcao = [System.Console]::ReadKey($true).KeyChar

        switch ($Opcao) {

            # ------------------------------------------------
            # MANUTENÇÃO
            # ------------------------------------------------

            "1" {

                Executar-Modulo `
                    -Url $UrlManutencao `
                    -Nome "Manutenção"
            }


            # ------------------------------------------------
            # PERSONALIZAÇÃO
            # ------------------------------------------------

            "2" {

                Executar-Modulo `
                    -Url $UrlPersonalizacao `
                    -Nome "Personalização"
            }


            # ------------------------------------------------
            # PROGRAMAS
            # ------------------------------------------------

            "3" {

                Executar-Modulo `
                    -Url $UrlProgramas `
                    -Nome "Programas"
            }


            # ------------------------------------------------
            # OFFICE
            # ------------------------------------------------

            "4" {

                Executar-Modulo `
                    -Url $UrlOffice `
                    -Nome "Office"
            }


            # ------------------------------------------------
            # DIAGNÓSTICO
            # ------------------------------------------------

            "5" {

                Menu-Diagnostico
            }


            # ------------------------------------------------
            # SAIR
            # ------------------------------------------------

            "0" {

                Limpar-Tela

                Write-Host ""
                Write-Host "Seattle encerrado." -ForegroundColor Cyan
                Write-Host ""

                return
            }
        }

    } while ($true)
}


# ============================================================
# INÍCIO
# ============================================================

Menu-Principal
