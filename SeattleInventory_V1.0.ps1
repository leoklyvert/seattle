# ============================================================
# SEATTLE INVENTORY V1.0.1
# LR Tecnologia
# Inventario local de hardware, software e rede
#
# Compatibilidade: Windows 10/11
# PowerShell 5.1 ou superior
#
# MODO: SOMENTE LEITURA
# - Nao altera configuracoes
# - Nao instala programas
# - Nao executa varredura ativa na rede
# - Nao transmite dados pela internet
# - Nao coleta senhas ou chaves de produto
#
# SAIDAS:
# - Arquivo JSON completo
# - Relatorio HTML visual e interativo
# ============================================================

[CmdletBinding()]
param(
    [string]$OutputDirectory = (
        Join-Path ([Environment]::GetFolderPath('Desktop')) 'SeattleInventory'
    )
)

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

# ------------------------------------------------------------
# FUNCOES AUXILIARES
# ------------------------------------------------------------

function ConvertTo-GB {
    param($Bytes)

    if ($null -eq $Bytes -or [double]$Bytes -le 0) {
        return $null
    }

    return [math]::Round(([double]$Bytes / 1GB), 2)
}

function ConvertTo-SafeText {
    param($Value)

    if ($null -eq $Value) {
        return ''
    }

    $text = [string]$Value
    $text = $text -replace '[\x00-\x08\x0B\x0C\x0E-\x1F]', ''
    return $text.Trim()
}

function Get-MemoryType {
    param([int]$Code)

    $types = @{
        0  = 'Desconhecido'
        20 = 'DDR'
        21 = 'DDR2'
        22 = 'DDR2 FB-DIMM'
        24 = 'DDR3'
        26 = 'DDR4'
        27 = 'LPDDR'
        28 = 'LPDDR2'
        29 = 'LPDDR3'
        30 = 'LPDDR4'
        34 = 'DDR5'
        35 = 'LPDDR5'
    }

    if ($types.ContainsKey($Code)) {
        return $types[$Code]
    }

    return "Codigo SMBIOS $Code"
}

function Get-MemoryManufacturer {
    param($Manufacturer)

    $value = ConvertTo-SafeText $Manufacturer

    if (-not $value) {
        return 'Nao identificado'
    }

    $map = @{
        '014F' = 'Transcend'
        '04CB' = 'A-DATA'
        '04CD' = 'G.Skill'
        '04B3' = 'Kingston'
        '04F1' = 'Corsair'
        '0198' = 'Kingston'
        '02FE' = 'Micron'
        '04A3' = 'Samsung'
        '04B0' = 'Samsung'
        '04F0' = 'SK Hynix'
        '04F2' = 'SK Hynix'
        '080A' = 'Crucial'
    }

    $key = $value -replace '^0x', ''

    if ($map.ContainsKey($key.ToUpper())) {
        return $map[$key.ToUpper()]
    }

    return $value
}

