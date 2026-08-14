# ============================================================
# Módulo Seattle by LR Tecnologia
# Criado e desenvolvido por Leonardo M. Batista.
# ============================================================
# Módulo: Manutenção
# Inventário do computador
# Versão 1.3.0
#
# SOMENTE LEITURA
#
# Esta versão NÃO grava inventário permanentemente
# no computador do cliente.
#
# Os dados são enviados diretamente para a HostGator.
# ============================================================
param(
    [string]$Cliente = "Não informado",
    [string]$TipoCliente = "Não informado"
)

$ErrorActionPreference = "SilentlyContinue"

# ============================================================
# CONFIGURAÇÃO
# ============================================================

$UrlServidor = "https://lrtecnologia.net.br/seattle/receber_inventario.php"

# COLOQUE AQUI A MESMA CHAVE DO receber_inventario.php
$ChaveSeattle = ")#twPMPaKsj>d23}y3covTxvmr1Ht*EA3iHc=WQQEFVB424H>}"

# ============================================================
# ESTRUTURA LOCAL
# ============================================================

$Base = "C:\ProgramData\LR Tecnologia"
$Relatorios = "$Base\Relatorios"
$Historico = "$Base\Historico"
$Logs = "$Base\Logs"

foreach ($P in @($Base, $Relatorios, $Historico, $Logs)) {

    if (!(Test-Path $P)) {
        New-Item -Path $P -ItemType Directory -Force | Out-Null
    }
}

$Log = "$Logs\Seattle.log"

function Log {
    param($Texto)

    Add-Content $Log "$(Get-Date -Format 'dd/MM/yyyy HH:mm:ss') - $Texto"
}

# ============================================================
# TIPO DE MEMÓRIA (tradução do código numérico do Windows)
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

# ============================================================
# CABEÇALHO
# ============================================================

Clear-Host

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "              ROBÔ LR TECNOLOGIA" -ForegroundColor Cyan
Write-Host "          DIAGNÓSTICO PREVENTIVO v1.3.0" -ForegroundColor Cyan
Write-Host ""
Write-Host "                  SOMENTE LEITURA" -ForegroundColor Yellow
Write-Host "       Não altera configurações do computador" -ForegroundColor Gray
Write-Host "       Não remove programas" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Log "===== INÍCIO DIAGNÓSTICO ====="

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

Log "Identificação coletada"

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
# Get-CimInstance já retorna LastBootUpTime como [DateTime],
# diferente do Get-WmiObject (que retorna string DMTF).
# ============================================================

$Boot = $null
$TempoLigado = $null

try {

    $ValorBoot = $SO.LastBootUpTime

    if ($null -eq $ValorBoot) {

        throw "SO.LastBootUpTime veio nulo"
    }
    elseif ($ValorBoot -is [string]) {

        $Boot = [Management.ManagementDateTimeConverter]::ToDateTime($ValorBoot)
    }
    else {

        $Boot = $ValorBoot
    }

    $TempoLigado = New-TimeSpan -Start $Boot -End (Get-Date)

}
catch {

    Log "Não foi possível obter tempo ligado: $($_.Exception.Message)"
}

# ============================================================
# CPU
# ============================================================

Write-Host "[3/6] Coletando processador..." -ForegroundColor Cyan

$CPUInfo = Get-CimInstance Win32_Processor |
    Select-Object -First 1

$CPU = $CPUInfo.Name
$Nucleos = $CPUInfo.NumberOfCores
$Threads = $CPUInfo.NumberOfLogicalProcessors

$UsoCPU = 0

