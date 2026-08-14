# ============================================================
# LR TECNOLOGIA
# Módulo: Personalização
# Versão: 1.0.0
# ============================================================

$VersaoPersonalizacao = "1.0.0"

# ============================================================
# VERIFICAÇÃO DE ADMINISTRADOR
# ============================================================

$Identidade = [Security.Principal.WindowsIdentity]::GetCurrent()
$Principal = New-Object Security.Principal.WindowsPrincipal($Identidade)

if (-not $Principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)) {

    Write-Host ""
    Write-Host "Esta etapa precisa ser executada como Administrador." -ForegroundColor Yellow
    Write-Host "Solicitando permissao do Windows..." -ForegroundColor Cyan
    Write-Host ""

    $Url = "https://github.com/leoklyvert/seattle/raw/refs/heads/main/personalizacao.ps1"

    Start-Process `
        -FilePath "powershell.exe" `
        -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"irm '$Url' | iex`"" `
        -Verb RunAs

    exit
}

# ============================================================
# CABEÇALHO
# ============================================================

Clear-Host

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "                  LR TECNOLOGIA" -ForegroundColor Cyan
Write-Host "                    PERSONALIZACAO" -ForegroundColor Cyan
Write-Host "                     Versao $VersaoPersonalizacao" -ForegroundColor DarkCyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# 1 - VISUAL C++ REDISTRIBUTABLES
# ============================================================

Write-Host "1/8 - Instalando bibliotecas Microsoft Visual C++..." -ForegroundColor Yellow
Write-Host ""

$PastaTemp = Join-Path $env:TEMP "LR-VCpp"

if (-not (Test-Path $PastaTemp)) {

    New-Item `
        -ItemType Directory `
        -Path $PastaTemp `
        -Force |
        Out-Null
}

$Pacotes = @(
    @{
        Nome = "VC++ 2013 x86"
        Url = "https://download.microsoft.com/download/9/3/F/93F7C6F2-9B9E-4E6B-9C1E-2C6B8A8F7F3E/vcredist_x86.exe"
        Arquivo = "vcredist_2013_x86.exe"
    },
    @{
        Nome = "VC++ 2013 x64"
        Url = "https://download.microsoft.com/download/9/3/F/93F7C6F2-9B9E-4E6B-9C1E-2C6B8A8F7F3E/vcredist_x64.exe"
        Arquivo = "vcredist_2013_x64.exe"
    },
    @{
        Nome = "VC++ 2015-2022 x86"
        Url = "https://aka.ms/vs/17/release/vc_redist.x86.exe"
        Arquivo = "vc_redist.x86.exe"
    },
    @{
        Nome = "VC++ 2015-2022 x64"
        Url = "https://aka.ms/vs/17/release/vc_redist.x64.exe"
        Arquivo = "vc_redist.x64.exe"
    }
)

foreach ($Pacote in $Pacotes) {

    $Arquivo = Join-Path $PastaTemp $Pacote.Arquivo

    try {

        Write-Host "Baixando $($Pacote.Nome)..." -ForegroundColor Cyan

        Invoke-WebRequest `
            -Uri $Pacote.Url `
            -OutFile $Arquivo `
            -UseBasicParsing `
            -ErrorAction Stop

        Write-Host "Instalando $($Pacote.Nome)..." -ForegroundColor Cyan

        $Processo = Start-Process `
            -FilePath $Arquivo `
            -ArgumentList "/quiet /norestart" `
            -Wait `
            -PassThru `
            -ErrorAction Stop

        if ($Processo.ExitCode -eq 0) {

            Write-Host "[OK] $($Pacote.Nome)" -ForegroundColor Green
        }
        elseif ($Processo.ExitCode -eq 3010) {

            Write-Host "[OK] $($Pacote.Nome) - Reinicio recomendado" -ForegroundColor Green
        }
        else {

            Write-Host "[ERRO] $($Pacote.Nome) - Codigo $($Processo.ExitCode)" -ForegroundColor Red
        }

    }
    catch {

        Write-Host "[ERRO] $($Pacote.Nome)" -ForegroundColor Red
        Write-Host $_.Exception.Message -ForegroundColor Red
    }
}

# ============================================================
# 2 - REMOVER MARK OF THE WEB
# ============================================================

Write-Host ""
Write-Host "2/8 - Removendo Mark of the Web..." -ForegroundColor Yellow
Write-Host ""