function Get-InstalledSoftware {

    $paths = @(
        'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )

    $items = foreach ($path in $paths) {

        Get-ItemProperty -Path $path -ErrorAction SilentlyContinue |
            Where-Object { $_.DisplayName } |
            ForEach-Object {

                [PSCustomObject]@{
                    Nome            = $_.DisplayName
                    Versao          = $_.DisplayVersion
                    Fabricante      = $_.Publisher
                    DataInstalacao  = $_.InstallDate
                    LocalInstalacao = $_.InstallLocation
                }
            }
    }

    return @($items | Sort-Object Nome, Versao -Unique)
}

function Get-ProcessNameById {
    param([int]$ProcessId)

    if ($ProcessId -le 0) {
        return 'Sistema'
    }

    try {
        $process = Get-Process -Id $ProcessId -ErrorAction Stop
        return $process.ProcessName
    }
    catch {
        return 'Processo indisponivel'
    }
}

function Get-HtmlEncoded {
    param($Value)

    if ($null -eq $Value) {
        return ''
    }

    return [System.Net.WebUtility]::HtmlEncode([string]$Value)
}

# ------------------------------------------------------------
# IDENTIFICACAO DO COMPUTADOR
# ------------------------------------------------------------

function Get-ComputerInventory {

    $computer = Get-CimInstance Win32_ComputerSystem
    $bios = Get-CimInstance Win32_BIOS
    $board = Get-CimInstance Win32_BaseBoard
    $os = Get-CimInstance Win32_OperatingSystem

    $registry = Get-ItemProperty `
        'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' `
        -ErrorAction SilentlyContinue

    [PSCustomObject]@{

        NomeComputador = $env:COMPUTERNAME

        UsuarioLogado = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

        Fabricante = $computer.Manufacturer
        Modelo = $computer.Model
        DominioOuGrupo = $computer.Domain
        ParticipaDominio = $computer.PartOfDomain

        NumeroSerieBIOS = $bios.SerialNumber
        FabricanteBIOS = $bios.Manufacturer
        VersaoBIOS = $bios.SMBIOSBIOSVersion
        DataBIOS = $bios.ReleaseDate

        PlacaMaeFabricante = $board.Manufacturer
        PlacaMaeModelo = $board.Product
        PlacaMaeVersao = $board.Version
        PlacaMaeNumeroSerie = $board.SerialNumber

        Windows = $os.Caption
        VersaoWindows = $os.Version
        BuildWindows = $os.BuildNumber
        Arquitetura = $os.OSArchitecture

        EdicaoWindows = $registry.EditionID
        DisplayVersion = $registry.DisplayVersion

        DataInstalacaoWindows = $os.InstallDate
        UltimoBoot = $os.LastBootUpTime
    }
}

# ------------------------------------------------------------
# HARDWARE
# ------------------------------------------------------------

function Get-HardwareInventory {

    Write-Host '  Processador...'

    $cpu = @(Get-CimInstance Win32_Processor |
        ForEach-Object {

            [PSCustomObject]@{
                Modelo = $_.Name
                Fabricante = $_.Manufacturer
                Nucleos = $_.NumberOfCores
                ProcessadoresLogicos = $_.NumberOfLogicalProcessors
                FrequenciaAtualMHz = $_.CurrentClockSpeed
                FrequenciaMaximaMHz = $_.MaxClockSpeed
                Soquete = $_.SocketDesignation
            }
        })

    Write-Host '  Memoria RAM...'

    $memory = @(Get-CimInstance Win32_PhysicalMemory |
        ForEach-Object {

            [PSCustomObject]@{
                Fabricante = Get-MemoryManufacturer $_.Manufacturer
                CapacidadeGB = ConvertTo-GB $_.Capacity
                VelocidadeMHz = $_.Speed
                VelocidadeConfiguradaMHz = $_.ConfiguredClockSpeed
                Tipo = Get-MemoryType ([int]$_.SMBIOSMemoryType)
                NumeroSerie = $_.SerialNumber
                PartNumber = $_.PartNumber
                Banco = $_.BankLabel
                Slot = $_.DeviceLocator
            }
        })

    Write-Host '  Placas de video...'

    $gpu = @(Get-CimInstance Win32_VideoController |
        ForEach-Object {

            [PSCustomObject]@{
                Nome = $_.Name
                Fabricante = $_.AdapterCompatibility
                DriverVersao = $_.DriverVersion
                ProcessadorVideo = $_.VideoProcessor

                Resolucao = if (
                    $_.CurrentHorizontalResolution -and
                    $_.CurrentVerticalResolution
                ) {
                    "$($_.CurrentHorizontalResolution)x$($_.CurrentVerticalResolution)"
                } else {
                    $null
                }

                MemoriaRelatadaGB = ConvertTo-GB $_.AdapterRAM
            }
        })

    Write-Host '  Discos fisicos...'

    $disks = @(Get-CimInstance Win32_DiskDrive |
        ForEach-Object {

            [PSCustomObject]@{
                Modelo = $_.Model
                Fabricante = $_.Manufacturer
                NumeroSerie = $_.SerialNumber
                Interface = $_.InterfaceType
                TipoMidia = $_.MediaType
                CapacidadeGB = ConvertTo-GB $_.Size
                Firmware = $_.FirmwareRevision
                Status = $_.Status
                Identificador = $_.DeviceID
            }
        })

    Write-Host '  Unidades e volumes...'

    $volumes = @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' |
        ForEach-Object {

            $type = 'Unidade local'

            if (
                $_.VolumeName -match 'Google Drive|OneDrive|Dropbox' -or
                $_.ProviderName
            ) {
                $type = 'Possivel unidade virtual ou sincronizada'
            }

            [PSCustomObject]@{
                Unidade = $_.DeviceID
                Nome = $_.VolumeName
                SistemaArquivos = $_.FileSystem
                TipoUnidade = $type
                CapacidadeGB = ConvertTo-GB $_.Size
                LivreGB = ConvertTo-GB $_.FreeSpace

                LivrePercentual = if ($_.Size -gt 0) {
                    [math]::Round(($_.FreeSpace / $_.Size) * 100, 1)
                } else {
                    $null
                }

                OcupadoPercentual = if ($_.Size -gt 0) {
                    [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 1)
                } else {
                    $null
                }
            }
        })

    Write-Host '  Saude dos discos...'

    $diskHealth = @()

    if (Get-Command Get-PhysicalDisk -ErrorAction SilentlyContinue) {

        $diskHealth = @(Get-PhysicalDisk -ErrorAction SilentlyContinue |
            ForEach-Object {

                $reliability = $null

                if (Get-Command Get-StorageReliabilityCounter -ErrorAction SilentlyContinue) {

                    $reliability = Get-StorageReliabilityCounter `
                        -PhysicalDisk $_ `
                        -ErrorAction SilentlyContinue
                }

                [PSCustomObject]@{
                    Nome = $_.FriendlyName
                    NumeroSerie = $_.SerialNumber
                    TipoMidia = [string]$_.MediaType
                    Saude = [string]$_.HealthStatus
                    Status = [string]$_.OperationalStatus

                    TemperaturaC = if ($reliability) {
                        $reliability.Temperature
                    } else {
                        $null
                    }

                    HorasLigado = if ($reliability) {
                        $reliability.PowerOnHours
                    } else {
                        $null
                    }
                }
            })
    }

    Write-Host '  Monitores...'

    $monitors = @(Get-CimInstance `
        -Namespace root\wmi `
        -ClassName WmiMonitorID `
        -ErrorAction SilentlyContinue |
        ForEach-Object {

            $name = -join (
                $_.UserFriendlyName |
                Where-Object { $_ -ne 0 } |
                ForEach-Object { [char]$_ }
            )

            $serial = -join (
                $_.SerialNumberID |
                Where-Object { $_ -ne 0 } |
                ForEach-Object { [char]$_ }
            )

            $manufacturer = -join (
                $_.ManufacturerName |
                Where-Object { $_ -ne 0 } |
                ForEach-Object { [char]$_ }
            )

            [PSCustomObject]@{
                Fabricante = ConvertTo-SafeText $manufacturer
                Modelo = ConvertTo-SafeText $name
                NumeroSerie = ConvertTo-SafeText $serial
                Ativo = $_.Active
            }
        } |
        Where-Object {
            $_.Fabricante -or $_.Modelo -or $_.NumeroSerie
        })

    Write-Host '  Dispositivos USB...'

    $usb = @(Get-CimInstance Win32_PnPEntity |
        Where-Object { $_.PNPDeviceID -like 'USB*' } |
        ForEach-Object {

            [PSCustomObject]@{
                Nome = $_.Name
                Fabricante = $_.Manufacturer
                Status = $_.Status
                Identificador = $_.PNPDeviceID
            }
        })

    Write-Host '  Sensores termicos ACPI...'

    $temperatures = @(Get-CimInstance `
        -Namespace root\wmi `
        -ClassName MSAcpi_ThermalZoneTemperature `
        -ErrorAction SilentlyContinue |
        ForEach-Object {

            [PSCustomObject]@{
                TemperaturaC = [math]::Round(
                    ($_.CurrentTemperature / 10) - 273.15,
                    1
                )

                Metodo = 'Zona termica ACPI'
            }
        })

    Write-Host '  Bateria...'

    $battery = @()

    $batteryInfo = Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue

    if ($batteryInfo) {

        $battery = @($batteryInfo |
            ForEach-Object {

                [PSCustomObject]@{
                    Nome = $_.Name
                    Fabricante = $_.Manufacturer
                    NumeroSerie = $_.SerialNumber
                    Status = $_.Status
                    CargaPercentual = $_.EstimatedChargeRemaining
                    TempoRestanteMinutos = $_.EstimatedRunTime
                    Quimica = $_.Chemistry
                }
            })
    }

    $batteryDesign = @()

    try {
        $batteryDesign = @(Get-CimInstance `
            -Namespace root\wmi `
            -ClassName BatteryStaticData `
            -ErrorAction Stop |
            ForEach-Object {

                [PSCustomObject]@{
                    Fabricante = $_.ManufacturerName
                    Nome = $_.DeviceName
                    CapacidadeOriginalmWh = $_.DesignedCapacity
                    NumeroSerie = $_.SerialNumber
                }
            })
    }
    catch {}

    $batteryFull = @()

    try {
        $batteryFull = @(Get-CimInstance `
            -Namespace root\wmi `
            -ClassName BatteryFullChargedCapacity `
            -ErrorAction Stop |
            ForEach-Object {

                [PSCustomObject]@{
                    CapacidadeAtualmWh = $_.FullChargedCapacity
                }
            })
    }
    catch {}

    [PSCustomObject]@{

        Processadores = $cpu
        MemoriaRAM = $memory
        PlacasVideo = $gpu
        DiscosFisicos = $disks
        SaudeDiscos = $diskHealth
        Volumes = $volumes
        Monitores = $monitors
        DispositivosUSB = $usb
        SensoresTermicos = $temperatures
        Baterias = $battery
        DadosCapacidadeBateria = $batteryDesign
        CapacidadeAtualBateria = $batteryFull
    }
}

