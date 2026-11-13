```powershell
# ============================================================
# SEATTLE - LR TECNOLOGIA
# Modulo principal
# Criado e desenvolvido por Leonardo M. Batista
# ============================================================

$ErrorActionPreference = "Stop"

# ------------------------------------------------------------
# CONFIGURACAO
# ------------------------------------------------------------

$GitHubBase = "https://raw.githubusercontent.com/leoklyvert/seattle/main"

$UrlManutencao     = "$GitHubBase/manuten%C3%A7%C3%A3o.ps1"
$UrlDiagnostico    = "$GitHubBase/diagn%C3%B3stico.ps1"
$UrlPersonalizacao = "$GitHubBase/personalizacao.ps1"
$UrlProgramas      = "$GitHubBase/programas.ps1"
$UrlOffice         = "$GitHubBase/office.ps1"
$UrlBackup         = "$GitHubBase/backup.ps1"

$UrlInventario = "$GitHubBase/SeattleInventory_V1.0.ps1"

# Pasta reservada para os inventarios locais
$PastaInventarios = Join-Path $env:ProgramData "LR Tecnologia\Seattle\Inventarios"


# ------------------------------------------------------------
# FUNCOES GERAIS
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
    Write-Host "              Modulo Seattle by LR Tecnologia" -ForegroundColor Cyan
    Write-Host "        Criado e desenvolvido por Leonardo M. Batista" -ForegroundColor Gray
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
}


# ------------------------------------------------------------
# DOWNLOAD DOS MODULOS EXISTENTES
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

            throw "O arquivo retornado esta vazio."
        }

        $Codigo = ([string]$Codigo).TrimStart([char]0xFEFF)

        return $Codigo
    }
    catch {

        Write-Host ""
        Write-Host "ERRO AO CARREGAR MODULO" -ForegroundColor Red
        Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host "Modulo: $Nome" -ForegroundColor White
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

    $Codigo = Obter-Modulo `
        -Url $Url `
        -Nome $Nome

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
        Write-Host "ERRO DURANTE A EXECUCAO DO MODULO" -ForegroundColor Red
        Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host ""

        Pausar
    }
}


# ------------------------------------------------------------
# PROTECAO DA PASTA DE INVENTARIOS
# ------------------------------------------------------------

function Configurar-PastaReservada {

    param(
        [Parameter(Mandatory = $true)]
        [string]$Caminho
    )

    if (-not (Test-Path -LiteralPath $Caminho)) {

        New-Item `
            -ItemType Directory `
            -Path $Caminho `
            -Force | Out-Null
    }

    # Impede heranca de permissoes externas
    $acl = Get-Acl -LiteralPath $Caminho

    $acl.SetAccessRuleProtection($true, $false)

    # Remove regras anteriores
    foreach ($rule in @($acl.Access)) {

        [void]$acl.RemoveAccessRuleAll($rule)
    }

    # Usuarios autorizados:
    # SYSTEM
    # Administradores
    # Usuario atual

    $identidades = @(
        "S-1-5-18",
        "S-1-5-32-544",
        [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value
    ) | Select-Object -Unique

    foreach ($sidTexto in $identidades) {

        $sid = New-Object System.Security.Principal.SecurityIdentifier($sidTexto)

        $regra = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $sid,
            "FullControl",
            "ContainerInherit,ObjectInherit",
            "None",
            "Allow"
        )

        [void]$acl.AddAccessRule($regra)
    }

    Set-Acl -LiteralPath $Caminho -AclObject $acl

    # Marca a pasta como oculta
    $item = Get-Item -LiteralPath $Caminho -Force

    $item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::Hidden
}


# ------------------------------------------------------------
# INVENTARIO COMPLETO
# ------------------------------------------------------------

