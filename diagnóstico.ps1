# ============================================================
# SEATTLE - LR TECNOLOGIA
# ============================================================
# Módulo: Diagnóstico Preventivo
# Versão: 2.0.0
#
# SOMENTE LEITURA
#
# Fluxo:
#   Cliente Existente
#       ├── Contrato Mensal
#       └── Sem Contrato / Particular
#
#   Cliente Novo
#
# O inventário é enviado para a HostGator.
# Não mantém inventário permanente no computador cliente.
# ============================================================

$ErrorActionPreference = "SilentlyContinue"

# ============================================================
# CONFIGURAÇÃO
# ============================================================

$UrlServidor = "https://lrtecnologia.net.br/seattle/receber_inventario.php"

# IMPORTANTE:
# Esta chave deve ser a mesma configurada no PHP.
$ChaveSeattle = ")#twPMPaKsj>d23}y3covTxvmr1Ht*EA3iHc=WQQEFVB424H>}"

# ============================================================
# FUNÇÕES
# ============================================================

function Obter-TipoMemoria {
    param($Codigo)

    switch ($Codigo) {
        20 { return "DDR" }
        21 { return "DDR2" }
        24 { return "DDR3" }
        26 { return "DDR4" }
        30 { return "DDR5" }
        default { return "Desconhecido" }
    }
}

function Pausar-Diagnostico {

    Write-Host ""
    Write-Host "Pressione qualquer tecla para continuar..." -ForegroundColor Gray
    [System.Console]::ReadKey($true) | Out-Null
}

# ============================================================
# MENU CLIENTE
# ============================================================

function Selecionar-Cliente {

    while ($true) {

        Clear-Host

        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "              DIAGNÓSTICO PREVENTIVO" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""

        Write-Host "1 - Cliente Existente" -ForegroundColor White
        Write-Host "2 - Cliente Novo" -ForegroundColor White
        Write-Host "0 - Voltar" -ForegroundColor White
        Write-Host ""

        Write-Host "Escolha uma opção: " -ForegroundColor Yellow -NoNewline

        $Tecla = [System.Console]::ReadKey($true)

        switch ($Tecla.KeyChar) {

            "1" {

                return Selecionar-ClienteExistente
            }

            "2" {

                return Selecionar-ClienteNovo
            }

            "0" {

                return $null
            }
        }
    }
}

# ============================================================
# CLIENTE EXISTENTE
# ============================================================

function Selecionar-ClienteExistente {

    while ($true) {

        Clear-Host

        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "                  CLIENTE EXISTENTE" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""

        Write-Host "1 - Contrato Mensal"
        Write-Host "2 - Sem Contrato / Particular"
        Write-Host "0 - Voltar"
        Write-Host ""

        Write-Host "Escolha uma opção: " -ForegroundColor Yellow -NoNewline

        $Tecla = [System.Console]::ReadKey($true)

        switch ($Tecla.KeyChar) {

            "1" {

                return Selecionar-ContratoMensal
            }

            "2" {

                return Selecionar-Particular
            }

            "0" {

                return $null
            }
        }
    }
}

# ============================================================
# CLIENTES DE CONTRATO
# ============================================================

function Selecionar-ContratoMensal {

    $Clientes = @(
        "A Casa do Panificador",
        "Escritório Real de Contabilidade",
        "Impacto Contabilidade",
        "Futura Contabilidade"
    )

    while ($true) {

        Clear-Host

        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "                 CONTRATO MENSAL" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""

        for ($i = 0; $i -lt $Clientes.Count; $i++) {

            Write-Host "$($i + 1) - $($Clientes[$i])"
        }

        Write-Host ""
        Write-Host "0 - Voltar"
        Write-Host ""

        Write-Host "Escolha o cliente: " -ForegroundColor Yellow -NoNewline

        $Tecla = [System.Console]::ReadKey($true)

        switch ($Tecla.KeyChar) {

            "1" {

                return [PSCustomObject]@{
                    cliente     = $Clientes[0]
                    tipo_cliente = "Existente"
                    contrato    = "Mensal"
                }
            }

            "2" {

                return [PSCustomObject]@{
                    cliente     = $Clientes[1]
                    tipo_cliente = "Existente"
                    contrato    = "Mensal"
                }
            }

            "3" {

                return [PSCustomObject]@{
                    cliente     = $Clientes[2]
                    tipo_cliente = "Existente"
                    contrato    = "Mensal"
                }
            }

            "4" {

                return [PSCustomObject]@{
                    cliente     = $Clientes[3]
                    tipo_cliente = "Existente"
                    contrato    = "Mensal"
                }
            }

            "0" {

                return $null
            }
        }
    }
}