# ------------------------------------------------------------
# SOFTWARE E SEGURANCA
# ------------------------------------------------------------

function Get-SoftwareInventory {

    Write-Host '  Programas instalados...'

    $programs = Get-InstalledSoftware

    Write-Host '  Licenciamento Windows...'

    $license = @(Get-CimInstance SoftwareLicensingProduct |
        Where-Object {
            $_.PartialProductKey -and
            $_.Name -like 'Windows*'
        } |
        ForEach-Object {

            $status = switch ([int]$_.LicenseStatus) {
                0 { 'Nao licenciado' }
                1 { 'Licenciado' }
                2 { 'Carencia inicial' }
                3 { 'Carencia adicional' }
                4 { 'Carencia nao genuina' }
                5 { 'Notificacao' }
                6 { 'Carencia estendida' }
                default { 'Indeterminado' }
            }

            [PSCustomObject]@{
                Produto = $_.Name
                Descricao = $_.Description
                EstadoAtivacao = $status
                ChaveProduto = '[NAO COLETADA]'
            }
        })

    Write-Host '  Antivirus...'

    $antivirus = @(Get-CimInstance `
        -Namespace root\SecurityCenter2 `
        -ClassName AntivirusProduct `
        -ErrorAction SilentlyContinue |
        ForEach-Object {

            [PSCustomObject]@{
                Nome = $_.displayName
                Caminho = $_.pathToSignedProductExe
                EstadoBruto = $_.productState
                Interpretacao = 'Estado bruto coletado; requer validacao especifica do produto'
            }
        })

    Write-Host '  Firewall...'

    $firewall = @()

    if (Get-Command Get-NetFirewallProfile -ErrorAction SilentlyContinue) {

        $firewall = @(Get-NetFirewallProfile |
            ForEach-Object {

                [PSCustomObject]@{
                    Perfil = $_.Name
                    Habilitado = $_.Enabled
                    AcaoEntrada = [string]$_.DefaultInboundAction
                    AcaoSaida = [string]$_.DefaultOutboundAction
                }
            })
    }

    Write-Host '  Atualizacoes instaladas...'

    $updates = @(Get-HotFix |
        ForEach-Object {

            [PSCustomObject]@{
                KB = $_.HotFixID
                Descricao = $_.Description
                InstaladoPor = $_.InstalledBy
                DataInstalacao = $_.InstalledOn
            }
        })

    Write-Host '  Drivers...'

    $drivers = @(Get-CimInstance Win32_PnPSignedDriver |
        ForEach-Object {

            [PSCustomObject]@{
                Dispositivo = $_.DeviceName
                Fabricante = $_.Manufacturer
                Versao = $_.DriverVersion
                Data = $_.DriverDate
                Assinado = $_.IsSigned
                Provedor = $_.DriverProviderName
            }
        })

    [PSCustomObject]@{

        ProgramasInstalados = $programs
        LicenciamentoWindows = $license
        Antivirus = $antivirus
        Firewall = $firewall
        AtualizacoesInstaladas = $updates
        Drivers = $drivers

        Observacoes = @(
            'Programas portateis podem nao aparecer na lista.',
            'Get-HotFix nao representa necessariamente todas as atualizacoes do Windows Update.',
            'Nenhuma senha ou chave de produto e coletada.',
            'A ativacao do Office nao e verificada nesta versao.',
            'O estado do antivirus e apresentado como dado bruto, sem presumir que esteja ativo.'
        )
    }
}

# ------------------------------------------------------------
# REDE
# ------------------------------------------------------------

function Get-NetworkInventory {

    Write-Host '  Adaptadores de rede...'

    $adapters = @(Get-CimInstance Win32_NetworkAdapterConfiguration |
        Where-Object { $_.IPEnabled } |
        ForEach-Object {

            [PSCustomObject]@{
                Descricao = $_.Description
                MAC = $_.MACAddress
                DHCP = $_.DHCPEnabled
                EnderecosIP = @($_.IPAddress)
                Mascara = @($_.IPSubnet)
                Gateway = @($_.DefaultIPGateway)
                DNS = @($_.DNSServerSearchOrder)
                ServidorDHCP = $_.DHCPServer
                DominioDNS = $_.DNSDomain
            }
        })

    Write-Host '  Compartilhamentos...'

    $shares = @(Get-CimInstance Win32_Share |
        ForEach-Object {

            [PSCustomObject]@{
                Nome = $_.Name
                Caminho = $_.Path
                Tipo = $_.Type
                Descricao = $_.Description
            }
        })

    Write-Host '  Unidades de rede...'

    $mappedDrives = @(Get-CimInstance Win32_LogicalDisk `
        -Filter 'DriveType=4' |
        ForEach-Object {

            [PSCustomObject]@{
                Unidade = $_.DeviceID
                Caminho = $_.ProviderName
                Nome = $_.VolumeName
            }
        })

    Write-Host '  Portas TCP em escuta...'

    $tcp = @()

    if (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue) {

        $tcp = @(Get-NetTCPConnection -State Listen |
            Select-Object -First 500 |
            ForEach-Object {

                [PSCustomObject]@{
                    EnderecoLocal = $_.LocalAddress
                    Porta = $_.LocalPort
                    PID = $_.OwningProcess
                    Processo = Get-ProcessNameById $_.OwningProcess
                }
            })
    }

    Write-Host '  Endpoints UDP...'

    $udp = @()

    if (Get-Command Get-NetUDPEndpoint -ErrorAction SilentlyContinue) {

        $udp = @(Get-NetUDPEndpoint |
            Select-Object -First 500 |
            ForEach-Object {

                [PSCustomObject]@{
                    EnderecoLocal = $_.LocalAddress
                    Porta = $_.LocalPort
                    PID = $_.OwningProcess
                    Processo = Get-ProcessNameById $_.OwningProcess
                }
            })
    }

    Write-Host '  Dispositivos ja conhecidos na rede...'

    $neighbors = @()

    if (Get-Command Get-NetNeighbor -ErrorAction SilentlyContinue) {

        $neighbors = @(Get-NetNeighbor |
            Where-Object {
                $_.LinkLayerAddress -and
                $_.LinkLayerAddress -ne '00-00-00-00-00-00' -and
                $_.IPAddress -notmatch '^(224\.|239\.|ff)'
            } |
            ForEach-Object {

                [PSCustomObject]@{
                    Interface = $_.InterfaceAlias
                    IP = $_.IPAddress
                    MAC = $_.LinkLayerAddress
                    Estado = [string]$_.State
                }
            })
    }

    Write-Host '  Impressoras...'

    $printers = @(Get-CimInstance Win32_Printer |
        ForEach-Object {

            [PSCustomObject]@{
                Nome = $_.Name
                Driver = $_.DriverName
                Porta = $_.PortName
                Compartilhada = $_.Shared
                Padrao = $_.Default
                Rede = $_.Network
            }
        })

    [PSCustomObject]@{

        Adaptadores = $adapters
        Compartilhamentos = $shares
        UnidadesMapeadas = $mappedDrives
        PortasTCPEmEscuta = $tcp
        EndpointsUDP = $udp
        DispositivosConhecidosNaRede = $neighbors
        Impressoras = $printers

        Observacoes = @(
            'Nao foi executada varredura ativa na rede.',
            'Dispositivos conhecidos sao obtidos do cache ARP/NDP do Windows.',
            'A lista nao representa necessariamente todos os dispositivos da rede.',
            'Endpoints UDP nao possuem estado LISTEN equivalente ao TCP.'
        )
    }
}