function Executar-Inventario {

    $ArquivoTemporario = $null

    try {

        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "             SEATTLE INVENTORY" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host ""

        Write-Host "Preparando ambiente de inventario..." -ForegroundColor Yellow

        # Cria e protege a pasta principal
        Configurar-PastaReservada -Caminho $PastaInventarios

        # Pasta individual do computador
        $PastaComputador = Join-Path $PastaInventarios $env:COMPUTERNAME

        Configurar-PastaReservada -Caminho $PastaComputador

        Write-Host ""
        Write-Host "Armazenamento reservado configurado." -ForegroundColor Green
        Write-Host "Computador: $env:COMPUTERNAME" -ForegroundColor Gray
        Write-Host ""

        # Nome temporario exclusivo
        $ArquivoTemporario = Join-Path `
            $env:TEMP `
            ("SeattleInventory_" + [guid]::NewGuid().ToString() + ".ps1")

        Write-Host "Baixando coletor do GitHub..." -ForegroundColor Yellow

        $Resposta = Invoke-WebRequest `
            -Uri $UrlInventario `
            -UseBasicParsing `
            -TimeoutSec 120

        $Codigo = [string]$Resposta.Content

        if ([string]::IsNullOrWhiteSpace($Codigo)) {

            throw "O coletor retornado pelo GitHub esta vazio."
        }

        $Codigo = $Codigo.TrimStart([char]0xFEFF)

        # Salva temporariamente em UTF-8 sem BOM
        $encoding = New-Object System.Text.UTF8Encoding($false)

        [System.IO.File]::WriteAllText(
            $ArquivoTemporario,
            $Codigo,
            $encoding
        )

        Write-Host ""
        Write-Host "Iniciando coleta de inventario..." -ForegroundColor Green
        Write-Host ""

        # Executa o coletor como script independente
        & $ArquivoTemporario -OutputDirectory $PastaComputador

        if ($LASTEXITCODE -and $LASTEXITCODE -ne 0) {

            throw "O coletor retornou um codigo de erro."
        }

        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Green
        Write-Host "          INVENTARIO FINALIZADO" -ForegroundColor Green
        Write-Host "============================================================" -ForegroundColor Green

        Write-Host ""
        Write-Host "Relatorios armazenados localmente em:" -ForegroundColor Cyan
        Write-Host $PastaComputador -ForegroundColor White

        Write-Host ""
        Write-Host "Nenhum relatorio foi enviado pela internet." -ForegroundColor Green

        Write-Host ""
        Write-Host "Os arquivos permanecem protegidos no computador."

    }
    catch {

        Write-Host ""
        Write-Host "ERRO AO EXECUTAR INVENTARIO" -ForegroundColor Red
        Write-Host "------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host $_.Exception.Message -ForegroundColor Red
        Write-Host ""

    }
    finally {

        # Remove o coletor temporario
        if (
            $ArquivoTemporario -and
            (Test-Path -LiteralPath $ArquivoTemporario)
        ) {

            Remove-Item `
                -LiteralPath $ArquivoTemporario `
                -Force `
                -ErrorAction SilentlyContinue
        }

        Pausar
    }
}


# ------------------------------------------------------------
# MENU PRINCIPAL
# ------------------------------------------------------------

function Menu-Principal {

    do {

        Mostrar-Cabecalho

        Write-Host "MENU PRINCIPAL" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "1 - Manutencao"
        Write-Host "2 - Personalizacao"
        Write-Host "3 - Programas"
        Write-Host "4 - Office"
        Write-Host "5 - Diagnostico Preventivo"
        Write-Host "6 - Backup e restauracao"
        Write-Host "7 - Inventario completo"
        Write-Host "0 - Sair"
        Write-Host ""

        $Opcao = [System.Console]::ReadKey($true).KeyChar

        switch ($Opcao) {

            "1" {

                Executar-Modulo `
                    -Url $UrlManutencao `
                    -Nome "Manutencao"
            }

            "2" {

                Executar-Modulo `
                    -Url $UrlPersonalizacao `
                    -Nome "Personalizacao"
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

                Executar-Modulo `
                    -Url $UrlDiagnostico `
                    -Nome "Diagnostico Preventivo"
            }

            "6" {

                Executar-Modulo `
                    -Url $UrlBackup `
                    -Nome "Backup e restauracao"
            }

            "7" {

                Executar-Inventario
            }

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
# INICIO
# ============================================================

Menu-Principal
```
