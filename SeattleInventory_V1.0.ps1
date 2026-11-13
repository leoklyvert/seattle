# ============================================================
# SEATTLE INVENTORY V1.0.2
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
# - Nao transmite o inventario pela internet
# - Nao coleta senhas ou chaves de produto
#
# SAIDAS:
# - Arquivo JSON completo
# - Relatorio HTML visual e interativo
#
# V1.0.2:
# - Identificacao aprimorada do equipamento
# - Numero de serie e Dell Service Tag
# - Inventario do Microsoft Office
# - Geolocalizacao por servicos do Windows
# - Fallback aproximado por IP
# - Armazenamento local em pasta reservada
# ============================================================

[CmdletBinding()]
param(
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

# ------------------------------------------------------------
# DIRETORIO PADRAO
# ------------------------------------------------------------

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $env:ProgramData `
        "LR Tecnologia\Seattle\Inventarios\$env:COMPUTERNAME"
}

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

function Get-ValidSerialNumber {
    param($Value)

    $serial = ConvertTo-SafeText $Value

    if ([string]::IsNullOrWhiteSpace($serial)) {
        return $null
    }

    $invalidValues = @(
        'TO BE FILLED BY O.E.M.',
        'DEFAULT STRING',
        'SYSTEM SERIAL NUMBER',
        'NONE',
        'UNKNOWN',
        'NOT APPLICABLE',
        'N/A',
        '123456789',
        '0'
    )

    if ($invalidValues -contains $serial.ToUpper()) {
        return $null
    }

    return $serial
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
# MICROSOFT OFFICE
# ------------------------------------------------------------

# ------------------------------------------------------------
# MICROSOFT OFFICE - V1.0.3
# ------------------------------------------------------------

function Get-OfficeInventory {

    $results = @()

    $c2rPaths = @(
        'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration',
        'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration'
    )

    $c2r = $null

    foreach ($path in $c2rPaths) {

        $candidate = Get-ItemProperty -Path $path `
            -ErrorAction SilentlyContinue

        if ($candidate -and $candidate.VersionToReport) {
            $c2r = $candidate
            break
        }
    }

    if ($c2r) {

        $releaseIds = @(
            ([string]$c2r.ProductReleaseIds -split ',') |
            ForEach-Object { $_.Trim() } |
            Where-Object { $_ }
        )

        foreach ($releaseId in $releaseIds) {

            $productName = switch -Regex ($releaseId) {

                '^ProPlus2024Volume$' {
                    'Microsoft Office LTSC Professional Plus 2024'
                    break
                }

                '^Standard2024Volume$' {
                    'Microsoft Office LTSC Standard 2024'
                    break
                }

                '^ProPlus2021Volume$' {
                    'Microsoft Office LTSC Professional Plus 2021'
                    break
                }

                '^Standard2021Volume$' {
                    'Microsoft Office LTSC Standard 2021'
                    break
                }

                '^ProPlus2019Volume$' {
                    'Microsoft Office Professional Plus 2019'
                    break
                }

                '^Standard2019Volume$' {
                    'Microsoft Office Standard 2019'
                    break
                }

                '^O365ProPlusRetail$' {
                    'Microsoft 365 Apps for enterprise'
                    break
                }

                '^O365BusinessRetail$' {
                    'Microsoft 365 Apps for business'
                    break
                }

                '^HomeBusiness2024Retail$' {
                    'Microsoft Office Home and Business 2024'
                    break
                }

                '^HomeStudent2024Retail$' {
                    'Microsoft Office Home and Student 2024'
                    break
                }

                default {
                    "Microsoft Office ($releaseId)"
                }
            }

            $architecture = switch ([string]$c2r.Platform) {
                'x64' { '64 bits' }
                'x86' { '32 bits' }
                default { 'Nao identificado' }
            }

            $language = ConvertTo-SafeText $c2r.ClientCulture

            if ($language -eq 'pt-br') {
                $language = 'Portugues (Brasil)'
            }
            elseif ($language -eq 'en-us') {
                $language = 'Ingles (Estados Unidos)'
            }
            elseif (-not $language) {
                $language = 'Nao identificado'
            }

            $channel = ConvertTo-SafeText $c2r.UpdateChannel

            if (-not $channel) {
                $channel = 'Nao identificado'
            }

            $results += [PSCustomObject]@{

                Produto = $productName

                IdentificadorProduto = $releaseId

                Versao = if ($c2r.VersionToReport) {
                    $c2r.VersionToReport
                }
                else {
                    'Nao identificada'
                }

                Arquitetura = $architecture

                Idioma = $language

                CanalAtualizacao = $channel

                TecnologiaInstalacao = 'Click-to-Run'

                LocalInstalacao = $c2r.InstallationPath
            }
        }
    }

    # --------------------------------------------------------
    # FALLBACK: REGISTROS DE DESINSTALACAO
    # --------------------------------------------------------

    if ($results.Count -eq 0) {

        $paths = @(
            'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
        )

        foreach ($path in $paths) {

            $entries = Get-ItemProperty -Path $path `
                -ErrorAction SilentlyContinue

            foreach ($entry in $entries) {

                $name = ConvertTo-SafeText $entry.DisplayName

                if (
                    $name -match 'Microsoft 365' -or
                    $name -match 'Microsoft Office' -or
                    $name -match 'Microsoft Visio' -or
                    $name -match 'Microsoft Project'
                ) {

                    $architecture = 'Nao identificada'

                    if ($path -match 'WOW6432Node') {
                        $architecture = '32 bits'
                    }
                    elseif ($entry.InstallLocation -match 'Program Files \(x86\)') {
                        $architecture = '32 bits'
                    }
                    elseif ($entry.InstallLocation -match 'Program Files') {
                        $architecture = '64 bits'
                    }

                    $results += [PSCustomObject]@{

                        Produto = $name

                        IdentificadorProduto = 'Nao identificado'

                        Versao = if ($entry.DisplayVersion) {
                            $entry.DisplayVersion
                        }
                        else {
                            'Nao identificada'
                        }

                        Arquitetura = $architecture

                        Idioma = 'Nao identificado'

                        CanalAtualizacao = 'Nao identificado'

                        TecnologiaInstalacao = 'Registro de desinstalacao'

                        LocalInstalacao = $entry.InstallLocation
                    }
                }
            }
        }
    }

    # --------------------------------------------------------
    # RESULTADO
    # --------------------------------------------------------

    if ($results.Count -eq 0) {

        $results += [PSCustomObject]@{

            Produto = 'Microsoft Office nao identificado'

            IdentificadorProduto = 'Nao identificado'

            Versao = 'Nao identificada'

            Arquitetura = 'Nao identificada'

            Idioma = 'Nao identificado'

            CanalAtualizacao = 'Nao identificado'

            TecnologiaInstalacao = 'Nao identificada'

            LocalInstalacao = $null
        }
    }

    return @($results | Sort-Object Produto, Versao -Unique)
}

    return @($results | Sort-Object Produto, Versao -Unique)
}

# ------------------------------------------------------------
# GEOLOCALIZACAO
# ------------------------------------------------------------

# ------------------------------------------------------------
# IDENTIFICACAO DO COMPUTADOR - V1.0.3
# ------------------------------------------------------------

function Get-ComputerInventory {

    $computer = Get-CimInstance Win32_ComputerSystem `
        -ErrorAction SilentlyContinue

    $bios = Get-CimInstance Win32_BIOS `
        -ErrorAction SilentlyContinue

    $board = Get-CimInstance Win32_BaseBoard `
        -ErrorAction SilentlyContinue

    $os = Get-CimInstance Win32_OperatingSystem `
        -ErrorAction SilentlyContinue

    $product = Get-CimInstance Win32_ComputerSystemProduct `
        -ErrorAction SilentlyContinue

    $registry = Get-ItemProperty `
        'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' `
        -ErrorAction SilentlyContinue

    # --------------------------------------------------------
    # NUMERO DE SERIE
    # --------------------------------------------------------

    $serial = Get-ValidSerialNumber $bios.SerialNumber

    $serialSource = 'BIOS'

    if (-not $serial) {

        $serial = Get-ValidSerialNumber $product.IdentifyingNumber

        $serialSource = 'SMBIOS'
    }

    if (-not $serial) {

        $serial = 'NAO IDENTIFICADO'

        $serialSource = 'Nenhuma fonte retornou numero valido'
    }

    # --------------------------------------------------------
    # DELL SERVICE TAG
    # --------------------------------------------------------

    $manufacturer = ConvertTo-SafeText $computer.Manufacturer

    $serviceTag = 'NAO IDENTIFICADO'

    $expressServiceCode = 'NAO IDENTIFICADO'

    if ($manufacturer -match 'Dell') {

        $serviceTagValue = Get-ValidSerialNumber $bios.SerialNumber

        if (-not $serviceTagValue) {

            $serviceTagValue = Get-ValidSerialNumber $product.IdentifyingNumber
        }

        if ($serviceTagValue) {

            $serviceTag = $serviceTagValue
        }
    }

    # --------------------------------------------------------
    # RESULTADO
    # --------------------------------------------------------

    [PSCustomObject]@{

        NomeComputador = $env:COMPUTERNAME

        UsuarioLogado = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

        Fabricante = $computer.Manufacturer

        Modelo = $computer.Model

        DominioOuGrupo = $computer.Domain

        ParticipaDominio = $computer.PartOfDomain

        NumeroSerie = $serial

        OrigemNumeroSerie = $serialSource

        NumeroSerieBIOS = if ($bios.SerialNumber) {
            $bios.SerialNumber
        }
        else {
            'NAO IDENTIFICADO'
        }

        IdentificadorSMBIOS = if ($product.IdentifyingNumber) {
            $product.IdentifyingNumber
        }
        else {
            'NAO IDENTIFICADO'
        }

        DellServiceTag = $serviceTag

        DellExpressServiceCode = $expressServiceCode

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
# IDENTIFICACAO DO COMPUTADOR
# ------------------------------------------------------------

function Get-ComputerInventory {

    $computer = Get-CimInstance Win32_ComputerSystem
    $bios = Get-CimInstance Win32_BIOS
    $board = Get-CimInstance Win32_BaseBoard
    $os = Get-CimInstance Win32_OperatingSystem
    $product = Get-CimInstance Win32_ComputerSystemProduct `
        -ErrorAction SilentlyContinue

    $registry = Get-ItemProperty `
        'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion' `
        -ErrorAction SilentlyContinue

    $serial = Get-ValidSerialNumber $bios.SerialNumber

    if (-not $serial) {
        $serial = Get-ValidSerialNumber $product.IdentifyingNumber
    }

    $manufacturer = ConvertTo-SafeText $computer.Manufacturer

    $serviceTag = $null
    $expressServiceCode = 'Nao disponivel'

    if ($manufacturer -match 'Dell') {

        $serviceTag = Get-ValidSerialNumber $bios.SerialNumber

        if (-not $serviceTag) {
            $serviceTag = Get-ValidSerialNumber $product.IdentifyingNumber
        }

        # O Express Service Code nao sera estimado.
        # So sera preenchido futuramente se houver metodo validado.
    }

    [PSCustomObject]@{

        NomeComputador = $env:COMPUTERNAME

        UsuarioLogado = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name

        Fabricante = $computer.Manufacturer
        Modelo = $computer.Model
        DominioOuGrupo = $computer.Domain
        ParticipaDominio = $computer.PartOfDomain

        NumeroSerie = $serial
        NumeroSerieBIOS = $bios.SerialNumber
        IdentificadorSMBIOS = $product.IdentifyingNumber

        DellServiceTag = $serviceTag
        DellExpressServiceCode = $expressServiceCode

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
                }
                else {
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
                }
                else {
                    $null
                }

                OcupadoPercentual = if ($_.Size -gt 0) {
                    [math]::Round((($_.Size - $_.FreeSpace) / $_.Size) * 100, 1)
                }
                else {
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
                    }
                    else {
                        $null
                    }

                    HorasLigado = if ($reliability) {
                        $reliability.PowerOnHours
                    }
                    else {
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

    $batteryInfo = Get-CimInstance Win32_Battery `
        -ErrorAction SilentlyContinue

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
# ============================================================
# SOFTWARE E SEGURANCA
# ============================================================

function Get-SoftwareInventory {

    Write-Host '  Programas instalados...' -ForegroundColor Gray

    $programs = @(Get-InstalledSoftware)

    # --------------------------------------------------------
    # MICROSOFT OFFICE
    # --------------------------------------------------------

    Write-Host '  Microsoft Office...' -ForegroundColor Gray

    $office = @(Get-OfficeInventory)

    # --------------------------------------------------------
    # LICENCIAMENTO WINDOWS
    # --------------------------------------------------------

    Write-Host '  Licenciamento Windows...' -ForegroundColor Gray

    $license = @(
        Get-CimInstance SoftwareLicensingProduct -ErrorAction SilentlyContinue |
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
        }
    )

    # --------------------------------------------------------
    # ANTIVIRUS
    # --------------------------------------------------------

    Write-Host '  Antivirus...' -ForegroundColor Gray

    $antivirus = @(
        Get-CimInstance `
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
        }
    )

    # --------------------------------------------------------
    # FIREWALL
    # --------------------------------------------------------

    Write-Host '  Firewall...' -ForegroundColor Gray

    $firewall = @()

    if (Get-Command Get-NetFirewallProfile -ErrorAction SilentlyContinue) {

        try {

            $firewall = @(
                Get-NetFirewallProfile -ErrorAction Stop |
                ForEach-Object {

                    [PSCustomObject]@{
                        Perfil = $_.Name
                        Habilitado = $_.Enabled
                        AcaoEntrada = [string]$_.DefaultInboundAction
                        AcaoSaida = [string]$_.DefaultOutboundAction
                    }
                }
            )

        }
        catch {

            Write-Warning "Nao foi possivel consultar o Firewall: $($_.Exception.Message)"
        }
    }

    # --------------------------------------------------------
    # ATUALIZACOES INSTALADAS
    # --------------------------------------------------------

    Write-Host '  Atualizacoes instaladas...' -ForegroundColor Gray

    $updates = @(
        Get-HotFix -ErrorAction SilentlyContinue |
        ForEach-Object {

            [PSCustomObject]@{
                KB = $_.HotFixID
                Descricao = $_.Description
                InstaladoPor = $_.InstalledBy
                DataInstalacao = $_.InstalledOn
            }
        }
    )

    # --------------------------------------------------------
    # DRIVERS
    # --------------------------------------------------------

    Write-Host '  Drivers...' -ForegroundColor Gray

    $drivers = @(
        Get-CimInstance Win32_PnPSignedDriver -ErrorAction SilentlyContinue |
        ForEach-Object {

            [PSCustomObject]@{
                Dispositivo = $_.DeviceName
                Fabricante = $_.Manufacturer
                Versao = $_.DriverVersion
                Data = $_.DriverDate
                Assinado = $_.IsSigned
                Provedor = $_.DriverProviderName
            }
        }
    )

    # --------------------------------------------------------
    # RESULTADO
    # --------------------------------------------------------

    [PSCustomObject]@{

        ProgramasInstalados = $programs

        MicrosoftOffice = $office

        LicenciamentoWindows = $license

        Antivirus = $antivirus

        Firewall = $firewall

        AtualizacoesInstaladas = $updates

        Drivers = $drivers

        Observacoes = @(

            'Programas portateis podem nao aparecer na lista.',

            'Get-HotFix nao representa necessariamente todas as atualizacoes do Windows Update.',

            'Nenhuma senha ou chave de produto e coletada.',

            'O inventario do Microsoft Office identifica produto, edicao, versao, arquitetura, idioma e canal de atualizacao quando disponiveis.',

            'A identificacao do Office pode utilizar registros Click-to-Run e registros de desinstalacao do Windows.',

            'A ativacao do Office nao e verificada nesta versao.',

            'O estado do antivirus e apresentado como dado bruto, sem presumir que esteja ativo.',

            'Informacoes de licenciamento do Windows nao incluem a chave completa do produto.'
        )
    }
}
# ============================================================
# REDE E CONECTIVIDADE
# ============================================================

function Get-NetworkInventory {

    Write-Host '  Adaptadores de rede...' -ForegroundColor Gray

    $adapters = @(
        Get-CimInstance Win32_NetworkAdapterConfiguration `
            -ErrorAction SilentlyContinue |
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
        }
    )

    # --------------------------------------------------------
    # COMPARTILHAMENTOS
    # --------------------------------------------------------

    Write-Host '  Compartilhamentos...' -ForegroundColor Gray

    $shares = @(
        Get-CimInstance Win32_Share -ErrorAction SilentlyContinue |
        ForEach-Object {

            [PSCustomObject]@{
                Nome = $_.Name
                Caminho = $_.Path
                Tipo = $_.Type
                Descricao = $_.Description
            }
        }
    )

    # --------------------------------------------------------
    # UNIDADES DE REDE MAPEADAS
    # --------------------------------------------------------

    Write-Host '  Unidades de rede...' -ForegroundColor Gray

    $mappedDrives = @(
        Get-CimInstance Win32_LogicalDisk `
            -Filter 'DriveType=4' `
            -ErrorAction SilentlyContinue |
        ForEach-Object {

            [PSCustomObject]@{
                Unidade = $_.DeviceID
                Caminho = $_.ProviderName
                Nome = $_.VolumeName
            }
        }
    )

    # --------------------------------------------------------
    # PORTAS TCP EM ESCUTA
    # --------------------------------------------------------

    Write-Host '  Portas TCP em escuta...' -ForegroundColor Gray

    $tcp = @()

    if (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue) {

        try {

            $tcp = @(
                Get-NetTCPConnection -State Listen `
                    -ErrorAction Stop |
                Select-Object -First 500 |
                ForEach-Object {

                    [PSCustomObject]@{
                        EnderecoLocal = $_.LocalAddress
                        Porta = $_.LocalPort
                        PID = $_.OwningProcess
                        Processo = Get-ProcessNameById $_.OwningProcess
                    }
                }
            )

        }
        catch {

            Write-Warning "Nao foi possivel consultar portas TCP: $($_.Exception.Message)"
        }
    }

    # --------------------------------------------------------
    # ENDPOINTS UDP
    # --------------------------------------------------------

    Write-Host '  Endpoints UDP...' -ForegroundColor Gray

    $udp = @()

    if (Get-Command Get-NetUDPEndpoint -ErrorAction SilentlyContinue) {

        try {

            $udp = @(
                Get-NetUDPEndpoint -ErrorAction Stop |
                Select-Object -First 500 |
                ForEach-Object {

                    [PSCustomObject]@{
                        EnderecoLocal = $_.LocalAddress
                        Porta = $_.LocalPort
                        PID = $_.OwningProcess
                        Processo = Get-ProcessNameById $_.OwningProcess
                    }
                }
            )

        }
        catch {

            Write-Warning "Nao foi possivel consultar endpoints UDP: $($_.Exception.Message)"
        }
    }

    # --------------------------------------------------------
    # DISPOSITIVOS CONHECIDOS NA REDE
    # --------------------------------------------------------

    Write-Host '  Dispositivos ja conhecidos na rede...' -ForegroundColor Gray

    $neighbors = @()

    if (Get-Command Get-NetNeighbor -ErrorAction SilentlyContinue) {

        try {

            $neighbors = @(
                Get-NetNeighbor -ErrorAction Stop |
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
                }
            )

        }
        catch {

            Write-Warning "Nao foi possivel consultar dispositivos conhecidos: $($_.Exception.Message)"
        }
    }

    # --------------------------------------------------------
    # IMPRESSORAS
    # --------------------------------------------------------

    Write-Host '  Impressoras...' -ForegroundColor Gray

    $printers = @(
        Get-CimInstance Win32_Printer -ErrorAction SilentlyContinue |
        ForEach-Object {

            [PSCustomObject]@{
                Nome = $_.Name
                Driver = $_.DriverName
                Porta = $_.PortName
                Compartilhada = $_.Shared
                Padrao = $_.Default
                Rede = $_.Network
            }
        }
    )

    # --------------------------------------------------------
    # RESULTADO
    # --------------------------------------------------------

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

            'Endpoints UDP nao possuem estado LISTEN equivalente ao TCP.',

            'A coleta de portas TCP e UDP e limitada a 500 registros por categoria.',

            'As informacoes coletadas representam o estado da rede no momento da execucao.'
        )
    }
}
# ============================================================
# EXECUCAO PRINCIPAL
# SEATTLE INVENTORY V1.0.2
# ============================================================

function Set-InventoryDirectorySecurity {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    # --------------------------------------------------------
    # CRIAR DIRETORIO
    # --------------------------------------------------------

    if (-not (Test-Path -LiteralPath $Path)) {

        New-Item -ItemType Directory `
            -Path $Path `
            -Force `
            -ErrorAction Stop | Out-Null
    }

    # --------------------------------------------------------
    # CONFIGURAR ACL
    # --------------------------------------------------------

    $acl = New-Object System.Security.AccessControl.DirectorySecurity

    # Desabilita heranca de permissoes.
    $acl.SetAccessRuleProtection($true, $false)

    $inheritance = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor `
                   [System.Security.AccessControl.InheritanceFlags]::ObjectInherit

    $propagation = [System.Security.AccessControl.PropagationFlags]::None

    $accessType = [System.Security.AccessControl.AccessControlType]::Allow

    # SYSTEM, Administradores e usuario atual.
    $allowedSids = @(
        'S-1-5-18',
        'S-1-5-32-544',
        [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    )

    foreach ($sidValue in ($allowedSids | Select-Object -Unique)) {

        $sid = New-Object System.Security.Principal.SecurityIdentifier($sidValue)

        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $sid,
            [System.Security.AccessControl.FileSystemRights]::FullControl,
            $inheritance,
            $propagation,
            $accessType
        )

        $acl.AddAccessRule($rule)
    }

    # Aplica as permissoes.
    Set-Acl -LiteralPath $Path `
        -AclObject $acl `
        -ErrorAction Stop

    # --------------------------------------------------------
    # MARCAR DIRETORIO COMO OCULTO
    # --------------------------------------------------------

    $directory = Get-Item -LiteralPath $Path -Force -ErrorAction Stop

    $directory.Attributes = $directory.Attributes -bor `
        [System.IO.FileAttributes]::Hidden

    # --------------------------------------------------------
    # VALIDACAO
    # --------------------------------------------------------

    $verification = Get-Acl -LiteralPath $Path -ErrorAction Stop

    if (-not $verification.AreAccessRulesProtected) {

        throw 'A heranca de permissoes nao foi desabilitada corretamente.'
    }

    return $true
}

# ============================================================
# EXECUCAO
# ============================================================

try {

    Clear-Host

    Write-Host ''
    Write-Host '================================================' -ForegroundColor Cyan
    Write-Host '           SEATTLE INVENTORY V1.0.2' -ForegroundColor Cyan
    Write-Host '                 LR TECNOLOGIA' -ForegroundColor Cyan
    Write-Host '================================================' -ForegroundColor Cyan
    Write-Host ''

    Write-Host 'Iniciando inventario computacional...' -ForegroundColor Yellow

    Write-Host 'Modo de operacao: SOMENTE LEITURA' -ForegroundColor Green

    Write-Host 'Armazenamento: LOCAL' -ForegroundColor Green

    Write-Host ''

    # --------------------------------------------------------
    # DIRETORIO DE DESTINO
    # --------------------------------------------------------

    if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {

        $OutputDirectory = Join-Path $env:ProgramData `
            "LR Tecnologia\Seattle\Inventarios\$env:COMPUTERNAME"
    }

    Write-Host '[1/7] Preparando armazenamento protegido...' -ForegroundColor Green

    Set-InventoryDirectorySecurity -Path $OutputDirectory | Out-Null

    Write-Host '      Diretorio protegido com sucesso.' -ForegroundColor Gray

    # --------------------------------------------------------
    # INICIO DA COLETA
    # --------------------------------------------------------

    $start = Get-Date

    # --------------------------------------------------------
    # IDENTIFICACAO
    # --------------------------------------------------------

    Write-Host ''
    Write-Host '[2/7] Identificacao do computador...' -ForegroundColor Green

    $computer = Get-ComputerInventory

    # --------------------------------------------------------
    # HARDWARE
    # --------------------------------------------------------

    Write-Host ''
    Write-Host '[3/7] Inventario de hardware...' -ForegroundColor Green

    $hardware = Get-HardwareInventory

    # --------------------------------------------------------
    # SOFTWARE
    # --------------------------------------------------------

    Write-Host ''
    Write-Host '[4/7] Inventario de software...' -ForegroundColor Green

    $software = Get-SoftwareInventory

    # --------------------------------------------------------
    # REDE
    # --------------------------------------------------------

    Write-Host ''
    Write-Host '[5/7] Inventario de rede...' -ForegroundColor Green

    $network = Get-NetworkInventory

    # ------------------------------------------------------------
# GEOLOCALIZACAO - V1.0.3
# ------------------------------------------------------------

function Get-ComputerLocation {

    $result = [PSCustomObject]@{

        Disponivel = $false

        Latitude = $null

        Longitude = $null

        PrecisaoMetros = $null

        DataHora = $null

        Metodo = 'NAO IDENTIFICADO'

        Provedor = 'NAO IDENTIFICADO'

        Cidade = 'NAO IDENTIFICADA'

        Regiao = 'NAO IDENTIFICADA'

        Pais = 'NAO IDENTIFICADO'

        Observacao = $null

        StatusServicoWindows = 'Nao verificado'

        ErroWindows = $null

        ErroIP = $null
    }

    # --------------------------------------------------------
    # VERIFICAR SERVICO DO WINDOWS
    # --------------------------------------------------------

    $service = Get-Service -Name lfsvc `
        -ErrorAction SilentlyContinue

    if ($service) {

        $result.StatusServicoWindows = [string]$service.Status

        if ($service.StartType -eq 'Disabled') {

            $result.StatusServicoWindows = 'Desativado'
        }
    }
    else {

        $result.StatusServicoWindows = 'Servico indisponivel'
    }

    # --------------------------------------------------------
    # PRIMEIRA TENTATIVA: WINDOWS
    # --------------------------------------------------------

    $watcher = $null

    try {

        Add-Type -AssemblyName System.Device -ErrorAction Stop

        $watcher = New-Object -TypeName System.Device.Location.GeoCoordinateWatcher

        $watcher.Start()

        $timeout = (Get-Date).AddSeconds(7)

        while (
            [string]$watcher.Status -ne 'Ready' -and
            (Get-Date) -lt $timeout
        ) {

            Start-Sleep -Milliseconds 300
        }

        if (
            [string]$watcher.Status -eq 'Ready' -and
            $watcher.Position.Location -and
            -not $watcher.Position.Location.IsUnknown
        ) {

            $position = $watcher.Position.Location

            if (
                $position.Latitude -ge -90 -and
                $position.Latitude -le 90 -and
                $position.Longitude -ge -180 -and
                $position.Longitude -le 180
            ) {

                $result.Disponivel = $true

                $result.Latitude = [math]::Round(
                    $position.Latitude,
                    6
                )

                $result.Longitude = [math]::Round(
                    $position.Longitude,
                    6
                )

                if ($position.HorizontalAccuracy -gt 0) {

                    $result.PrecisaoMetros = [math]::Round(
                        $position.HorizontalAccuracy,
                        1
                    )
                }

                $result.DataHora = (Get-Date).ToString('o')

                $result.Metodo = 'Servico de localizacao do Windows'

                $result.Provedor = 'Windows'

                $result.Observacao = 'Localizacao obtida pelo Windows.'

            }
        }

        if (-not $result.Disponivel) {

            $result.ErroWindows = 'O servico nao forneceu coordenadas validas.'
        }
    }
    catch {

        $result.ErroWindows = $_.Exception.Message
    }
    finally {

        if ($null -ne $watcher) {

            try {
                $watcher.Stop()
                $watcher.Dispose()
            }
            catch {}
        }
    }

    if ($result.Disponivel) {

        return $result
    }

    # --------------------------------------------------------
    # SEGUNDA TENTATIVA: IP
    # --------------------------------------------------------

    try {

        $response = Invoke-RestMethod `
            -Uri 'https://ipwho.is/' `
            -Method Get `
            -TimeoutSec 10 `
            -ErrorAction Stop

        if (
            $response.success -eq $true -and
            $null -ne $response.latitude -and
            $null -ne $response.longitude
        ) {

            $latitude = [double]$response.latitude

            $longitude = [double]$response.longitude

            if (
                $latitude -ge -90 -and
                $latitude -le 90 -and
                $longitude -ge -180 -and
                $longitude -le 180
            ) {

                $result.Disponivel = $true

                $result.Latitude = [math]::Round($latitude, 6)

                $result.Longitude = [math]::Round($longitude, 6)

                $result.PrecisaoMetros = $null

                $result.DataHora = (Get-Date).ToString('o')

                $result.Metodo = 'Geolocalizacao aproximada por IP'

                $result.Provedor = 'ipwho.is'

                $result.Cidade = if ($response.city) {
                    $response.city
                }
                else {
                    'NAO IDENTIFICADA'
                }

                $result.Regiao = if ($response.region) {
                    $response.region
                }
                else {
                    'NAO IDENTIFICADA'
                }

                $result.Pais = if ($response.country) {
                    $response.country
                }
                else {
                    'NAO IDENTIFICADO'
                }

                $result.Observacao = 'Localizacao aproximada pelo IP publico. Nao representa necessariamente a posicao fisica exata do equipamento.'
            }
            else {

                $result.ErroIP = 'O provedor retornou coordenadas fora dos limites validos.'
            }
        }
        else {

            $result.ErroIP = if ($response.message) {
                [string]$response.message
            }
            else {
                'O provedor nao retornou uma localizacao valida.'
            }
        }
    }
    catch {

        $result.ErroIP = $_.Exception.Message
    }

    if (-not $result.Disponivel) {

        $result.Metodo = 'NAO IDENTIFICADO'

        $result.Provedor = 'NAO IDENTIFICADO'

        $result.Observacao = 'Nenhuma fonte de geolocalizacao forneceu dados validos.'
    }

    return $result
}

    # --------------------------------------------------------
    # MONTAGEM DO INVENTARIO
    # --------------------------------------------------------

    Write-Host ''
    Write-Host '[7/7] Consolidando inventario...' -ForegroundColor Green

    $finish = Get-Date

    $inventory = [PSCustomObject]@{

        Produto = 'Seattle Inventory'

        Versao = '1.0.3'

        Desenvolvedor = 'LR Tecnologia'

        DataColeta = $finish.ToString('o')

        InicioColeta = $start.ToString('o')

        FimColeta = $finish.ToString('o')

        Modo = 'Somente leitura'

        EnvioRemoto = $false

        Identificacao = $computer

        Hardware = $hardware

        Software = $software

        Rede = $network

        Localizacao = $location

        Limitacoes = @(

            'A disponibilidade das informacoes depende do hardware e dos drivers.',

            'Sensores de temperatura de CPU e GPU podem nao estar disponiveis.',

            'A leitura SMART depende do disco e do controlador.',

            'A execucao como Administrador pode ampliar a quantidade de dados coletados.',

            'A identificacao de unidades virtuais e aproximada.',

            'A saude e o desgaste da bateria dependem do suporte WMI do equipamento.',

            'A geolocalizacao do Windows depende das permissoes e da disponibilidade do servico de localizacao.',

            'A geolocalizacao por IP e aproximada e nao representa a posicao exata do equipamento.',

            'O Express Service Code somente e apresentado quando obtido por metodo confiavel.',

            'Nenhuma chave de produto do Windows ou Office e coletada.'
        )
    }

    # --------------------------------------------------------
    # NOMES DOS ARQUIVOS
    # --------------------------------------------------------

    $baseName = 'SeattleInventory_{0}_{1}' -f `
        $env:COMPUTERNAME, `
        (Get-Date -Format 'yyyyMMdd_HHmmss')

    $jsonPath = Join-Path $OutputDirectory ($baseName + '.json')

    $htmlPath = Join-Path $OutputDirectory ($baseName + '.html')

    # --------------------------------------------------------
    # GERAR JSON
    # --------------------------------------------------------

    Write-Host ''
    Write-Host 'Gerando arquivo JSON...' -ForegroundColor Yellow

    $json = $inventory | ConvertTo-Json -Depth 30

    $encoding = New-Object System.Text.UTF8Encoding($false)

    [System.IO.File]::WriteAllText(
        $jsonPath,
        $json,
        $encoding
    )

    # --------------------------------------------------------
    # GERAR HTML
    # --------------------------------------------------------

    Write-Host 'Gerando relatorio HTML...' -ForegroundColor Yellow

    New-InventoryHtml `
        -Inventory $inventory `
        -HtmlPath $htmlPath

    # --------------------------------------------------------
    # RESULTADO
    # --------------------------------------------------------

    Write-Host ''
    Write-Host '================================================' -ForegroundColor Green
    Write-Host '              INVENTARIO CONCLUIDO' -ForegroundColor Green
    Write-Host '================================================' -ForegroundColor Green

    Write-Host ''

    Write-Host "Computador: $env:COMPUTERNAME"

    Write-Host "Fabricante: $($computer.Fabricante)"

    Write-Host "Modelo: $($computer.Modelo)"

    Write-Host "Numero de serie: $($computer.NumeroSerie)"

    Write-Host "Service Tag Dell: $($computer.DellServiceTag)"

    Write-Host "Processadores: $(@($hardware.Processadores).Count)"

    Write-Host "Modulos RAM: $(@($hardware.MemoriaRAM).Count)"

    Write-Host "Discos fisicos: $(@($hardware.DiscosFisicos).Count)"

    Write-Host "Volumes: $(@($hardware.Volumes).Count)"

    Write-Host "Programas: $(@($software.ProgramasInstalados).Count)"

    Write-Host "Produtos Office: $(@($software.MicrosoftOffice).Count)"

    Write-Host "Adaptadores de rede: $(@($network.Adaptadores).Count)"

    Write-Host "Impressoras: $(@($network.Impressoras).Count)"

    Write-Host "Portas TCP: $(@($network.PortasTCPEmEscuta).Count)"

    if ($location.Disponivel) {

    Write-Host "Geolocalizacao: $($location.Metodo)" -ForegroundColor Green

    Write-Host "Localidade: $($location.Cidade) / $($location.Regiao) / $($location.Pais)"

    Write-Host "Latitude: $($location.Latitude)"

    Write-Host "Longitude: $($location.Longitude)"
}
else {

    Write-Host 'Geolocalizacao: NAO IDENTIFICADA' -ForegroundColor Yellow

    Write-Host "Windows: $($location.ErroWindows)"

    Write-Host "IP: $($location.ErroIP)"
}

    # --------------------------------------------------------
    # CAMINHOS
    # --------------------------------------------------------

    Write-Host ''
    Write-Host 'ARQUIVOS GERADOS:' -ForegroundColor Cyan

    Write-Host ''
    Write-Host 'JSON:' -ForegroundColor Yellow

    Write-Host $jsonPath -ForegroundColor White

    Write-Host ''
    Write-Host 'HTML:' -ForegroundColor Yellow

    Write-Host $htmlPath -ForegroundColor White

    Write-Host ''
    Write-Host 'Diretorio protegido:' -ForegroundColor Green

    Write-Host $OutputDirectory -ForegroundColor Gray

    # --------------------------------------------------------
    # ABRIR RELATORIO
    # --------------------------------------------------------

    Write-Host ''
    Write-Host 'Abrindo relatorio no navegador...' -ForegroundColor Yellow

    try {

        Start-Process -FilePath $htmlPath -ErrorAction Stop
    }
    catch {

        Write-Warning 'Nao foi possivel abrir o navegador automaticamente.'

        Write-Host "Abra manualmente: $htmlPath"
    }

    Write-Host ''
    Write-Host 'Nenhum relatorio foi transmitido para servidores remotos.' -ForegroundColor Green

    Write-Host 'Inventario finalizado.' -ForegroundColor Green

    Write-Host ''

}
catch {

    Write-Host ''
    Write-Host '================================================' -ForegroundColor Red
    Write-Host '           ERRO DURANTE O INVENTARIO' -ForegroundColor Red
    Write-Host '================================================' -ForegroundColor Red

    Write-Host ''

    Write-Host $_.Exception.Message -ForegroundColor Red

    Write-Host ''

    if ($_.ScriptStackTrace) {

        Write-Host $_.ScriptStackTrace -ForegroundColor DarkRed
    }

    Write-Host ''

    exit 1
}