try {

    $ContadorCPU = Get-Counter `
        "\Processor(_Total)\% Processor Time"

    $UsoCPU = [math]::Round(
        $ContadorCPU.CounterSamples.CookedValue,
        1
    )

}
catch {

    Log "Não foi possível obter uso da CPU"
}

# ============================================================
# RAM (uso geral + hardware por pente)
# ============================================================

Write-Host "[4/6] Coletando memória RAM..." -ForegroundColor Cyan

$RAMTotal = [math]::Round(
    $Sistema.TotalPhysicalMemory / 1GB,
    1
)

$RAMUso = [math]::Round(
    (
        (
            $SO.TotalVisibleMemorySize -
            $SO.FreePhysicalMemory
        ) /
        $SO.TotalVisibleMemorySize
    ) * 100,
    1
)

$RAMLivre = [math]::Round(
    $SO.FreePhysicalMemory / 1MB,
    1
)

$ModulosRAM = @()

try {

    $ModulosRAM = @(
        Get-CimInstance Win32_PhysicalMemory -ErrorAction Stop |
        ForEach-Object {

            [PSCustomObject]@{

                Slot          = $_.DeviceLocator
                Fabricante    = if ($_.Manufacturer) { $_.Manufacturer.Trim() } else { $null }
                NumeroSerie   = if ($_.SerialNumber) { $_.SerialNumber.Trim() } else { $null }
                CapacidadeGB  = [math]::Round($_.Capacity / 1GB, 1)
                VelocidadeMHz = $_.Speed
                Tipo          = Obter-TipoMemoria -Codigo $_.SMBIOSMemoryType
            }
        }
    )

}
catch {

    Log "Não foi possível coletar módulos de memória RAM: $($_.Exception.Message)"
}

Log "Hardware de memória coletado"

# ============================================================
# DISCOS FÍSICOS (hardware, modelo, saúde)
# ============================================================
# Get-PhysicalDisk traz fabricante, modelo, número de série,
# tipo de mídia (SSD/HDD), interface e status de saúde.
# Get-StorageReliabilityCounter complementa com % de vida
# restante quando o disco expõe esse dado.
# Requer o módulo Storage (nativo no Win10/11) e, para dados
# completos, execução como Administrador.
# ============================================================

Write-Host "[5/6] Coletando armazenamento..." -ForegroundColor Cyan

$DiscosFisicos = @()

try {

    $DiscosFisicos = @(
        Get-PhysicalDisk -ErrorAction Stop |
        ForEach-Object {

            $Disco = $_
            $VidaRestante = $null
            $TemperaturaC = $null

            try {

                $Contador = $Disco |
                    Get-StorageReliabilityCounter -ErrorAction Stop

                if ($null -ne $Contador.Wear) {
                    $VidaRestante = 100 - $Contador.Wear
                }

                if ($null -ne $Contador.Temperature -and $Contador.Temperature -gt 0) {
                    $TemperaturaC = $Contador.Temperature
                }

            }
            catch {}

            [PSCustomObject]@{

                Numero            = $Disco.DeviceId
                Fabricante        = if ($Disco.Manufacturer) { $Disco.Manufacturer.Trim() } else { $null }
                Modelo            = if ($Disco.FriendlyName) { $Disco.FriendlyName.Trim() } else { $null }
                NumeroSerie       = if ($Disco.SerialNumber) { $Disco.SerialNumber.Trim() } else { $null }
                Tipo              = $Disco.MediaType
                Interface         = $Disco.BusType
                CapacidadeGB      = [math]::Round($Disco.Size / 1GB, 1)
                SaudeStatus       = $Disco.HealthStatus
                StatusOperacional = ($Disco.OperationalStatus -join ", ")
                VidaRestantePct   = $VidaRestante
                TemperaturaC      = $TemperaturaC
            }
        }
    )

    if ($DiscosFisicos.Count -eq 0) {

        throw "Get-PhysicalDisk não retornou discos"
    }

}
catch {

    Log "Get-PhysicalDisk indisponível ou vazio, usando Win32_DiskDrive como alternativa: $($_.Exception.Message)"

    $DiscosFisicos = @(
        Get-CimInstance Win32_DiskDrive |
        ForEach-Object {

            [PSCustomObject]@{

                Numero            = $_.Index
                Fabricante        = if ($_.Manufacturer) { $_.Manufacturer.Trim() } else { $null }
                Modelo            = if ($_.Model) { $_.Model.Trim() } else { $null }
                NumeroSerie       = if ($_.SerialNumber) { ("$($_.SerialNumber)").Trim() } else { $null }
                Tipo              = $null
                Interface         = $_.InterfaceType
                CapacidadeGB      = [math]::Round($_.Size / 1GB, 1)
                SaudeStatus       = $_.Status
                StatusOperacional = $_.Status
                VidaRestantePct   = $null
                TemperaturaC      = $null
            }
        }
    )
}

Log "Discos físicos coletados"

# ============================================================
# DISCOS LÓGICOS (espaço livre/uso por unidade)
# ============================================================

$Discos = @()

foreach (
    $D in Get-CimInstance Win32_LogicalDisk `
        -Filter "DriveType=3"
) {

    if ($D.Size -gt 0) {

        $Discos += [PSCustomObject]@{

            Unidade = $D.DeviceID

            TamanhoGB = [math]::Round(
                $D.Size / 1GB,
                1
            )

            LivreGB = [math]::Round(
                $D.FreeSpace / 1GB,
                1
            )

            Uso = [math]::Round(
                (1 - ($D.FreeSpace / $D.Size)) * 100,
                1
            )
        }
    }
}