# ============================================================
# PARTICULAR
# ============================================================

function Selecionar-Particular {

    while ($true) {

        Clear-Host

        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "             SEM CONTRATO / PARTICULAR" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""

        Write-Host "Digite o nome do cliente:"
        Write-Host ""

        $Nome = Read-Host "Cliente"

        if (-not [string]::IsNullOrWhiteSpace($Nome)) {

            return [PSCustomObject]@{
                cliente      = $Nome.Trim()
                tipo_cliente = "Existente"
                contrato     = "Sem Contrato"
            }
        }

        Write-Host ""
        Write-Host "Nome inválido." -ForegroundColor Red
        Pausar-Diagnostico
    }
}

# ============================================================
# CLIENTE NOVO
# ============================================================

function Selecionar-ClienteNovo {

    Clear-Host

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "                    CLIENTE NOVO" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""

    $Nome = Read-Host "Nome do cliente"

    if ([string]::IsNullOrWhiteSpace($Nome)) {

        Write-Host ""
        Write-Host "Nome inválido." -ForegroundColor Red

        Pausar-Diagnostico

        return $null
    }

    return [PSCustomObject]@{
        cliente      = $Nome.Trim()
        tipo_cliente = "Novo"
        contrato     = "Novo Cliente"
    }
}

# ============================================================
# SELECIONA CLIENTE
# ============================================================

$DadosCliente = Selecionar-Cliente

if ($null -eq $DadosCliente) {

    return
}

# ============================================================
# CABEÇALHO
# ============================================================

Clear-Host

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "              ROBÔ LR TECNOLOGIA" -ForegroundColor Cyan
Write-Host "          DIAGNÓSTICO PREVENTIVO v2.0.0" -ForegroundColor Cyan
Write-Host ""
Write-Host "                  SOMENTE LEITURA" -ForegroundColor Yellow
Write-Host "       Não altera configurações do computador" -ForegroundColor Gray
Write-Host "       Não remove programas" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Cliente   : " -NoNewline
Write-Host $DadosCliente.cliente -ForegroundColor Yellow

Write-Host "Categoria : " -NoNewline
Write-Host $DadosCliente.tipo_cliente -ForegroundColor Yellow

Write-Host "Contrato  : " -NoNewline
Write-Host $DadosCliente.contrato -ForegroundColor Yellow

Write-Host ""

# ============================================================
# IDENTIFICAÇÃO
# ============================================================

Write-Host "[1/6] Coletando identificação..." -ForegroundColor Cyan

$Sistema = Get-CimInstance Win32_ComputerSystem
$BIOS = Get-CimInstance Win32_BIOS
$SO = Get-CimInstance Win32_OperatingSystem

$Computador = $env:COMPUTERNAME
$Usuario = $env:USERNAME
$Fabricante = $Sistema.Manufacturer
$Modelo = $Sistema.Model
$Serial = $BIOS.SerialNumber

# ============================================================
# WINDOWS
# ============================================================

Write-Host "[2/6] Coletando informações do Windows..." -ForegroundColor Cyan