$PastasUsuario = @(
    [Environment]::GetFolderPath("Desktop"),
    [Environment]::GetFolderPath("MyDocuments"),
    [Environment]::GetFolderPath("MyPictures"),
    [Environment]::GetFolderPath("MyVideos"),
    [Environment]::GetFolderPath("MyMusic"),
    (Join-Path $env:USERPROFILE "Downloads")
)

$PastasUsuario = $PastasUsuario |
    Where-Object {
        $_ -and (Test-Path $_)
    } |
    Sort-Object -Unique

$TotalDesbloqueados = 0

foreach ($Pasta in $PastasUsuario) {

    Write-Host "Processando: $Pasta" -ForegroundColor DarkCyan

    Get-ChildItem `
        -Path $Pasta `
        -Recurse `
        -File `
        -Force `
        -ErrorAction SilentlyContinue |
    ForEach-Object {

        try {

            $Streams = Get-Item `
                $_.FullName `
                -Stream * `
                -ErrorAction Stop

            if ($Streams.Stream -contains "Zone.Identifier") {

                Unblock-File `
                    -Path $_.FullName `
                    -ErrorAction Stop

                $TotalDesbloqueados++
            }

        }
        catch {
            # Ignora arquivos que não possam ser processados.
        }
    }
}

Write-Host ""
Write-Host "Arquivos desbloqueados: $TotalDesbloqueados" -ForegroundColor Green

# ============================================================
# 3 - CONFIGURAR DESEMPENHO / ENERGIA
# ============================================================

Write-Host ""
Write-Host "3/8 - Configurando energia e desempenho..." -ForegroundColor Yellow
Write-Host ""

powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null

powercfg /change monitor-timeout-ac 0
powercfg /change monitor-timeout-dc 0
powercfg /change disk-timeout-ac 0
powercfg /change disk-timeout-dc 0
powercfg /change standby-timeout-ac 0
powercfg /change standby-timeout-dc 0

powercfg.exe /hibernate off

Write-Host "Configuração de energia concluída." -ForegroundColor Green

# ============================================================
# 4 - PERSONALIZAÇÃO DA BARRA DE TAREFAS
# ============================================================

Write-Host ""
Write-Host "4/8 - Personalizando barra de tarefas..." -ForegroundColor Yellow
Write-Host ""

$SearchPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"

if (-not (Test-Path $SearchPath)) {

    New-Item `
        -Path $SearchPath `
        -Force |
        Out-Null
}

New-ItemProperty `
    -Path $SearchPath `
    -Name "SearchboxTaskbarMode" `
    -PropertyType DWORD `
    -Value 0 `
    -Force |
    Out-Null

$ExplorerPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"

if (-not (Test-Path $ExplorerPath)) {

    New-Item `
        -Path $ExplorerPath `
        -Force |
        Out-Null
}

New-ItemProperty `
    -Path $ExplorerPath `
    -Name "ShowTaskViewButton" `
    -PropertyType DWORD `
    -Value 0 `
    -Force |
    Out-Null

Write-Host "Barra de tarefas configurada." -ForegroundColor Green

# ============================================================
# 5 - CONFIGURAR HORÁRIO NTP
# ============================================================

Write-Host ""
Write-Host "5/8 - Configurando sincronização de horário..." -ForegroundColor Yellow
Write-Host ""

$NTPServers = "a.st1.ntp.br c.st1.ntp.br d.st1.ntp.br e.st1.ntp.br"

