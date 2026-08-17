# ============================================================
# ROBÔ LR TECNOLOGIA
# Criado e desenvolvido por Leonardo M. Batista.
# ============================================================
# Menu principal
#
# Versão: 1.4.0
#
# Módulos:
# 1 - Manutenção
# 2 - Personalização
# 3 - Programas
# 4 - Office
# 5 - Diagnóstico
#
# Compatível com execução:
#
# irm "https://github.com/leoklyvert/seattle/raw/refs/heads/main/lr.ps1" | iex
#
# ============================================================

$ErrorActionPreference = "Stop"

# ============================================================
# CONFIGURAÇÃO GITHUB
# ============================================================

$GitHubBase = "https://raw.githubusercontent.com/leoklyvert/seattle/main"

# ============================================================
# PASTA TEMPORÁRIA DO ROBÔ
# ============================================================

$PastaBase = Join-Path $env:TEMP "LR-Tecnologia"

if (!(Test-Path $PastaBase)) {

    New-Item `
        -Path $PastaBase `
        -ItemType Directory `
        -Force |
        Out-Null
}

# ============================================================
# ARQUIVOS DOS MÓDULOS
# ============================================================

$ModuloManutencao     = Join-Path $PastaBase "manutencao.ps1"
$ModuloPersonalizacao = Join-Path $PastaBase "personalizacao.ps1"
$ModuloProgramas      = Join-Path $PastaBase "programas.ps1"
$ModuloOffice         = Join-Path $PastaBase "office.ps1"

# ============================================================
# FUNÇÃO - PAUSA
# ============================================================

function Pausar {

    Write-Host ""
    Write-Host "Pressione ENTER para continuar..." -ForegroundColor Gray

    Read-Host
}

# ============================================================
# FUNÇÃO - BAIXAR MÓDULO
# ============================================================

function Baixar-Modulo {

    param(
        [string]$NomeArquivo
    )

    $Url = "$GitHubBase/$NomeArquivo"

    $Destino = Join-Path $PastaBase $NomeArquivo

    try {

        Write-Host "Atualizando módulo: $NomeArquivo" -ForegroundColor Gray

        Invoke-WebRequest `
            -Uri $Url `
            -OutFile $Destino `
            -UseBasicParsing `
            -ErrorAction Stop

        if (!(Test-Path $Destino)) {

            throw "Arquivo não foi criado."
        }

        return $Destino
    }
    catch {

        Write-Host ""
        Write-Host "ERRO AO BAIXAR MÓDULO" -ForegroundColor Red
        Write-Host ""
        Write-Host "Arquivo : $NomeArquivo" -ForegroundColor Yellow
        Write-Host "URL     : $Url" -ForegroundColor Gray
        Write-Host ""
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host ""

        return $null
    }
}

# ============================================================
# ATUALIZA MÓDULOS
# ============================================================

$ModuloManutencao = Baixar-Modulo "manutencao.ps1"

$ModuloPersonalizacao = Baixar-Modulo "personalizacao.ps1"

$ModuloProgramas = Baixar-Modulo "programas.ps1"

$ModuloOffice = Baixar-Modulo "office.ps1"

# ============================================================
# FUNÇÃO - EXECUTAR MÓDULO
# ============================================================

function Executar-Modulo {

    param(
        [string]$Arquivo,
        [string]$Nome
    )

    Clear-Host

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "                 ROBÔ LR TECNOLOGIA" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""

    Write-Host "Módulo: " -NoNewline
    Write-Host $Nome -ForegroundColor Yellow

    Write-Host ""

    if (!$Arquivo -or !(Test-Path $Arquivo)) {

        Write-Host "ERRO: módulo não encontrado." -ForegroundColor Red
        Write-Host ""

        Write-Host "Arquivo:" -ForegroundColor Gray
        Write-Host $Arquivo -ForegroundColor Yellow

        Pausar
        return
    }

    try {

        & $Arquivo

    }
    catch {

        Write-Host ""
        Write-Host "ERRO AO EXECUTAR MÓDULO" -ForegroundColor Red
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

    if (!$ModuloManutencao -or !(Test-Path $ModuloManutencao)) {

        Write-Host "ERRO: manutencao.ps1 não encontrado." -ForegroundColor Red
        Write-Host ""

        Write-Host "Caminho:" -ForegroundColor Gray
        Write-Host $ModuloManutencao -ForegroundColor Yellow

        Pausar
        return
    }

    Write-Host "Iniciando módulo de diagnóstico..." -ForegroundColor Cyan
    Write-Host ""

    try {

        & $ModuloManutencao `
            -Cliente $Cliente `
            -TipoCliente $TipoCliente

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
# MENU - CLIENTE EXISTENTE
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
# MENU - CONTRATO MENSAL
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
# DIAGNÓSTICO - PARTICULAR
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
# DIAGNÓSTICO - CLIENTE NOVO
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
                -Arquivo $ModuloManutencao `
                -Nome "Manutenção"
        }

        "2" {

            Executar-Modulo `
                -Arquivo $ModuloPersonalizacao `
                -Nome "Personalização"
        }

        "3" {

            Executar-Modulo `
                -Arquivo $ModuloProgramas `
                -Nome "Programas"
        }

        "4" {

            Executar-Modulo `
                -Arquivo $ModuloOffice `
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