Log "Discos lógicos coletados"

# ============================================================
# ALERTAS
# ============================================================

Write-Host "[6/6] Gerando análise preventiva..." -ForegroundColor Cyan

$Alertas = @()

if ($RAMUso -gt 80) {

    $Alertas += "Uso elevado de memória RAM"
}

if ($UsoCPU -gt 80) {

    $Alertas += "Uso elevado de CPU"
}

foreach ($D in $Discos) {

    if ($D.Uso -gt 85) {

        $Alertas += "Disco $($D.Unidade) acima de 85%"
    }
}

foreach ($DF in $DiscosFisicos) {

    if ($DF.SaudeStatus -and $DF.SaudeStatus -notin @("Healthy", "OK")) {

        $Alertas += "Disco $($DF.Modelo) com saúde: $($DF.SaudeStatus)"
    }

    if ($null -ne $DF.VidaRestantePct -and $DF.VidaRestantePct -lt 20) {

        $Alertas += "Disco $($DF.Modelo) com vida restante baixa: $($DF.VidaRestantePct)%"
    }
}

# ============================================================
# OBJETO DO INVENTÁRIO
# ============================================================

$Objeto = [PSCustomObject]@{

    data = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    cliente = $Cliente

    tipo_cliente = $TipoCliente

    computador = $Computador

    usuario = $Usuario

    sistema = [PSCustomObject]@{

        fabricante = $Fabricante

        modelo = $Modelo

        serial = $Serial

        windows = $VersaoWindows

        build = "$BuildWindows.$UBRWindows"

        boot = $Boot

        tempo_ligado_horas = if ($TempoLigado) {
            [math]::Round(
                $TempoLigado.TotalHours,
                1
            )
        }
        else {
            $null
        }
    }

    processador = [PSCustomObject]@{

        modelo = $CPU

        nucleos = $Nucleos

        threads = $Threads

        uso_percentual = $UsoCPU
    }

    memoria = [PSCustomObject]@{

        total_gb = $RAMTotal

        livre_gb = $RAMLivre

        uso_percentual = $RAMUso

        modulos = $ModulosRAM
    }

    armazenamento = [PSCustomObject]@{

        discos_fisicos = $DiscosFisicos

        unidades = $Discos
    }

    alertas = $Alertas
}

# ============================================================
# GERA JSON LOCAL
# ============================================================

Write-Host ""
Write-Host "Gerando inventário..." -ForegroundColor Yellow

$PastaPC = "$Historico\$Computador"