w32tm /config `
    /manualpeerlist:"$NTPServers" `
    /syncfromflags:manual `
    /update |
    Out-Null

Set-Service `
    -Name W32Time `
    -StartupType Automatic

Restart-Service `
    -Name W32Time `
    -Force

Start-Sleep -Seconds 5

w32tm /resync /force 2>$null

Write-Host "Sincronização NTP configurada." -ForegroundColor Green

# ============================================================
# 6 - REMOVER APLICATIVOS NATIVOS SELECIONADOS
# ============================================================

Write-Host ""
Write-Host "6/8 - Removendo aplicativos nativos selecionados..." -ForegroundColor Yellow
Write-Host ""

$AplicativosRemover = @(
    "*3dbuilder*",
    "*windowsalarms*",
    "*windowscommunicationsapps*",
    "*skypeapp*",
    "*zunemusic*",
    "*windowsmaps*",
    "*solitairecollection*",
    "*bingfinance*",
    "*zunevideo*",
    "*bingnews*",
    "*onenote*",
    "*people*",
    "*windowsphone*",
    "*bingsports*",
    "*soundrecorder*",
    "*bingweather*",
    "*xboxapp*",
    "*Microsoft.Microsoft3DViewer*",
    "*Microsoft.MixedReality.Portal*",
    "*Microsoft.WindowsFeedbackHub*",
    "*Microsoft.GetHelp*",
    "*Microsoft.Getstarted*",
    "*Microsoft.YourPhone*",
    "*Microsoft.WindowsMaps*",
    "*Microsoft.BingNews*",
    "*Microsoft.XboxGamingOverlay*"
)

foreach ($Aplicativo in $AplicativosRemover) {

    Get-AppxPackage `
        -Name $Aplicativo `
        -ErrorAction SilentlyContinue |
    Remove-AppxPackage `
        -ErrorAction SilentlyContinue
}

Write-Host "Aplicativos selecionados processados." -ForegroundColor Green

# ============================================================
# 7 - DESINSTALAR ONEDRIVE E DRIVER BOOSTER
# ============================================================

Write-Host ""
Write-Host "7/8 - Removendo softwares selecionados..." -ForegroundColor Yellow
Write-Host ""

# ----------------------------
# OneDrive
# ----------------------------

Write-Host "Verificando OneDrive..." -ForegroundColor Cyan

$OneDriveSetup = "$env:SystemRoot\System32\OneDriveSetup.exe"

if (Test-Path $OneDriveSetup) {

    Start-Process `
        -FilePath $OneDriveSetup `
        -ArgumentList "/uninstall" `
        -Wait `
        -ErrorAction SilentlyContinue

    Write-Host "OneDrive processado." -ForegroundColor Green
}
else {

    Write-Host "OneDriveSetup não encontrado." -ForegroundColor DarkGray
}

# ----------------------------
# Driver Booster
# ----------------------------

Write-Host ""
Write-Host "Verificando Driver Booster..." -ForegroundColor Cyan

winget uninstall `
    --id IObit.DriverBooster `
    --silent `
    --accept-source-agreements `
    --disable-interactivity `
    2>$null

Write-Host "Driver Booster processado." -ForegroundColor Green

# ============================================================
# 8 - LIMPEZA
# ============================================================

Write-Host ""
Write-Host "8/8 - Limpando arquivos temporários..." -ForegroundColor Yellow
Write-Host ""

$PastasLimpeza = @(
    "$env:TEMP",
    "$env:LOCALAPPDATA\Temp",
    "C:\Windows\Temp",
    "C:\Temp",
    "C:\Office",
    "C:\InstaladoresDotNet",
    "C:\InstaladoresVCpp"
)

foreach ($Pasta in $PastasLimpeza) {

    if (Test-Path $Pasta) {

        Write-Host "Limpando: $Pasta" -ForegroundColor DarkCyan

        Get-ChildItem `
            -Path $Pasta `
            -Force `
            -ErrorAction SilentlyContinue |
        Remove-Item `
            -Recurse `
            -Force `
            -ErrorAction SilentlyContinue
    }
}

# ============================================================
# LIMPAR LIXEIRA
# ============================================================

Write-Host ""
Write-Host "Esvaziando a Lixeira..." -ForegroundColor Cyan

Clear-RecycleBin `
    -Force `
    -ErrorAction SilentlyContinue

# ============================================================
# LIMPAR ARQUIVOS TEMPORÁRIOS DO MÓDULO
# ============================================================

if (Test-Path $PastaTemp) {

    Remove-Item `
        -Path $PastaTemp `
        -Recurse `
        -Force `
        -ErrorAction SilentlyContinue
}

# ============================================================
# FINALIZAÇÃO
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Green
Write-Host "              PERSONALIZACAO CONCLUIDA" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Versao do modulo: $VersaoPersonalizacao" -ForegroundColor Cyan
Write-Host ""

Write-Host "O computador sera reiniciado em 60 segundos." -ForegroundColor Yellow
Write-Host ""
Write-Host "Para cancelar o reinicio, execute:" -ForegroundColor DarkGray
Write-Host "shutdown.exe /a" -ForegroundColor DarkGray
Write-Host ""

shutdown.exe /r /t 60