$Windows = Get-ItemProperty `
    "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"

$VersaoWindows = "$($Windows.ProductName) $($Windows.DisplayVersion)"

$BuildWindows = $Windows.CurrentBuild
$UBRWindows = $Windows.UBR

# ============================================================
# TEMPO LIGADO
# ============================================================

$Boot = $null
$TempoLigado = $null

try {

    $ValorBoot = $SO.LastBootUpTime

    if ($null -eq $ValorBoot) {

        throw "LastBootUpTime veio nulo"
    }

    if ($ValorBoot -is [string]) {

        $Boot =
            [Management.ManagementDateTimeConverter]::ToDateTime(
                $ValorBoot
            )
    }
    else {

        $Boot = $ValorBoot
    }

    $TempoLigado =
        New-TimeSpan `
            -Start $Boot `
            -End (Get-Date)

}
catch {}

# ============================================================
# CPU
# ============================================================

Write-Host "[3/6] Coletando processador..." -ForegroundColor Cyan

$CPUInfo =
    Get-CimInstance Win32_Processor |
    Select-Object -First 1

$CPU = $CPUInfo.Name
$Nucleos = $CPUInfo.NumberOfCores
$Threads = $CPUInfo.NumberOfLogicalProcessors

$UsoCPU = 0

try {

    $ContadorCPU =
        Get-Counter "\Processor(_Total)\% Processor Time"

    $UsoCPU =
        [math]::Round(
            $ContadorCPU.CounterSamples.CookedValue,
            1
        )
}
catch {}

# ============================================================
# RAM
# ============================================================

Write-Host "[4/6] Coletando memória RAM..." -ForegroundColor Cyan

$RAMTotal =
    [math]::Round(
        $Sistema.TotalPhysicalMemory / 1GB,
        1
    )

$RAMUso =
    [math]::Round(
        (
            (
                $SO.TotalVisibleMemorySize -
                $SO.FreePhysicalMemory
            ) /
            $SO.TotalVisibleMemorySize
        ) * 100,
        1
    )

$RAMLivre =
    [math]::Round(
        $SO.FreePhysicalMemory / 1MB,
        1
    )

$ModulosRAM = @()

try {

    $ModulosRAM = @(
        Get-CimInstance Win32_PhysicalMemory |
        ForEach-Object {

            [PSCustomObject]@{

                Slot =
                    $_.DeviceLocator

                Fabricante =
                    if ($_.Manufacturer) {
                        $_.Manufacturer.Trim()
                    }
                    else {
                        $null
                    }

                NumeroSerie =
                    if ($_.SerialNumber) {
                        $_.SerialNumber.Trim()
                    }
                    else {
                        $null
                    }

                CapacidadeGB =
                    [math]::Round(
                        $_.Capacity / 1GB,
                        1
                    )

                VelocidadeMHz =
                    $_.Speed

                Tipo =
                    Obter-TipoMemoria `
                        -Codigo $_.SMBIOSMemoryType
            }
        }
    )
}
catch {}

# ============================================================
# DISCOS FÍSICOS
# ============================================================

Write-Host "[5/6] Coletando armazenamento..." -ForegroundColor Cyan

$DiscosFisicos = @()

try {

    $DiscosFisicos = @(
        Get-PhysicalDisk |
        ForEach-Object {

            $Disco = $_

            $VidaRestante = $null
            $TemperaturaC = $null

            try {

                $Contador =
                    $Disco |
                    Get-StorageReliabilityCounter

                if ($null -ne $Contador.Wear) {

                    $VidaRestante =
                        100 - $Contador.Wear
                }

                if (
                    $null -ne $Contador.Temperature -and
                    $Contador.Temperature -gt 0
                ) {

                    $TemperaturaC =
                        $Contador.Temperature
                }

            }
            catch {}

            [PSCustomObject]@{

                Numero =
                    $Disco.DeviceId

                Fabricante =
                    if ($Disco.Manufacturer) {
                        $Disco.Manufacturer.Trim()
                    }
                    else {
                        $null
                    }

                Modelo =
                    if ($Disco.FriendlyName) {
                        $Disco.FriendlyName.Trim()
                    }
                    else {
                        $null
                    }

                NumeroSerie =
                    if ($Disco.SerialNumber) {
                        "$($Disco.SerialNumber)".Trim()
                    }
                    else {
                        $null
                    }

                Tipo =
                    $Disco.MediaType

                Interface =
                    $Disco.BusType

                CapacidadeGB =
                    [math]::Round(
                        $Disco.Size / 1GB,
                        1
                    )

                SaudeStatus =
                    $Disco.HealthStatus

                StatusOperacional =
                    ($Disco.OperationalStatus -join ", ")

                VidaRestantePct =
                    $VidaRestante

                TemperaturaC =
                    $TemperaturaC
            }
        }
    )

    if ($DiscosFisicos.Count -eq 0) {

        throw "Nenhum disco retornado"
    }

}
catch {

    $DiscosFisicos = @(
        Get-CimInstance Win32_DiskDrive |
        ForEach-Object {

            [PSCustomObject]@{

                Numero =
                    $_.Index

                Fabricante =
                    if ($_.Manufacturer) {
                        $_.Manufacturer.Trim()
                    }
                    else {
                        $null
                    }

                Modelo =
                    if ($_.Model) {
                        $_.Model.Trim()
                    }
                    else {
                        $null
                    }

                NumeroSerie =
                    if ($_.SerialNumber) {
                        "$($_.SerialNumber)".Trim()
                    }
                    else {
                        $null
                    }

                Tipo = $null

                Interface =
                    $_.InterfaceType

                CapacidadeGB =
                    [math]::Round(
                        $_.Size / 1GB,
                        1
                    )

                SaudeStatus =
                    $_.Status

                StatusOperacional =
                    $_.Status

                VidaRestantePct = $null

                TemperaturaC = $null
            }
        }
    )
}

