# ============================================================
# SEATTLE INVENTORY V1.0
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
                Fabricante = $_.Manufacturer
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

    Write-Host '  Unidades e particoes...'

    $volumes = @(Get-CimInstance Win32_LogicalDisk -Filter 'DriveType=3' |
        ForEach-Object {

            [PSCustomObject]@{
                Unidade = $_.DeviceID
                Nome = $_.VolumeName
                SistemaArquivos = $_.FileSystem
                CapacidadeGB = ConvertTo-GB $_.Size
                LivreGB = ConvertTo-GB $_.FreeSpace

                LivrePercentual = if ($_.Size -gt 0) {
                    [math]::Round(($_.FreeSpace / $_.Size) * 100, 1)
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

            [PSCustomObject]@{
                Fabricante = -join (
                    $_.ManufacturerName |
                    Where-Object { $_ -ne 0 } |
                    ForEach-Object { [char]$_ }
                )

                Modelo = $name.Trim()
                NumeroSerie = $serial.Trim()
                Ativo = $_.Active
            }
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
            'A ativacao do Office nao e verificada nesta versao.'
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
                }
            })
    }

    Write-Host '  Dispositivos ja conhecidos na rede...'

    $neighbors = @()

    if (Get-Command Get-NetNeighbor -ErrorAction SilentlyContinue) {

        $neighbors = @(Get-NetNeighbor |
            Where-Object {
                $_.LinkLayerAddress -and
                $_.LinkLayerAddress -ne '00-00-00-00-00-00'
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
# EXECUCAO PRINCIPAL
# ------------------------------------------------------------

try {

    Write-Host ''
    Write-Host '============================================' -ForegroundColor Cyan
    Write-Host '       SEATTLE INVENTORY V1.0' -ForegroundColor Cyan
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
        Versao = '1.0'

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
            'A execucao como Administrador pode ampliar a quantidade de dados coletados.'
        )
    }

    $fileName = 'SeattleInventory_{0}_{1}.json' -f `
        $env:COMPUTERNAME, `
        (Get-Date -Format 'yyyyMMdd_HHmmss')

    $outputFile = Join-Path $OutputDirectory $fileName

    $json = $inventory | ConvertTo-Json -Depth 15

    $encoding = New-Object System.Text.UTF8Encoding($false)

    [System.IO.File]::WriteAllText(
        $outputFile,
        $json,
        $encoding
    )

    Write-Host ''
    Write-Host '============================================' -ForegroundColor Green
    Write-Host '          INVENTARIO CONCLUIDO' -ForegroundColor Green
    Write-Host '============================================' -ForegroundColor Green

    Write-Host ''
    Write-Host "Computador: $env:COMPUTERNAME"
    Write-Host "Processadores: $(@($hardware.Processadores).Count)"
    Write-Host "Modulos RAM: $(@($hardware.MemoriaRAM).Count)"
    Write-Host "Discos: $(@($hardware.DiscosFisicos).Count)"
    Write-Host "Programas: $(@($software.ProgramasInstalados).Count)"
    Write-Host "Adaptadores de rede: $(@($network.Adaptadores).Count)"
    Write-Host "Impressoras: $(@($network.Impressoras).Count)"

    Write-Host ''
    Write-Host 'Arquivo gerado:' -ForegroundColor Cyan
    Write-Host $outputFile -ForegroundColor White

    Write-Host ''
    Write-Host 'O arquivo permanece neste computador.'
    Write-Host 'Nenhuma informacao foi transmitida pela internet.'

}
catch {

    Write-Host ''
    Write-Host 'ERRO DURANTE A COLETA' -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    exit 1
}

Write-Host ''
Read-Host 'Pressione ENTER para fechar'