# ------------------------------------------------------------
# GERACAO DO RELATORIO HTML
# ------------------------------------------------------------

function ConvertTo-HtmlTable {
    param(
        [object[]]$Items,
        [string]$EmptyMessage = 'Nenhum registro encontrado.'
    )

    if (-not $Items -or $Items.Count -eq 0) {
        return "<p class='empty'>$EmptyMessage</p>"
    }

    $first = $Items | Select-Object -First 1
    $properties = @($first.PSObject.Properties.Name)

    $html = '<div class="table-wrap"><table><thead><tr>'

    foreach ($property in $properties) {
        $html += '<th>' + (Get-HtmlEncoded $property) + '</th>'
    }

    $html += '</tr></thead><tbody>'

    foreach ($item in $Items) {

        $html += '<tr>'

        foreach ($property in $properties) {

            $value = $item.$property

            if ($null -eq $value) {
                $display = '-'
            }
            elseif ($value -is [array]) {
                $display = ($value -join ', ')
            }
            elseif ($value -is [System.Collections.IDictionary]) {
                $display = ($value | ConvertTo-Json -Compress -Depth 5)
            }
            else {
                $display = [string]$value
            }

            if ([string]::IsNullOrWhiteSpace($display)) {
                $display = '-'
            }

            $html += '<td>' + (Get-HtmlEncoded $display) + '</td>'
        }

        $html += '</tr>'
    }

    $html += '</tbody></table></div>'

    return $html
}