if (!(Test-Path $PastaPC)) {

    New-Item `
        -Path $PastaPC `
        -ItemType Directory `
        -Force |
        Out-Null
}

$DataArquivo = Get-Date -Format "yyyyMMdd_HHmmss"

$ArquivoJSON =
    "$PastaPC\inventario_$DataArquivo.json"

$JSON = $Objeto |
    ConvertTo-Json -Depth 10

$JSON |
    Out-File `
        -FilePath $ArquivoJSON `
        -Encoding UTF8

Log "JSON local criado"

# ============================================================
# ENVIA PARA HOSTGATOR
# ============================================================

Write-Host ""
Write-Host "Enviando inventário para LR Tecnologia..." -ForegroundColor Yellow

$StatusServidor = "NÃO TESTADO"

try {

    $Resposta = Invoke-RestMethod `
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
        Write-Host "Inventário enviado com sucesso!" -ForegroundColor Green

        Log "Inventário enviado para servidor com sucesso"

    }
    else {

        $StatusServidor = "RECUSADO"

        Write-Host ""
        Write-Host "O servidor recusou o inventário." -ForegroundColor Red

        Log "Servidor recusou inventário"
    }

}
catch {

    $StatusServidor = "OFFLINE"

    Write-Host ""
    Write-Host "Não foi possível enviar o inventário." -ForegroundColor Red
    Write-Host "O arquivo local foi preservado." -ForegroundColor Yellow

    Log "Erro no envio: $($_.Exception.Message)"
}

# ============================================================
# RESULTADO
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "              INVENTÁRIO FINALIZADO" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

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

Write-Host "Boot       : " -NoNewline

if ($Boot) {

    Write-Host "$Boot" -ForegroundColor Yellow

}
else {

    Write-Host "Não disponível" -ForegroundColor Red
}

Write-Host "Ligado há  : " -NoNewline

if ($TempoLigado) {

    Write-Host "$([math]::Round($TempoLigado.TotalHours,1)) horas" -ForegroundColor Yellow

}
else {

    Write-Host "Não disponível" -ForegroundColor Red
}

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

Write-Host ""

# ============================================================
# MÓDULOS DE RAM
# ============================================================

Write-Host "MEMÓRIA RAM (FÍSICO):" -ForegroundColor Cyan
Write-Host ""

foreach ($M in $ModulosRAM) {

    Write-Host " - Slot $($M.Slot): $($M.Fabricante) $($M.CapacidadeGB) GB $($M.Tipo) @ $($M.VelocidadeMHz) MHz" -ForegroundColor Yellow
}

Write-Host ""

# ============================================================
# DISCOS FÍSICOS
# ============================================================

Write-Host "ARMAZENAMENTO (FÍSICO):" -ForegroundColor Cyan
Write-Host ""

foreach ($DF in $DiscosFisicos) {

    Write-Host " - $($DF.Fabricante) $($DF.Modelo)" -ForegroundColor Yellow
    Write-Host "   Tipo: $($DF.Tipo)  |  Interface: $($DF.Interface)  |  Capacidade: $($DF.CapacidadeGB) GB" -ForegroundColor Gray

    Write-Host "   Saúde: " -NoNewline -ForegroundColor Gray

    if ($DF.SaudeStatus -in @("Healthy", "OK")) {
        Write-Host "$($DF.SaudeStatus)" -ForegroundColor Green -NoNewline
    }
    else {
        Write-Host "$($DF.SaudeStatus)" -ForegroundColor Red -NoNewline
    }

    if ($null -ne $DF.VidaRestantePct) {
        Write-Host "  |  Vida restante: $($DF.VidaRestantePct)%" -ForegroundColor Gray
    }
    else {
        Write-Host ""
    }

    Write-Host ""
}

# ============================================================
# ALERTAS
# ============================================================

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

# ============================================================
# ARQUIVO LOCAL
# ============================================================

Write-Host ""
Write-Host "Arquivo local:" -ForegroundColor Gray
Write-Host $ArquivoJSON -ForegroundColor DarkGray

Write-Host ""

Log "===== FINALIZADO ====="

Write-Host "Pressione ENTER para voltar ao menu..." -ForegroundColor Gray

Read-Host
