# ============================================================
# ROBÔ LR TECNOLOGIA
# Criado e desenvolvido por Leonardo M. Batista.
# ============================================================
# Menu principal
#
# Os módulos são carregados diretamente do GitHub.
# Não depende de arquivos .ps1 locais.
#
# ============================================================

$ErrorActionPreference = "Stop"

# ============================================================
# CONFIGURAÇÃO GITHUB
# ============================================================

$GitHubBase = "https://github.com/leoklyvert/seattle/raw/refs/heads/main"

$UrlManutencao     = "$GitHubBase/manutencao.ps1"
$UrlPersonalizacao = "$GitHubBase/personalizacao.ps1"
$UrlProgramas      = "$GitHubBase/programas.ps1"
$UrlOffice         = "$GitHubBase/office.ps1"

# ============================================================
# FUNÇÃO - PAUSA
# ============================================================

function Pausar {

    Write-Host ""
    Write-Host "Pressione ENTER para continuar..." -ForegroundColor Gray
    Read-Host
}

# ============================================================
# FUNÇÃO - BAIXAR MÓDULO DO GITHUB
# ============================================================

function Obter-Modulo {

    param(
        [string]$Url,
        [string]$Nome
    )

    try {

        Write-Host ""
        Write-Host "Carregando $Nome..." -ForegroundColor Cyan

        $Codigo = Invoke-RestMethod `
            -Uri $Url `
            -Method Get `
            -ErrorAction Stop

        if ([string]::IsNullOrWhiteSpace($Codigo)) {

            throw "O GitHub retornou o módulo vazio."
        }

        return $Codigo
    }
    catch {

        Write-Host ""
        Write-Host "ERRO AO CARREGAR MÓDULO" -ForegroundColor Red
        Write-Host ""
        Write-Host "Módulo: $Nome" -ForegroundColor Yellow
        Write-Host "URL   : $Url" -ForegroundColor Gray
        Write-Host ""
        Write-Host $_.Exception.Message -ForegroundColor Yellow

        Pausar

        return $null
    }
}

# ============================================================
# FUNÇÃO - EXECUTAR MÓDULO
# ============================================================

function Executar-Modulo {

    param(
        [string]$Url,
        [string]$Nome
    )

    Clear-Host

    $Codigo = Obter-Modulo `
        -Url $Url `
        -Nome $Nome

    if ([string]::IsNullOrWhiteSpace($Codigo)) {
        return
    }

    Write-Host ""
    Write-Host "Iniciando $Nome..." -ForegroundColor Cyan
    Write-Host ""

    try {

        Invoke-Expression $Codigo

    }
    catch {

        Write-Host ""
        Write-Host "ERRO AO EXECUTAR O MÓDULO" -ForegroundColor Red
        Write-Host ""
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Write-Host ""

        Pausar
    }
}

# ============================================================
# CLIENTES COM CONTRATO
# ============================================================

$ClientesContrato = @(
    "A Casa do Panificador"
    "Escritório Real de Contabilidade"
    "Impacto Contabilidade"
    "Futura Contabilidade"
)

# ============================================================
# EXECUTAR DIAGNÓSTICO
# ============================================================

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

    $Codigo = Obter-Modulo `
        -Url $UrlManutencao `
        -Nome "Diagnóstico / Manutenção"

    if ([string]::IsNullOrWhiteSpace($Codigo)) {
        return
    }

    try {

        # ----------------------------------------------------
        # Disponibiliza os dados do cliente para o módulo
        # ----------------------------------------------------

        $env:LR_CLIENTE = $Cliente
        $env:LR_TIPO_CLIENTE = $TipoCliente

        Invoke-Expression $Codigo

    }
    catch {

        Write-Host ""
        Write-Host "ERRO AO EXECUTAR DIAGNÓSTICO" -ForegroundColor Red
        Write-Host ""
        Write-Host $_.Exception.Message -ForegroundColor Yellow
        Write-Host ""

        Pausar
    }
}

# ============================================================
# CLIENTE EXISTENTE
# ============================================================

function Menu-ClienteExistente {

    while ($true) {

        Clear-Host

        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "                    CLIENTE EXISTENTE" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""

        Write-Host "1 - Contrato Mensal" -ForegroundColor White
        Write-Host "2 - Sem Contrato / Particular" -ForegroundColor White
        Write-Host ""
        Write-Host "0 - Voltar" -ForegroundColor Gray
        Write-Host ""

        $Opcao = Read-Host "Selecione uma opção"

        switch ($Opcao) {

            "1" {
                Menu-ContratoMensal
            }

            "2" {
                Diagnostico-Particular
            }

            "0" {
                return
            }

            default {

                Write-Host ""
                Write-Host "Opção inválida." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}

# ============================================================
# CONTRATO MENSAL
# ============================================================

function Menu-ContratoMensal {

    while ($true) {

        Clear-Host

        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "                    CONTRATO MENSAL" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""

        $Numero = 1

        foreach ($Cliente in $ClientesContrato) {

            Write-Host "$Numero - $Cliente" -ForegroundColor White

            $Numero++
        }

        Write-Host ""
        Write-Host "0 - Voltar" -ForegroundColor Gray
        Write-Host ""

        $Opcao = Read-Host "Selecione o cliente"

        if ($Opcao -eq "0") {
            return
        }

        $Indice = 0

        if ([int]::TryParse($Opcao, [ref]$Indice)) {

            if (
                $Indice -ge 1 -and
                $Indice -le $ClientesContrato.Count
            ) {

                $ClienteSelecionado =
                    $ClientesContrato[$Indice - 1]

                Executar-Diagnostico `
                    -Cliente $ClienteSelecionado `
                    -TipoCliente "Contrato Mensal"

                return
            }
        }

        Write-Host ""
        Write-Host "Cliente inválido." -ForegroundColor Red
        Start-Sleep -Seconds 1
    }
}

# ============================================================
# PARTICULAR
# ============================================================

function Diagnostico-Particular {

    Clear-Host

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "                 CLIENTE PARTICULAR" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""

    $NomeCliente = Read-Host "Digite o nome do cliente"

    if ([string]::IsNullOrWhiteSpace($NomeCliente)) {

        Write-Host ""
        Write-Host "Nome do cliente não informado." -ForegroundColor Red

        Pausar
        return
    }

    Executar-Diagnostico `
        -Cliente $NomeCliente `
        -TipoCliente "Sem Contrato / Particular"
}

# ============================================================
# CLIENTE NOVO
# ============================================================

function Diagnostico-ClienteNovo {

    Clear-Host

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "                      CLIENTE NOVO" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""

    $NomeCliente = Read-Host "Digite o nome do cliente"

    if ([string]::IsNullOrWhiteSpace($NomeCliente)) {

        Write-Host ""
        Write-Host "Nome do cliente não informado." -ForegroundColor Red

        Pausar
        return
    }

    Executar-Diagnostico `
        -Cliente $NomeCliente `
        -TipoCliente "Cliente Novo"
}

# ============================================================
# MENU DIAGNÓSTICO
# ============================================================

function Menu-Diagnostico {

    while ($true) {

        Clear-Host

        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "                 DIAGNÓSTICO LR TECNOLOGIA" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""

        Write-Host "1 - Cliente Existente" -ForegroundColor White
        Write-Host "2 - Cliente Novo" -ForegroundColor White
        Write-Host ""
        Write-Host "0 - Voltar" -ForegroundColor Gray
        Write-Host ""

        $Opcao = Read-Host "Selecione uma opção"

        switch ($Opcao) {

            "1" {
                Menu-ClienteExistente
            }

            "2" {
                Diagnostico-ClienteNovo
            }

            "0" {
                return
            }

            default {

                Write-Host ""
                Write-Host "Opção inválida." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}

# ============================================================
# MENU PRINCIPAL
# ============================================================

while ($true) {

    Clear-Host

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "                 ROBÔ LR TECNOLOGIA" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "                    MENU PRINCIPAL" -ForegroundColor Gray
    Write-Host ""

    Write-Host "1 - Manutenção" -ForegroundColor White
    Write-Host "2 - Personalização" -ForegroundColor White
    Write-Host "3 - Programas" -ForegroundColor White
    Write-Host "4 - Office" -ForegroundColor White
    Write-Host "5 - Diagnóstico" -ForegroundColor Green
    Write-Host ""
    Write-Host "0 - Sair" -ForegroundColor Gray
    Write-Host ""

    $Opcao = Read-Host "Selecione uma opção"

    switch ($Opcao) {

        "1" {

            Executar-Modulo `
                -Url $UrlManutencao `
                -Nome "Manutenção"
        }

        "2" {

            Executar-Modulo `
                -Url $UrlPersonalizacao `
                -Nome "Personalização"
        }

        "3" {

            Executar-Modulo `
                -Url $UrlProgramas `
                -Nome "Programas"
        }

        "4" {

            Executar-Modulo `
                -Url $UrlOffice `
                -Nome "Office"
        }

        "5" {

            Menu-Diagnostico
        }

        "0" {

            Clear-Host

            Write-Host ""
            Write-Host "Robô LR Tecnologia encerrado." -ForegroundColor Cyan
            Write-Host ""

            exit
        }

        default {

            Write-Host ""
            Write-Host "Opção inválida." -ForegroundColor Red

            Start-Sleep -Seconds 1
        }
    }
}
