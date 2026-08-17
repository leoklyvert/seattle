```powershell
# ============================================================
# ROBÔ LR TECNOLOGIA
# Criado e desenvolvido por Leonardo M. Batista.
# ============================================================
# MENU PRINCIPAL
#
# 1 - Manutenção
# 2 - Personalização
# 3 - Programas
# 4 - Office
# 5 - Diagnóstico
# ============================================================

$ErrorActionPreference = "Stop"

# ============================================================
# GITHUB
# ============================================================

$GitHubBase = "https://github.com/leoklyvert/seattle/raw/refs/heads/main"

$UrlManutencao     = "$GitHubBase/manutencao.ps1"
$UrlPersonalizacao = "$GitHubBase/personalizacao.ps1"
$UrlProgramas      = "$GitHubBase/programas.ps1"
$UrlOffice         = "$GitHubBase/office.ps1"

# ============================================================
# PASTA TEMPORÁRIA
# ============================================================

$PastaTemp = Join-Path $env:TEMP "LR-Tecnologia"

if (!(Test-Path $PastaTemp)) {

    New-Item `
        -Path $PastaTemp `
        -ItemType Directory `
        -Force |
        Out-Null
}

# ============================================================
# PAUSA
# ============================================================

function Pausar {

    Write-Host ""
    Write-Host "Pressione ENTER para continuar..." -ForegroundColor Gray

    Read-Host | Out-Null
}

# ============================================================
# BAIXAR MÓDULO
# ============================================================

function Baixar-Modulo {

    param(
        [string]$Url,
        [string]$NomeArquivo
    )

    $Destino = Join-Path $PastaTemp $NomeArquivo

    try {

        Invoke-WebRequest `
            -Uri $Url `
            -OutFile $Destino `
            -UseBasicParsing `
            -ErrorAction Stop

        if (!(Test-Path $Destino)) {

            throw "Arquivo não encontrado após o download."
        }

        return $Destino
    }
    catch {

        Write-Host ""
        Write-Host "ERRO AO BAIXAR MÓDULO" -ForegroundColor Red
        Write-Host ""
        Write-Host "Arquivo: $NomeArquivo" -ForegroundColor Yellow
        Write-Host "URL: $Url" -ForegroundColor Gray
        Write-Host ""
        Write-Host $_.Exception.Message -ForegroundColor Yellow

        return $null
    }
}

# ============================================================
# EXECUTAR MÓDULO
# ============================================================

function Executar-Modulo {

    param(
        [string]$Url,
        [string]$NomeArquivo,
        [string]$Nome
    )

    Clear-Host

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "                 ROBÔ LR TECNOLOGIA" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Iniciando $Nome..." -ForegroundColor Cyan
    Write-Host ""

    $Arquivo = Baixar-Modulo `
        -Url $Url `
        -NomeArquivo $NomeArquivo

    if (!$Arquivo) {

        Pausar
        return
    }

    try {

        & $Arquivo

    }
    catch {

        Write-Host ""
        Write-Host "ERRO AO EXECUTAR $Nome" -ForegroundColor Red
        Write-Host ""
        Write-Host $_.Exception.Message -ForegroundColor Yellow

        Pausar
    }
}

# ============================================================
# CLIENTES DE CONTRATO
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
    Write-Host "Baixando módulo de diagnóstico..." -ForegroundColor Cyan
    Write-Host ""

    $Arquivo = Baixar-Modulo `
        -Url $UrlManutencao `
        -NomeArquivo "manutencao_diagnostico.ps1"

    if (!$Arquivo) {

        Pausar
        return
    }

    Write-Host "Módulo carregado com sucesso." -ForegroundColor Green
    Write-Host ""

    try {

        & $Arquivo `
            -Cliente $Cliente `
            -TipoCliente $TipoCliente

    }
    catch {

        Write-Host ""
        Write-Host "ERRO AO EXECUTAR DIAGNÓSTICO" -ForegroundColor Red
        Write-Host ""
        Write-Host $_.Exception.Message -ForegroundColor Yellow

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
                -NomeArquivo "manutencao.ps1" `
                -Nome "Manutenção"
        }

        "2" {

            Executar-Modulo `
                -Url $UrlPersonalizacao `
                -NomeArquivo "personalizacao.ps1" `
                -Nome "Personalização"
        }

        "3" {

            Executar-Modulo `
                -Url $UrlProgramas `
                -NomeArquivo "programas.ps1" `
                -Nome "Programas"
        }

        "4" {

            Executar-Modulo `
                -Url $UrlOffice `
                -NomeArquivo "office.ps1" `
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