function New-InventoryHtml {
    param(
        $Inventory,
        [string]$HtmlPath
    )

    $computer = $Inventory.Identificacao
    $hardware = $Inventory.Hardware
    $software = $Inventory.Software
    $network = $Inventory.Rede

    $ramTotal = 0

    foreach ($module in @($hardware.MemoriaRAM)) {
        if ($module.CapacidadeGB) {
            $ramTotal += [double]$module.CapacidadeGB
        }
    }

    $diskTotal = @($hardware.DiscosFisicos).Count
    $programTotal = @($software.ProgramasInstalados).Count
    $printerTotal = @($network.Impressoras).Count
    $tcpTotal = @($network.PortasTCPEmEscuta).Count

    $volumeCards = ''

    foreach ($volume in @($hardware.Volumes)) {

        if (-not $volume.CapacidadeGB -or $volume.CapacidadeGB -le 0) {
            continue
        }

        $used = [double]$volume.OcupadoPercentual
        $free = [double]$volume.LivrePercentual

        $volumeCards += @"
        <div class="volume-card">
            <div class="volume-title">
                <strong>$(Get-HtmlEncoded $volume.Unidade)</strong>
                <span>$(Get-HtmlEncoded $volume.Nome)</span>
            </div>
            <div class="bar">
                <div class="bar-used" style="width:$used%"></div>
            </div>
            <div class="volume-details">
                <span>Ocupado: $used%</span>
                <span>Livre: $free%</span>
            </div>
            <div class="volume-details">
                <span>Capacidade: $($volume.CapacidadeGB) GB</span>
                <span>Disponivel: $($volume.LivreGB) GB</span>
            </div>
        </div>
"@
    }

    if (-not $volumeCards) {
        $volumeCards = '<p class="empty">Nenhum volume local identificado.</p>'
    }

    $htmlCpu = ConvertTo-HtmlTable @($hardware.Processadores)
    $htmlRam = ConvertTo-HtmlTable @($hardware.MemoriaRAM)
    $htmlGpu = ConvertTo-HtmlTable @($hardware.PlacasVideo)
    $htmlDisks = ConvertTo-HtmlTable @($hardware.DiscosFisicos)
    $htmlHealth = ConvertTo-HtmlTable @($hardware.SaudeDiscos)
    $htmlMonitors = ConvertTo-HtmlTable @($hardware.Monitores)
    $htmlUsb = ConvertTo-HtmlTable @($hardware.DispositivosUSB)
    $htmlBattery = ConvertTo-HtmlTable @($hardware.Baterias)

    $htmlPrograms = ConvertTo-HtmlTable @($software.ProgramasInstalados)
    $htmlLicense = ConvertTo-HtmlTable @($software.LicenciamentoWindows)
    $htmlAntivirus = ConvertTo-HtmlTable @($software.Antivirus)
    $htmlFirewall = ConvertTo-HtmlTable @($software.Firewall)
    $htmlUpdates = ConvertTo-HtmlTable @($software.AtualizacoesInstaladas)
    $htmlDrivers = ConvertTo-HtmlTable @($software.Drivers)

    $htmlAdapters = ConvertTo-HtmlTable @($network.Adaptadores)
    $htmlShares = ConvertTo-HtmlTable @($network.Compartilhamentos)
    $htmlMapped = ConvertTo-HtmlTable @($network.UnidadesMapeadas)
    $htmlTcp = ConvertTo-HtmlTable @($network.PortasTCPEmEscuta)
    $htmlUdp = ConvertTo-HtmlTable @($network.EndpointsUDP)
    $htmlNeighbors = ConvertTo-HtmlTable @($network.DispositivosConhecidosNaRede)
    $htmlPrinters = ConvertTo-HtmlTable @($network.Impressoras)

    $generated = Get-Date -Format 'dd/MM/yyyy HH:mm:ss'

    $html = @"
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">

<title>Seattle Inventory - $($computer.NomeComputador)</title>

<style>

:root {
    --primary: #102a43;
    --secondary: #176b87;
    --accent: #f39c35;
    --background: #f2f5f8;
    --card: #ffffff;
    --text: #243746;
    --muted: #6b7c8c;
    --border: #dce4eb;
}

* {
    box-sizing: border-box;
}

body {
    margin: 0;
    background: var(--background);
    color: var(--text);
    font-family: "Segoe UI", Arial, sans-serif;
}

header {
    background: linear-gradient(120deg, #102a43, #176b87);
    color: white;
    padding: 30px 5%;
}

header h1 {
    margin: 0;
    font-size: 29px;
}

header p {
    margin: 8px 0 0;
    color: #d8e7ef;
}

.container {
    max-width: 1500px;
    margin: 25px auto;
    padding: 0 20px;
}

.toolbar {
    display: flex;
    justify-content: space-between;
    align-items: center;
    gap: 10px;
    flex-wrap: wrap;
    margin-bottom: 20px;
}

button {
    border: 0;
    border-radius: 7px;
    background: var(--secondary);
    color: white;
    padding: 11px 17px;
    cursor: pointer;
    font-weight: 600;
}

button:hover {
    background: var(--primary);
}

.cards {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(190px, 1fr));
    gap: 15px;
    margin-bottom: 25px;
}

.card {
    background: var(--card);
    border: 1px solid var(--border);
    border-radius: 11px;
    padding: 20px;
    box-shadow: 0 2px 7px rgba(0,0,0,.04);
}

.card-label {
    color: var(--muted);
    font-size: 13px;
}

.card-value {
    font-size: 27px;
    font-weight: 700;
    color: var(--primary);
    margin-top: 8px;
}

.card-detail {
    color: var(--muted);
    font-size: 12px;
    margin-top: 5px;
}

.panel {
    background: var(--card);
    border: 1px solid var(--border);
    border-radius: 11px;
    padding: 22px;
    margin-bottom: 20px;
    box-shadow: 0 2px 7px rgba(0,0,0,.035);
}

.panel h2 {
    margin: 0 0 17px;
    color: var(--primary);
    font-size: 20px;
    border-bottom: 2px solid var(--accent);
    padding-bottom: 10px;
}

.panel h3 {
    color: var(--secondary);
    margin-top: 24px;
}

.info-grid {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
    gap: 13px;
}

.info-item {
    padding: 11px;
    background: #f6f8fa;
    border-radius: 7px;
    overflow-wrap: anywhere;
}

.info-item span {
    display: block;
    color: var(--muted);
    font-size: 12px;
    margin-bottom: 5px;
}

.info-item strong {
    font-size: 14px;
}

.volume-card {
    padding: 15px;
    border: 1px solid var(--border);
    border-radius: 8px;
    margin-bottom: 13px;
}

.volume-title {
    display: flex;
    justify-content: space-between;
    gap: 10px;
    margin-bottom: 12px;
}

.volume-title span {
    color: var(--muted);
}

.bar {
    width: 100%;
    height: 13px;
    background: #e5ebf0;
    border-radius: 20px;
    overflow: hidden;
}

.bar-used {
    height: 100%;
    background: linear-gradient(90deg, #176b87, #f39c35);
    border-radius: 20px;
}

.volume-details {
    display: flex;
    justify-content: space-between;
    flex-wrap: wrap;
    gap: 8px;
    margin-top: 8px;
    color: var(--muted);
    font-size: 12px;
}

.table-wrap {
    width: 100%;
    overflow-x: auto;
}

table {
    border-collapse: collapse;
    width: 100%;
    font-size: 13px;
    margin-top: 8px;
}

th {
    background: #eaf0f5;
    color: var(--primary);
    text-align: left;
    white-space: nowrap;
}

th, td {
    padding: 10px;
    border: 1px solid var(--border);
    vertical-align: top;
}

td {
    overflow-wrap: anywhere;
}

tr:nth-child(even) {
    background: #fafbfd;
}

.empty {
    color: var(--muted);
    font-style: italic;
    padding: 12px 0;
}

.note {
    background: #fff8e9;
    border-left: 4px solid var(--accent);
    padding: 12px 15px;
    margin: 9px 0;
    border-radius: 4px;
    font-size: 13px;
}

footer {
    text-align: center;
    color: var(--muted);
    padding: 25px;
    font-size: 12px;
}

nav {
    display: flex;
    flex-wrap: wrap;
    gap: 8px;
    margin-bottom: 20px;
}

nav a {
    color: var(--secondary);
    background: white;
    border: 1px solid var(--border);
    padding: 8px 12px;
    border-radius: 6px;
    text-decoration: none;
    font-size: 13px;
}

@media print {
    body {
        background: white;
    }

    header {
        background: #102a43 !important;
        print-color-adjust: exact;
        -webkit-print-color-adjust: exact;
    }

    .toolbar, nav {
        display: none;
    }

    .panel, .card {
        break-inside: avoid;
        box-shadow: none;
    }

    .table-wrap {
        overflow: visible;
    }

    table {
        font-size: 9px;
    }

    th, td {
        padding: 5px;
    }
}

</style>
</head>

<body>

<header>
    <h1>SEATTLE INVENTORY</h1>
    <p>Relatorio de inventario computacional | LR Tecnologia</p>
    <p>Equipamento: $(Get-HtmlEncoded $computer.NomeComputador)</p>
</header>

<div class="container">

    <div class="toolbar">
        <div>
            <strong>Relatorio gerado em:</strong> $generated
        </div>
        <button onclick="window.print()">Imprimir / Salvar em PDF</button>
    </div>

    <nav>
        <a href="#identificacao">Identificacao</a>
        <a href="#hardware">Hardware</a>
        <a href="#armazenamento">Armazenamento</a>
        <a href="#software">Software</a>
        <a href="#rede">Rede</a>
        <a href="#seguranca">Seguranca</a>
    </nav>

    <div class="cards">

        <div class="card">
            <div class="card-label">Memoria RAM instalada</div>
            <div class="card-value">$([math]::Round($ramTotal, 2)) GB</div>
            <div class="card-detail">$(@($hardware.MemoriaRAM).Count) modulo(s)</div>
        </div>

        <div class="card">
            <div class="card-label">Discos fisicos</div>
            <div class="card-value">$diskTotal</div>
            <div class="card-detail">Unidades identificadas</div>
        </div>

        <div class="card">
            <div class="card-label">Programas instalados</div>
            <div class="card-value">$programTotal</div>
            <div class="card-detail">Registros encontrados</div>
        </div>

        <div class="card">
            <div class="card-label">Impressoras</div>
            <div class="card-value">$printerTotal</div>
            <div class="card-detail">Dispositivos identificados</div>
        </div>

        <div class="card">
            <div class="card-label">Portas TCP em escuta</div>
            <div class="card-value">$tcpTotal</div>
            <div class="card-detail">Endpoints encontrados</div>
        </div>

    </div>

    <section class="panel" id="identificacao">
        <h2>Identificacao do computador</h2>

        <div class="info-grid">

            <div class="info-item">
                <span>Nome do computador</span>
                <strong>$(Get-HtmlEncoded $computer.NomeComputador)</strong>
            </div>

            <div class="info-item">
                <span>Fabricante</span>
                <strong>$(Get-HtmlEncoded $computer.Fabricante)</strong>
            </div>

            <div class="info-item">
                <span>Modelo</span>
                <strong>$(Get-HtmlEncoded $computer.Modelo)</strong>
            </div>

            <div class="info-item">
                <span>Usuario</span>
                <strong>$(Get-HtmlEncoded $computer.UsuarioLogado)</strong>
            </div>

            <div class="info-item">
                <span>Windows</span>
                <strong>$(Get-HtmlEncoded $computer.Windows)</strong>
            </div>

            <div class="info-item">
                <span>Versao / Build</span>
                <strong>$(Get-HtmlEncoded $computer.DisplayVersion) / $(Get-HtmlEncoded $computer.BuildWindows)</strong>
            </div>

            <div class="info-item">
                <span>Arquitetura</span>
                <strong>$(Get-HtmlEncoded $computer.Arquitetura)</strong>
            </div>

            <div class="info-item">
                <span>Dominio ou grupo</span>
                <strong>$(Get-HtmlEncoded $computer.DominioOuGrupo)</strong>
            </div>

            <div class="info-item">
                <span>Placa-mae</span>
                <strong>$(Get-HtmlEncoded $computer.PlacaMaeFabricante) $(Get-HtmlEncoded $computer.PlacaMaeModelo)</strong>
            </div>

            <div class="info-item">
                <span>BIOS</span>
                <strong>$(Get-HtmlEncoded $computer.VersaoBIOS)</strong>
            </div>

        </div>
    </section>

    <section class="panel" id="hardware">
        <h2>Hardware</h2>

        <h3>Processador</h3>
        $htmlCpu

        <h3>Memoria RAM</h3>
        $htmlRam

        <h3>Placas de video</h3>
        $htmlGpu

        <h3>Monitores</h3>
        $htmlMonitors

        <h3>Dispositivos USB</h3>
        $htmlUsb

        <h3>Bateria</h3>
        $htmlBattery

    </section>

    <section class="panel" id="armazenamento">
        <h2>Armazenamento</h2>

        <h3>Uso dos volumes</h3>
        $volumeCards

        <h3>Discos fisicos</h3>
        $htmlDisks

        <h3>Saude dos discos</h3>
        $htmlHealth

    </section>

    <section class="panel" id="software">
        <h2>Software instalado</h2>

        <h3>Programas</h3>
        $htmlPrograms

        <h3>Drivers</h3>
        $htmlDrivers

        <h3>Atualizacoes instaladas</h3>
        $htmlUpdates

    </section>

    <section class="panel" id="seguranca">
        <h2>Seguranca e licenciamento</h2>

        <h3>Licenciamento Windows</h3>
        $htmlLicense

        <h3>Antivirus identificados</h3>
        $htmlAntivirus

        <h3>Firewall</h3>
        $htmlFirewall

        <div class="note">
            A identificacao de um antivirus nao significa necessariamente
            que ele esteja ativo ou atualizado. O estado bruto foi preservado
            para analise posterior.
        </div>

    </section>

    <section class="panel" id="rede">
        <h2>Rede</h2>

        <h3>Adaptadores e configuracoes IP</h3>
        $htmlAdapters

        <h3>Impressoras</h3>
        $htmlPrinters

        <h3>Unidades de rede</h3>
        $htmlMapped

        <h3>Compartilhamentos</h3>
        $htmlShares

        <h3>Portas TCP em escuta</h3>
        $htmlTcp

        <h3>Endpoints UDP</h3>
        $htmlUdp

        <h3>Dispositivos conhecidos na rede</h3>
        $htmlNeighbors

    </section>

    <section class="panel">
        <h2>Observacoes tecnicas</h2>

        <div class="note">
            Este inventario foi realizado em modo somente leitura.
            Nenhuma configuracao do computador foi alterada.
        </div>

        <div class="note">
            Nenhum dado foi enviado pela internet.
            Os arquivos JSON e HTML permanecem no computador.
        </div>

        <div class="note">
            Algumas informacoes dependem do hardware, dos drivers,
            das permissoes do Windows e da disponibilidade das interfaces WMI.
        </div>

        <div class="note">
            A lista de dispositivos de rede utiliza informacoes ja conhecidas
            pelo Windows. Nao foi executada varredura ativa.
        </div>

    </section>

</div>

<footer>
    SEATTLE INVENTORY V1.0.1 | LR TECNOLOGIA<br>
    Relatorio local de inventario computacional
</footer>

</body>
</html>
"@

    $encoding = New-Object System.Text.UTF8Encoding($false)

    [System.IO.File]::WriteAllText(
        $HtmlPath,
        $html,
        $encoding
    )
}

# ------------------------------------------------------------
# EXECUCAO PRINCIPAL
# ------------------------------------------------------------

try {

    Write-Host ''
    Write-Host '============================================' -ForegroundColor Cyan
    Write-Host '       SEATTLE INVENTORY V1.0.1' -ForegroundColor Cyan
    Write-Host '             LR TECNOLOGIA' -ForegroundColor Cyan
    Write-Host '============================================' -ForegroundColor Cyan
    Write-Host ''

    Write-Host 'Iniciando inventario...' -ForegroundColor Yellow
    Write-Host 'Modo somente leitura. Nenhum dado sera enviado.'
    Write-Host ''

    if (-not (Test-Path -LiteralPath $OutputDirectory)) {

        New-Item -ItemType Directory `
            -Path $OutputDirectory `
            -Force | Out-Null
    }

    $start = Get-Date

    Write-Host '[1/4] Identificacao do computador' -ForegroundColor Green
    $computer = Get-ComputerInventory

    Write-Host ''
    Write-Host '[2/4] Inventario de hardware' -ForegroundColor Green
    $hardware = Get-HardwareInventory

    Write-Host ''
    Write-Host '[3/4] Inventario de software' -ForegroundColor Green
    $software = Get-SoftwareInventory

    Write-Host ''
    Write-Host '[4/4] Inventario de rede' -ForegroundColor Green
    $network = Get-NetworkInventory

    $inventory = [PSCustomObject]@{

        Produto = 'Seattle Inventory'
        Versao = '1.0.1'

        DataColeta = (Get-Date).ToString('o')
        InicioColeta = $start.ToString('o')
        FimColeta = (Get-Date).ToString('o')

        Modo = 'Somente leitura'
        EnvioRemoto = $false

        Identificacao = $computer
        Hardware = $hardware
        Software = $software
        Rede = $network

        Limitacoes = @(
            'A disponibilidade das informacoes depende do hardware e dos drivers.',
            'Sensores de temperatura de CPU e GPU podem nao estar disponiveis.',
            'A leitura SMART depende do disco e do controlador.',
            'A execucao como Administrador pode ampliar a quantidade de dados coletados.',
            'A identificacao de unidades virtuais e aproximada.',
            'A saude e o desgaste da bateria dependem do suporte WMI do equipamento.'
        )
    }

    $baseName = 'SeattleInventory_{0}_{1}' -f `
        $env:COMPUTERNAME, `
        (Get-Date -Format 'yyyyMMdd_HHmmss')

    $jsonPath = Join-Path $OutputDirectory ($baseName + '.json')
    $htmlPath = Join-Path $OutputDirectory ($baseName + '.html')

    Write-Host ''
    Write-Host 'Gerando arquivo JSON...' -ForegroundColor Yellow

    $json = $inventory | ConvertTo-Json -Depth 20

    $encoding = New-Object System.Text.UTF8Encoding($false)

    [System.IO.File]::WriteAllText(
        $jsonPath,
        $json,
        $encoding
    )

    Write-Host 'Gerando relatorio HTML...' -ForegroundColor Yellow

    New-InventoryHtml -Inventory $inventory -HtmlPath $htmlPath

    Write-Host ''
    Write-Host '============================================' -ForegroundColor Green
    Write-Host '          INVENTARIO CONCLUIDO' -ForegroundColor Green
    Write-Host '============================================' -ForegroundColor Green

    Write-Host ''
    Write-Host "Computador: $env:COMPUTERNAME"
    Write-Host "Processadores: $(@($hardware.Processadores).Count)"
    Write-Host "Modulos RAM: $(@($hardware.MemoriaRAM).Count)"
    Write-Host "Discos fisicos: $(@($hardware.DiscosFisicos).Count)"
    Write-Host "Volumes: $(@($hardware.Volumes).Count)"
    Write-Host "Programas: $(@($software.ProgramasInstalados).Count)"
    Write-Host "Adaptadores de rede: $(@($network.Adaptadores).Count)"
    Write-Host "Impressoras: $(@($network.Impressoras).Count)"
    Write-Host "Portas TCP: $(@($network.PortasTCPEmEscuta).Count)"

    Write-Host ''
    Write-Host 'ARQUIVOS GERADOS:' -ForegroundColor Cyan

    Write-Host ''
    Write-Host 'JSON:' -ForegroundColor Yellow
    Write-Host $jsonPath -ForegroundColor White

    Write-Host ''
    Write-Host 'HTML:' -ForegroundColor Yellow
    Write-Host $htmlPath -ForegroundColor White

    Write-Host ''
    Write-Host 'O relatorio HTML sera aberto no navegador.'

    try {
        Start-Process $htmlPath
    }
    catch {
        Write-Host 'Nao foi possivel abrir o navegador automaticamente.'
    }

    Write-Host ''
    Write-Host 'Nenhuma informacao foi transmitida pela internet.'

}
catch {

    Write-Host ''
    Write-Host 'ERRO DURANTE A COLETA' -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    Write-Host ''
    Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed

    exit 1
}

Write-Host ''
Read-Host 'Pressione ENTER para fechar'