# ============================================================
# DISCOS LÓGICOS
# ============================================================

$Discos = @()

foreach (
    $D in Get-CimInstance Win32_LogicalDisk `
        -Filter "DriveType=3"
) {

    if ($D.Size -gt 0) {

        $Discos +=
            [PSCustomObject]@{

                Unidade =
                    $D.DeviceID

                TamanhoGB =
                    [math]::Round(
                        $D.Size / 1GB,
                        1
                    )

                LivreGB =
                    [math]::Round(
                        $D.FreeSpace / 1GB,
                        1
                    )

                Uso =
                    [math]::Round(
                        (
                            1 -
                            (
                                $D.FreeSpace /
                                $D.Size
                            )
                        ) * 100,
                        1
                    )
            }
    }
}

# ============================================================
# PROGRAMAS DE INICIALIZAÇÃO
# ============================================================

$Inicializacao = @()

try {

    $Inicializacao = @(
        Get-CimInstance Win32_StartupCommand |
        Select-Object Name, Command
    )
}
catch {}

# ============================================================
# PROCESSOS COM MAIOR CONSUMO
# ============================================================

$Processos = @()

try {

    $Processos = @(
        Get-Process |
        Sort-Object WorkingSet64 -Descending |
        Select-Object -First 15 |
        ForEach-Object {

            [PSCustomObject]@{

                Processo =
                    $_.ProcessName

                MemoriaMB =
                    [math]::Round(
                        $_.WorkingSet64 / 1MB,
                        1
                    )
            }
        }
    )
}
catch {}

# ============================================================
# EVENTOS RECENTES
# ============================================================

$Eventos = @()

try {

    $Eventos = @(
        Get-WinEvent `
            -FilterHashtable @{
                LogName = "System"
                Level = 1,2
            } `
            -MaxEvents 20 |
        ForEach-Object {

            [PSCustomObject]@{

                Data =
                    $_.TimeCreated

                ID =
                    $_.Id

                Origem =
                    $_.ProviderName
            }
        }
    )
}
catch {}

# ============================================================
# ALERTAS
# ============================================================

Write-Host "[6/6] Gerando análise preventiva..." -ForegroundColor Cyan

$Alertas = @()

if ($RAMUso -gt 80) {

    $Alertas +=
        "Uso elevado de memória RAM."
}

if ($UsoCPU -gt 80) {

    $Alertas +=
        "Uso elevado de CPU."
}

foreach ($D in $Discos) {

    if ($D.Uso -gt 85) {

        $Alertas +=
            "Disco $($D.Unidade) acima de 85% de utilização."
    }
}

foreach ($DF in $DiscosFisicos) {

    if (
        $DF.SaudeStatus -and
        $DF.SaudeStatus -notin @(
            "Healthy",
            "OK"
        )
    ) {

        $Alertas +=
            "Disco $($DF.Modelo) com saúde: $($DF.SaudeStatus)."
    }

    if (
        $null -ne $DF.VidaRestantePct -and
        $DF.VidaRestantePct -lt 20
    ) {

        $Alertas +=
            "Disco $($DF.Modelo) com vida restante baixa: $($DF.VidaRestantePct)%."
    }
}

# ============================================================
# OBJETO DO INVENTÁRIO
# ============================================================

$Objeto =
    [PSCustomObject]@{

        data =
            Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        cliente =
            $DadosCliente.cliente

        tipo_cliente =
            $DadosCliente.tipo_cliente

        contrato =
            $DadosCliente.contrato

        computador =
            $Computador

        usuario =
            $Usuario

        sistema =
            [PSCustomObject]@{

                fabricante =
                    $Fabricante

                modelo =
                    $Modelo

                serial =
                    $Serial

                windows =
                    $VersaoWindows

                build =
                    "$BuildWindows.$UBRWindows"

                boot =
                    $Boot

                tempo_ligado_horas =
                    if ($TempoLigado) {
                        [math]::Round(
                            $TempoLigado.TotalHours,
                            1
                        )
                    }
                    else {
                        $null
                    }
            }

        processador =
            [PSCustomObject]@{

                modelo =
                    $CPU

                nucleos =
                    $Nucleos

                threads =
                    $Threads

                uso_percentual =
                    $UsoCPU
            }

        memoria =
            [PSCustomObject]@{

                total_gb =
                    $RAMTotal

                livre_gb =
                    $RAMLivre

                uso_percentual =
                    $RAMUso

                modulos =
                    $ModulosRAM
            }

        armazenamento =
            [PSCustomObject]@{

                discos_fisicos =
                    $DiscosFisicos

                unidades =
                    $Discos
            }

        inicializacao =
            [PSCustomObject]@{

                quantidade =
                    $Inicializacao.Count

                programas =
                    $Inicializacao
            }

        processos =
            $Processos

        eventos =
            $Eventos

        alertas =
            $Alertas
    }

# ============================================================
# JSON
# ============================================================

Write-Host ""
Write-Host "Preparando inventário..." -ForegroundColor Yellow

$JSON =
    $Objeto |
    ConvertTo-Json -Depth 15

# ============================================================
# ENVIO
# ============================================================

Write-Host ""
Write-Host "Enviando inventário para LR Tecnologia..." -ForegroundColor Yellow
Write-Host ""

$StatusServidor = "NÃO TESTADO"

try {

    $Resposta =
        Invoke-RestMethod `
            -Uri $UrlServidor `
            -Method Post `
            -Headers @{
                "X-SEATTLE-KEY" = $ChaveSeattle
            } `
            -ContentType "application/json; charset=utf-8" `
            -Body $JSON `
            -ErrorAction Stop

    if ($Resposta.sucesso -eq $true) {

        $StatusServidor = "OK"

        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Green
        Write-Host "       INVENTÁRIO ENVIADO COM SUCESSO!" -ForegroundColor Green
        Write-Host "============================================================" -ForegroundColor Green
    }
    else {

        $StatusServidor = "RECUSADO"

        Write-Host ""
        Write-Host "O servidor recusou o inventário." -ForegroundColor Red
        Write-Host $Resposta.mensagem -ForegroundColor Red
    }

}
catch {

    $StatusServidor = "OFFLINE"

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host "        FALHA NO ENVIO DO INVENTÁRIO" -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# ============================================================
# RESUMO
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "                 DIAGNÓSTICO FINALIZADO" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Cliente    : " -NoNewline
Write-Host $DadosCliente.cliente -ForegroundColor Yellow

Write-Host "Categoria  : " -NoNewline
Write-Host $DadosCliente.tipo_cliente -ForegroundColor Yellow

Write-Host "Contrato   : " -NoNewline
Write-Host $DadosCliente.contrato -ForegroundColor Yellow

Write-Host "Computador : " -NoNewline
Write-Host $Computador -ForegroundColor Yellow

Write-Host "Usuário    : " -NoNewline
Write-Host $Usuario -ForegroundColor Yellow

Write-Host "Fabricante : " -NoNewline
Write-Host $Fabricante -ForegroundColor Yellow

Write-Host "Modelo     : " -NoNewline
Write-Host $Modelo -ForegroundColor Yellow

Write-Host "Windows    : " -NoNewline
Write-Host $VersaoWindows -ForegroundColor Yellow

Write-Host "CPU        : " -NoNewline
Write-Host "$UsoCPU %" -ForegroundColor Yellow

Write-Host "RAM        : " -NoNewline
Write-Host "$RAMTotal GB / $RAMUso %" -ForegroundColor Yellow

Write-Host "Servidor   : " -NoNewline

if ($StatusServidor -eq "OK") {

    Write-Host "ONLINE - INVENTÁRIO ARMAZENADO" -ForegroundColor Green

}
else {

    Write-Host $StatusServidor -ForegroundColor Red
}

# ============================================================
# ALERTAS
# ============================================================

Write-Host ""

if ($Alertas.Count -gt 0) {

    Write-Host "ALERTAS PREVENTIVOS:" -ForegroundColor Red
    Write-Host ""

    foreach ($A in $Alertas) {

        Write-Host " - $A" -ForegroundColor Yellow
    }

}
else {

    Write-Host "Nenhum alerta preventivo identificado." -ForegroundColor Green
}

Write-Host ""

Pausar-Diagnostico
