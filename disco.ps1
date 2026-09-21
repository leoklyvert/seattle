# ============================================================
# LR TECNOLOGIA
# SEATTLE - TESTE E DIAGNÓSTICO DE ARMAZENAMENTO
#
# Versão: 2.1.0
#
# Diagnóstico somente leitura:
#   - Identificação HDD / SSD / NVMe
#   - HealthStatus / OperationalStatus
#   - Storage Reliability Counter
#   - Temperatura
#   - Horas de uso
#   - Desgaste
#   - Erros de leitura/gravação
#   - Latência
#   - Espaço livre
#   - CHKDSK /SCAN
#   - Eventos de armazenamento
#   - Teste de leitura com WinSAT
#   - Geração de relatório PDF local
#
# NÃO EXECUTA:
#   - CHKDSK /F
#   - CHKDSK /R
#   - Formatação
#   - Escrita de arquivo para benchmark
#   - Alterações no disco
#
# Desenvolvido por Leonardo M. Batista
# LR Tecnologia
# ============================================================

$ErrorActionPreference = "SilentlyContinue"

Clear-Host

$Inicio = Get-Date

$Resultado = "NORMAL"

$Alertas = New-Object System.Collections.Generic.List[string]
$Avisos  = New-Object System.Collections.Generic.List[string]

$DadosDiscos = New-Object System.Collections.Generic.List[object]

$ChkDiskTexto = ""
$EventosResumo = New-Object System.Collections.Generic.List[object]
$WinSATTexto = ""


# ============================================================
# FUNÇÕES
# ============================================================

function Adicionar-Alerta {

    param(
        [string]$Mensagem
    )

    if (-not $Alertas.Contains($Mensagem)) {
        $Alertas.Add($Mensagem)
    }
}


function Adicionar-Aviso {

    param(
        [string]$Mensagem
    )

    if (-not $Avisos.Contains($Mensagem)) {
        $Avisos.Add($Mensagem)
    }
}


function Nivel-Atencao {

    if ($Resultado -eq "NORMAL") {
        $script:Resultado = "ATENÇÃO"
    }
}


function Nivel-Critico {

    $script:Resultado = "CRÍTICO"
}


function Mostrar-Linha {

    Write-Host "------------------------------------------------------------"
}


function Html {

    param(
        [AllowNull()]
        [object]$Texto
    )

    if ($null -eq $Texto) {
        return ""
    }

    return [System.Net.WebUtility]::HtmlEncode([string]$Texto)
}


function Obter-Caminho-Navegador {

    $Caminhos = @(
        "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe",
        "${env:ProgramFiles(x86)}\Microsoft\Edge\Application\msedge.exe",
        "$env:LOCALAPPDATA\Microsoft\Edge\Application\msedge.exe",
        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
        "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
        "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
    )

    foreach ($Caminho in $Caminhos) {

        if ($Caminho -and (Test-Path $Caminho)) {
            return $Caminho
        }
    }

    return $null
}


function Gerar-PDF {

    param(
        [string]$CaminhoPDF,
        [string]$CaminhoHTML
    )

    $Navegador = Obter-Caminho-Navegador

    if (-not $Navegador) {

        Write-Host ""
        Write-Host "Microsoft Edge/Google Chrome não encontrado." `
            -ForegroundColor Yellow

        Write-Host ""
        Write-Host "O relatório HTML foi mantido em:"
        Write-Host $CaminhoHTML

        return $false
    }

    Write-Host ""
    Write-Host "Gerando relatório PDF..." `
        -ForegroundColor Cyan

    try {

        $Argumentos = @(
            "--headless=new"
            "--disable-gpu"
            "--no-first-run"
            "--no-default-browser-check"
            "--print-to-pdf=`"$CaminhoPDF`""
            "--print-to-pdf-no-header"
            "`"$CaminhoHTML`""
        )

        $Processo = Start-Process `
            -FilePath $Navegador `
            -ArgumentList $Argumentos `
            -Wait `
            -PassThru `
            -WindowStyle Hidden

        Start-Sleep -Seconds 2

        if (Test-Path $CaminhoPDF) {

            return $true
        }

    }
    catch {

        Write-Host ""
        Write-Host "Erro ao gerar o PDF: $($_.Exception.Message)" `
            -ForegroundColor Yellow
    }

    return $false
}


# ============================================================
# CABEÇALHO
# ============================================================

Write-Host ""
Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host "       LR TECNOLOGIA - DIAGNÓSTICO DO ARMAZENAMENTO" `
    -ForegroundColor Cyan

Write-Host "============================================================" `
    -ForegroundColor Cyan

Write-Host ""

$DataHoraInicio = Get-Date -Format "dd/MM/yyyy HH:mm:ss"

Write-Host "Computador : $env:COMPUTERNAME"
Write-Host "Usuário    : $env:USERNAME"
Write-Host "Windows    : $([System.Environment]::OSVersion.Version)"
Write-Host "Data       : $DataHoraInicio"
Write-Host ""


# ============================================================
# VERIFICAR ADMINISTRADOR
# ============================================================

$Principal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)

$Administrador = $Principal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $Administrador) {

    Write-Host "AVISO: PowerShell não está sendo executado como Administrador." `
        -ForegroundColor Yellow

    Write-Host ""
    Write-Host "Algumas informações podem não estar disponíveis."
    Write-Host ""

    Adicionar-Aviso `
        "O PowerShell não foi executado como Administrador. Algumas informações podem estar incompletas."
}


# ============================================================
# UNIDADE DO SISTEMA
# ============================================================

Write-Host "UNIDADE DO SISTEMA" -ForegroundColor Cyan

Mostrar-Linha

$ParticaoSistema = Get-CimInstance Win32_LogicalDisk `
    -Filter "DeviceID='C:'"

$EspacoTotal = 0
$EspacoLivre = 0
$PercentualLivre = 0

if ($ParticaoSistema -and $ParticaoSistema.Size -gt 0) {

    $EspacoTotal = [math]::Round(
        $ParticaoSistema.Size / 1GB,
        2
    )

    $EspacoLivre = [math]::Round(
        $ParticaoSistema.FreeSpace / 1GB,
        2
    )

    $PercentualLivre = [math]::Round(
        ($ParticaoSistema.FreeSpace / $ParticaoSistema.Size) * 100,
        1
    )

    Write-Host "Unidade       : C:"
    Write-Host "Capacidade    : $EspacoTotal GB"
    Write-Host "Espaço livre  : $EspacoLivre GB"
    Write-Host "Livre         : $PercentualLivre %"

    if ($PercentualLivre -lt 10) {

        Adicionar-Alerta `
            "A unidade C: possui menos de 10% de espaço livre."

        Nivel-Atencao
    }

    elseif ($PercentualLivre -lt 15) {

        Adicionar-Aviso `
            "A unidade C: possui pouco espaço livre."
    }

}
else {

    Adicionar-Aviso `
        "Não foi possível obter os dados da unidade C:."
}

Write-Host ""


# ============================================================
# DISCOS FÍSICOS
# ============================================================

Write-Host "DISCOS FÍSICOS" -ForegroundColor Cyan

Mostrar-Linha

$Discos = @(Get-PhysicalDisk)

if ($Discos.Count -eq 0) {

    Write-Host "Não foi possível consultar os discos físicos." `
        -ForegroundColor Red

    Adicionar-Alerta `
        "O Windows não conseguiu fornecer informações dos discos."

    Nivel-Atencao

}
else {

    foreach ($Disco in $Discos) {

        Write-Host ""
        Write-Host "DISCO: $($Disco.FriendlyName)" `
            -ForegroundColor Cyan

        Write-Host ""


        # ====================================================
        # IDENTIFICAÇÃO
        # ====================================================

        switch ([string]$Disco.MediaType) {

            "HDD" {
                $TipoMidia = "HD mecânico (HDD)"
            }

            "SSD" {
                $TipoMidia = "SSD"
            }

            "SCM" {
                $TipoMidia = "SCM"
            }

            default {
                $TipoMidia = "Não identificado pelo Windows"
            }
        }


        if (
            ([string]$Disco.BusType -eq "NVMe") -or
            ([string]$Disco.FriendlyName -match "NVMe")
        ) {

            $TipoMidia = "SSD NVMe"
        }


        $CapacidadeDisco = [math]::Round(
            $Disco.Size / 1GB,
            2
        )


        Write-Host "Tipo              : $TipoMidia"
        Write-Host "Modelo            : $($Disco.FriendlyName)"
        Write-Host "Fabricante        : $($Disco.Manufacturer)"
        Write-Host "Número de série   : $($Disco.SerialNumber)"
        Write-Host "Barramento        : $($Disco.BusType)"
        Write-Host "Capacidade        : $CapacidadeDisco GB"
        Write-Host "HealthStatus      : $($Disco.HealthStatus)"
        Write-Host "OperationalStatus : $($Disco.OperationalStatus)"


        # ====================================================
        # OBJETO PARA O RELATÓRIO
        # ====================================================

        $DadosDisco = [PSCustomObject]@{

            Tipo              = $TipoMidia
            Modelo            = [string]$Disco.FriendlyName
            Fabricante        = [string]$Disco.Manufacturer
            Serial            = [string]$Disco.SerialNumber
            Barramento        = [string]$Disco.BusType
            Capacidade        = "$CapacidadeDisco GB"
            HealthStatus      = [string]$Disco.HealthStatus
            OperationalStatus = [string]$Disco.OperationalStatus
            Temperatura       = "Não disponível"
            HorasUso          = "Não disponível"
            Desgaste          = "Não disponível"
            ErrosLeitura     = "Não disponível"
            ErrosGravacao     = "Não disponível"
            LatenciaLeitura   = "Não disponível"
            LatenciaGravacao  = "Não disponível"
        }


        # ====================================================
        # HEALTH STATUS
        # ====================================================

        if ([string]$Disco.HealthStatus -eq "Unhealthy") {

            Adicionar-Alerta `
                "O disco '$($Disco.FriendlyName)' está com HealthStatus UNHEALTHY."

            Nivel-Critico
        }

        elseif ([string]$Disco.HealthStatus -eq "Warning") {

            Adicionar-Alerta `
                "O disco '$($Disco.FriendlyName)' está com HealthStatus WARNING."

            Nivel-Atencao
        }

        elseif ([string]$Disco.HealthStatus -eq "Unknown") {

            Adicionar-Aviso `
                "O Windows não conseguiu determinar completamente a saúde de '$($Disco.FriendlyName)'."
        }


        # ====================================================
        # STORAGE RELIABILITY
        # ====================================================

        Write-Host ""
        Write-Host "INDICADORES DE CONFIABILIDADE" `
            -ForegroundColor Yellow

        Mostrar-Linha

        $Contador = Get-StorageReliabilityCounter `
            -PhysicalDisk $Disco

        if ($Contador) {


            # ------------------------------------------------
            # TEMPERATURA
            # ------------------------------------------------

            if ($null -ne $Contador.Temperature) {

                $Temperatura = $Contador.Temperature

                $DadosDisco.Temperatura = "$Temperatura °C"

                Write-Host "Temperatura       : $Temperatura °C"

                if ($Temperatura -ge 70) {

                    Adicionar-Alerta `
                        "Temperatura muito elevada no disco '$($Disco.FriendlyName)': $Temperatura °C."

                    Nivel-Critico
                }

                elseif ($Temperatura -ge 60) {

                    Adicionar-Alerta `
                        "Temperatura elevada no disco '$($Disco.FriendlyName)': $Temperatura °C."

                    Nivel-Atencao
                }

            }
            else {

                Write-Host "Temperatura       : Não disponível"
            }


            # ------------------------------------------------
            # HORAS DE USO
            # ------------------------------------------------

            if ($null -ne $Contador.PowerOnHours) {

                $DadosDisco.HorasUso = "$($Contador.PowerOnHours) h"

                Write-Host "Horas ligado      : $($Contador.PowerOnHours) h"
            }
            else {

                Write-Host "Horas ligado      : Não disponível"
            }


            # ------------------------------------------------
            # DESGASTE
            # ------------------------------------------------

            if ($null -ne $Contador.Wear) {

                $DadosDisco.Desgaste = "$($Contador.Wear)%"

                Write-Host "Desgaste          : $($Contador.Wear)%"

                if ($Contador.Wear -ge 90) {

                    Adicionar-Alerta `
                        "Indicador de desgaste muito elevado no disco '$($Disco.FriendlyName)': $($Contador.Wear)%."

                    Nivel-Critico
                }

                elseif ($Contador.Wear -ge 80) {

                    Adicionar-Alerta `
                        "Indicador de desgaste elevado no disco '$($Disco.FriendlyName)': $($Contador.Wear)%."

                    Nivel-Atencao
                }
            }
            else {

                Write-Host "Desgaste          : Não disponível"
            }


            # ------------------------------------------------
            # ERROS DE LEITURA
            # ------------------------------------------------

            if ($null -ne $Contador.ReadErrorsUncorrected) {

                $DadosDisco.ErrosLeitura =
                    [string]$Contador.ReadErrorsUncorrected

                Write-Host "Erros leitura     : $($Contador.ReadErrorsUncorrected)"

                if ($Contador.ReadErrorsUncorrected -gt 0) {

                    Adicionar-Alerta `
                        "Existem erros de leitura não corrigidos no disco '$($Disco.FriendlyName)'."

                    Nivel-Critico
                }
            }
            else {

                Write-Host "Erros leitura     : Não disponível"
            }


            # ------------------------------------------------
            # ERROS DE GRAVAÇÃO
            # ------------------------------------------------

            if ($null -ne $Contador.WriteErrorsUncorrected) {

                $DadosDisco.ErrosGravacao =
                    [string]$Contador.WriteErrorsUncorrected

                Write-Host "Erros gravação    : $($Contador.WriteErrorsUncorrected)"

                if ($Contador.WriteErrorsUncorrected -gt 0) {

                    Adicionar-Alerta `
                        "Existem erros de gravação não corrigidos no disco '$($Disco.FriendlyName)'."

                    Nivel-Critico
                }
            }
            else {

                Write-Host "Erros gravação    : Não disponível"
            }


            # ------------------------------------------------
            # LATÊNCIA LEITURA
            # ------------------------------------------------

            if ($null -ne $Contador.ReadLatencyMax) {

                $DadosDisco.LatenciaLeitura =
                    "$($Contador.ReadLatencyMax) ms"

                Write-Host "Latência leitura  : $($Contador.ReadLatencyMax) ms"

                if ($Contador.ReadLatencyMax -gt 10000) {

                    Adicionar-Alerta `
                        "Latência máxima de leitura superior a 10 segundos no disco '$($Disco.FriendlyName)'."

                    Nivel-Atencao
                }
            }


            # ------------------------------------------------
            # LATÊNCIA GRAVAÇÃO
            # ------------------------------------------------

            if ($null -ne $Contador.WriteLatencyMax) {

                $DadosDisco.LatenciaGravacao =
                    "$($Contador.WriteLatencyMax) ms"

                Write-Host "Latência gravação : $($Contador.WriteLatencyMax) ms"

                if ($Contador.WriteLatencyMax -gt 10000) {

                    Adicionar-Alerta `
                        "Latência máxima de gravação superior a 10 segundos no disco '$($Disco.FriendlyName)'."

                    Nivel-Atencao
                }
            }

        }
        else {

            Write-Host "Contadores        : Não disponíveis" `
                -ForegroundColor Yellow

            Adicionar-Aviso `
                "Os contadores de confiabilidade não estão disponíveis para '$($Disco.FriendlyName)'."
        }


        $DadosDiscos.Add($DadosDisco)

        Write-Host ""
    }
}


# ============================================================
# CHKDSK /SCAN
# ============================================================

Write-Host ""
Write-Host "VERIFICAÇÃO DO SISTEMA DE ARQUIVOS" `
    -ForegroundColor Cyan

Mostrar-Linha

Write-Host ""
Write-Host "Executando CHKDSK /SCAN na unidade C:..."
Write-Host "Este teste não executa /F nem /R."
Write-Host ""

$ChkDiskResultado = & chkdsk.exe C: /scan 2>&1

$ChkDiskTexto = $ChkDiskResultado -join "`n"

Write-Host $ChkDiskTexto

if ($LASTEXITCODE -ne 0) {

    Adicionar-Alerta `
        "O CHKDSK retornou código diferente de zero."

    Nivel-Atencao
}


if (
    ($ChkDiskTexto -match "Windows found problems") -or
    ($ChkDiskTexto -match "found problems") -or
    (
        ($ChkDiskTexto -match "problemas") -and
        ($ChkDiskTexto -match "encontr")
    )
) {

    Adicionar-Alerta `
        "O CHKDSK indicou possíveis problemas no sistema de arquivos."

    Nivel-Atencao
}


# ============================================================
# EVENTOS DE ARMAZENAMENTO
# ============================================================

Write-Host ""
Write-Host "EVENTOS RECENTES DE ARMAZENAMENTO" `
    -ForegroundColor Cyan

Mostrar-Linha

Write-Host ""
Write-Host "Consultando eventos dos últimos 7 dias..."

$DataInicio = (Get-Date).AddDays(-7)

$EventosDisco = @(
    Get-WinEvent `
        -FilterHashtable @{
            LogName = "System"
            StartTime = $DataInicio
        } `
        -ErrorAction SilentlyContinue |
    Where-Object {

        $_.ProviderName -match `
        "disk|storahci|stornvme|iaStor|Ntfs|volmgr"
    }
)

$EventosErro = @(
    $EventosDisco |
    Where-Object {

        $_.LevelDisplayName -eq "Error" -or
        $_.LevelDisplayName -eq "Critical"
    }
)

Write-Host "Eventos encontrados : $($EventosDisco.Count)"
Write-Host "Erros críticos      : $($EventosErro.Count)"


foreach ($Evento in ($EventosErro | Select-Object -First 10)) {

    $EventosResumo.Add(
        [PSCustomObject]@{
            Data     = $Evento.TimeCreated
            Origem   = $Evento.ProviderName
            ID       = $Evento.Id
            Mensagem = $Evento.Message
        }
    )
}


if ($EventosErro.Count -gt 0) {

    Write-Host ""
    Write-Host "Eventos de erro encontrados:" `
        -ForegroundColor Yellow

    foreach ($Evento in ($EventosErro | Select-Object -First 10)) {

        Write-Host ""
        Write-Host "Data    : $($Evento.TimeCreated)"
        Write-Host "Origem  : $($Evento.ProviderName)"
        Write-Host "ID      : $($Evento.Id)"
        Write-Host "Mensagem: $($Evento.Message)"
    }

    Adicionar-Alerta `
        "Foram encontrados eventos de erro relacionados ao armazenamento nos últimos 7 dias."

    Nivel-Atencao

}
else {

    Write-Host ""
    Write-Host "Nenhum erro crítico de armazenamento encontrado." `
        -ForegroundColor Green
}


# ============================================================
# TESTE DE LEITURA - SEM ESCRITA
# ============================================================

Write-Host ""
Write-Host "TESTE DE LEITURA / DESEMPENHO" `
    -ForegroundColor Cyan

Mostrar-Linha

Write-Host ""
Write-Host "Este teste não cria arquivo temporário."
Write-Host "Não serão gravados dados no disco."
Write-Host ""

$WinSAT = Get-Command winsat.exe `
    -ErrorAction SilentlyContinue

if ($WinSAT) {

    Write-Host "Executando teste de leitura do Windows..."
    Write-Host "Aguarde..."
    Write-Host ""

    $WinSATResultado = & winsat.exe `
        disk `
        -drive c `
        -seq -read `
        -ran -read `
        2>&1

    $WinSATTexto = $WinSATResultado -join "`n"

    Write-Host $WinSATTexto

}
else {

    Write-Host "WinSAT não está disponível neste Windows." `
        -ForegroundColor Yellow

    Adicionar-Aviso `
        "O WinSAT não está disponível para realizar o teste de leitura."
}


# ============================================================
# RESULTADO FINAL
# ============================================================

$Fim = Get-Date

$Duracao = New-TimeSpan `
    -Start $Inicio `
    -End $Fim

Write-Host ""
Write-Host ""

Write-Host "============================================================"

switch ($Resultado) {

    "NORMAL" {

        Write-Host "                 RESULTADO: NORMAL" `
            -ForegroundColor Green
    }

    "ATENÇÃO" {

        Write-Host "                 RESULTADO: ATENÇÃO" `
            -ForegroundColor Yellow
    }

    "CRÍTICO" {

        Write-Host "                 RESULTADO: CRÍTICO" `
            -ForegroundColor Red
    }
}

Write-Host "============================================================"
Write-Host ""


# ============================================================
# ALERTAS
# ============================================================

if ($Alertas.Count -gt 0) {

    Write-Host "INDICADORES ENCONTRADOS:" `
        -ForegroundColor Yellow

    foreach ($Alerta in $Alertas) {

        Write-Host ""
        Write-Host " ! $Alerta"
    }

}
else {

    Write-Host `
        "Nenhum indicador relevante foi identificado nos testes realizados." `
        -ForegroundColor Green
}


# ============================================================
# AVISOS
# ============================================================

if ($Avisos.Count -gt 0) {

    Write-Host ""
    Write-Host "OBSERVAÇÕES:" `
        -ForegroundColor Cyan

    foreach ($Aviso in $Avisos) {

        Write-Host ""
        Write-Host " - $Aviso"
    }
}


# ============================================================
# RECOMENDAÇÃO
# ============================================================

Write-Host ""
Write-Host "RECOMENDAÇÃO:" `
    -ForegroundColor Cyan

Write-Host ""

switch ($Resultado) {

    "NORMAL" {

        Write-Host `
            "Não foram encontrados indícios relevantes de falha nos testes realizados."

        Write-Host ""

        Write-Host `
            "Manter backup periódico dos dados."
    }

    "ATENÇÃO" {

        Write-Host `
            "Foram encontrados indicadores que merecem investigação."

        Write-Host ""

        Write-Host "Recomenda-se:"
        Write-Host "1. Fazer backup dos dados importantes."
        Write-Host "2. Investigar os indicadores apresentados."
        Write-Host "3. Repetir o diagnóstico se necessário."
        Write-Host "4. Considerar ferramenta específica do fabricante."
    }

    "CRÍTICO" {

        Write-Host `
            "Foram encontrados indicadores compatíveis com possível problema no armazenamento." `
            -ForegroundColor Red

        Write-Host ""

        Write-Host "RECOMENDAÇÃO IMEDIATA:"
        Write-Host "1. Fazer backup dos dados."
        Write-Host "2. Evitar operações desnecessárias no disco."
        Write-Host "3. Realizar diagnóstico aprofundado."
        Write-Host "4. Avaliar substituição do dispositivo."
    }
}


# ============================================================
# GERAR RELATÓRIO PDF
# ============================================================

Write-Host ""
Write-Host "============================================================"
Write-Host "GERAÇÃO DO RELATÓRIO" -ForegroundColor Cyan
Write-Host "============================================================"
Write-Host ""

$PastaRelatorios = "C:\ProgramData\LR Tecnologia\Relatorios"

if (-not (Test-Path $PastaRelatorios)) {

    New-Item `
        -ItemType Directory `
        -Path $PastaRelatorios `
        -Force | Out-Null
}

$DataArquivo = Get-Date -Format "yyyyMMdd_HHmmss"

$NomeBase = "Diagnostico_Disco_$DataArquivo"

$CaminhoPDF = Join-Path `
    $PastaRelatorios `
    "$NomeBase.pdf"

$CaminhoHTML = Join-Path `
    $env:TEMP `
    "$NomeBase.html"


# ============================================================
# PREPARAR HTML
# ============================================================

$ClasseResultado = switch ($Resultado) {

    "NORMAL" { "normal" }
    "ATENÇÃO" { "atencao" }
    "CRÍTICO" { "critico" }
    default { "normal" }
}


$HTMLDiscos = ""

foreach ($D in $DadosDiscos) {

    $HTMLDiscos += @"
<div class="disk">
    <h2>$(Html $D.Modelo)</h2>

    <table>
        <tr><th>Tipo</th><td>$(Html $D.Tipo)</td></tr>
        <tr><th>Fabricante</th><td>$(Html $D.Fabricante)</td></tr>
        <tr><th>Número de série</th><td>$(Html $D.Serial)</td></tr>
        <tr><th>Barramento</th><td>$(Html $D.Barramento)</td></tr>
        <tr><th>Capacidade</th><td>$(Html $D.Capacidade)</td></tr>
        <tr><th>HealthStatus</th><td>$(Html $D.HealthStatus)</td></tr>
        <tr><th>OperationalStatus</th><td>$(Html $D.OperationalStatus)</td></tr>
        <tr><th>Temperatura</th><td>$(Html $D.Temperatura)</td></tr>
        <tr><th>Horas de uso</th><td>$(Html $D.HorasUso)</td></tr>
        <tr><th>Desgaste</th><td>$(Html $D.Desgaste)</td></tr>
        <tr><th>Erros de leitura</th><td>$(Html $D.ErrosLeitura)</td></tr>
        <tr><th>Erros de gravação</th><td>$(Html $D.ErrosGravacao)</td></tr>
        <tr><th>Latência máxima leitura</th><td>$(Html $D.LatenciaLeitura)</td></tr>
        <tr><th>Latência máxima gravação</th><td>$(Html $D.LatenciaGravacao)</td></tr>
    </table>
</div>
"@
}


$HTMLAlertas = ""

if ($Alertas.Count -gt 0) {

    foreach ($Alerta in $Alertas) {

        $HTMLAlertas += "<li>$(Html $Alerta)</li>"
    }

}
else {

    $HTMLAlertas = "<li>Nenhum indicador relevante identificado.</li>"
}


$HTMLAvisos = ""

if ($Avisos.Count -gt 0) {

    foreach ($Aviso in $Avisos) {

        $HTMLAvisos += "<li>$(Html $Aviso)</li>"
    }

}
else {

    $HTMLAvisos = "<li>Nenhuma observação adicional.</li>"
}


$HTMLEventos = ""

if ($EventosResumo.Count -gt 0) {

    foreach ($Evento in $EventosResumo) {

        $MensagemEvento = [string]$Evento.Mensagem

        if ($MensagemEvento.Length -gt 500) {
            $MensagemEvento = $MensagemEvento.Substring(0,500) + "..."
        }

        $HTMLEventos += @"
<tr>
    <td>$(Html $Evento.Data)</td>
    <td>$(Html $Evento.Origem)</td>
    <td>$(Html $Evento.ID)</td>
    <td>$(Html $MensagemEvento)</td>
</tr>
"@
    }

}
else {

    $HTMLEventos = @"
<tr>
    <td colspan="4">Nenhum erro crítico de armazenamento encontrado nos últimos 7 dias.</td>
</tr>
"@
}


$WinSATResumo = $WinSATTexto

if ([string]::IsNullOrWhiteSpace($WinSATResumo)) {

    $WinSATResumo = "Teste de leitura não disponível."
}

if ($WinSATResumo.Length -gt 8000) {

    $WinSATResumo = $WinSATResumo.Substring(0,8000) + "`r`n..."
}


$HTML = @"
<!DOCTYPE html>

<html lang="pt-BR">

<head>

<meta charset="UTF-8">

<title>Diagnóstico de Armazenamento - LR Tecnologia</title>

<style>

@page {
    size: A4;
    margin: 15mm;
}

body {
    font-family: Arial, Helvetica, sans-serif;
    color: #222;
    font-size: 11px;
    line-height: 1.4;
}

.header {
    border-bottom: 3px solid #1e73be;
    padding-bottom: 12px;
    margin-bottom: 18px;
}

.logo {
    font-size: 22px;
    font-weight: bold;
    color: #1e73be;
}

.subtitulo {
    font-size: 13px;
    color: #555;
}

.info {
    width: 100%;
    border-collapse: collapse;
    margin-bottom: 20px;
}

.info td {
    padding: 5px 7px;
    border-bottom: 1px solid #ddd;
}

.info td:first-child {
    font-weight: bold;
    width: 160px;
}

.resultado {
    padding: 14px;
    text-align: center;
    font-size: 22px;
    font-weight: bold;
    margin: 15px 0 25px 0;
    border-radius: 5px;
}

.normal {
    background: #e8f5e9;
    color: #2e7d32;
    border: 1px solid #81c784;
}

.atencao {
    background: #fff8e1;
    color: #f57f17;
    border: 1px solid #ffcc80;
}

.critico {
    background: #ffebee;
    color: #c62828;
    border: 1px solid #ef9a9a;
}

h1 {
    font-size: 17px;
    color: #1e73be;
    border-bottom: 1px solid #ccc;
    padding-bottom: 5px;
    margin-top: 25px;
}

h2 {
    font-size: 14px;
    color: #333;
    margin-bottom: 8px;
}

.disk {
    page-break-inside: avoid;
    margin-bottom: 20px;
}

table {
    width: 100%;
    border-collapse: collapse;
}

th {
    background: #f1f1f1;
    text-align: left;
    font-weight: bold;
}

th, td {
    border: 1px solid #d5d5d5;
    padding: 6px;
    vertical-align: top;
}

.disk table th {
    width: 220px;
}

.alertas li {
    margin-bottom: 7px;
}

.avisos li {
    margin-bottom: 7px;
}

pre {
    background: #f5f5f5;
    border: 1px solid #ddd;
    padding: 10px;
    white-space: pre-wrap;
    word-wrap: break-word;
    font-family: Consolas, monospace;
    font-size: 8px;
}

.footer {
    margin-top: 30px;
    border-top: 1px solid #ccc;
    padding-top: 10px;
    color: #666;
    font-size: 9px;
}

</style>

</head>

<body>

<div class="header">

    <div class="logo">
        LR TECNOLOGIA
    </div>

    <div class="subtitulo">
        Seattle — Teste e Diagnóstico de Armazenamento
    </div>

</div>


<table class="info">

<tr>
    <td>Computador</td>
    <td>$(Html $env:COMPUTERNAME)</td>
</tr>

<tr>
    <td>Usuário</td>
    <td>$(Html $env:USERNAME)</td>
</tr>

<tr>
    <td>Windows</td>
    <td>$(Html ([System.Environment]::OSVersion.Version))</td>
</tr>

<tr>
    <td>Data do diagnóstico</td>
    <td>$(Html $DataHoraInicio)</td>
</tr>

<tr>
    <td>Unidade analisada</td>
    <td>C:</td>
</tr>

<tr>
    <td>Capacidade C:</td>
    <td>$EspacoTotal GB</td>
</tr>

<tr>
    <td>Espaço livre</td>
    <td>$EspacoLivre GB ($PercentualLivre%)</td>
</tr>

<tr>
    <td>Tempo do diagnóstico</td>
    <td>$($Duracao.Minutes) min $($Duracao.Seconds) s</td>
</tr>

</table>


<div class="resultado $ClasseResultado">

RESULTADO: $(Html $Resultado)

</div>


<h1>1. Discos físicos</h1>

$HTMLDiscos


<h1>2. Indicadores encontrados</h1>

<ul class="alertas">

$HTMLAlertas

</ul>


<h1>3. Observações</h1>

<ul class="avisos">

$HTMLAvisos

</ul>


<h1>4. Verificação do sistema de arquivos</h1>

<p>
<strong>CHKDSK /SCAN — unidade C:</strong>
</p>

<pre>$(Html $ChkDiskTexto)</pre>


<h1>5. Eventos de armazenamento</h1>

<table>

<tr>
    <th>Data</th>
    <th>Origem</th>
    <th>ID</th>
    <th>Mensagem</th>
</tr>

$HTMLEventos

</table>


<h1>6. Teste de leitura</h1>

<p>
O teste de desempenho foi realizado somente com operações de leitura.
Nenhum arquivo temporário foi criado para benchmark.
</p>

<pre>$(Html $WinSATResumo)</pre>


<h1>7. Recomendação técnica</h1>

$(switch ($Resultado) {

    "NORMAL" {
        @"
<p>
Não foram encontrados indícios relevantes de falha nos testes realizados.
</p>

<p>
<strong>Recomendação:</strong> manter backup periódico dos dados.
</p>
"@
    }

    "ATENÇÃO" {
        @"
<p>
Foram encontrados indicadores que merecem investigação.
</p>

<ul>
    <li>Realizar backup dos dados importantes.</li>
    <li>Investigar os indicadores apresentados.</li>
    <li>Repetir o diagnóstico quando necessário.</li>
    <li>Considerar ferramenta específica do fabricante.</li>
</ul>
"@
    }

    "CRÍTICO" {
        @"
<p>
Foram encontrados indicadores compatíveis com possível problema no armazenamento.
</p>

<p><strong>Recomendação imediata:</strong></p>

<ol>
    <li>Fazer backup dos dados.</li>
    <li>Evitar operações desnecessárias no disco.</li>
    <li>Realizar diagnóstico aprofundado.</li>
    <li>Avaliar substituição do dispositivo.</li>
</ol>
"@
    }
})


<div class="footer">

    <strong>LR Tecnologia</strong><br>

    Seattle — Diagnóstico de armazenamento<br>

    Desenvolvido por Leonardo M. Batista<br><br>

    Este diagnóstico não garante que o dispositivo não irá falhar.
    Ele avalia os indicadores disponibilizados pelo Windows e pelo
    dispositivo durante os testes realizados.

</div>


</body>

</html>
"@


# ============================================================
# GRAVAR HTML TEMPORÁRIO
# ============================================================

try {

    [System.IO.File]::WriteAllText(
        $CaminhoHTML,
        $HTML,
        [System.Text.UTF8Encoding]::new($false)
    )

}
catch {

    Write-Host ""
    Write-Host "Não foi possível criar o relatório temporário." `
        -ForegroundColor Red

    Adicionar-Alerta `
        "Falha na criação do relatório local."

    $CaminhoHTML = $null
}


# ============================================================
# GERAR PDF
# ============================================================

$PDFGerado = $false

if ($CaminhoHTML) {

    $PDFGerado = Gerar-PDF `
        -CaminhoPDF $CaminhoPDF `
        -CaminhoHTML $CaminhoHTML
}


# ============================================================
# REMOVER HTML TEMPORÁRIO
# ============================================================

if ($PDFGerado -and (Test-Path $CaminhoHTML)) {

    Remove-Item `
        $CaminhoHTML `
        -Force `
        -ErrorAction SilentlyContinue
}


# ============================================================
# RESULTADO DO RELATÓRIO
# ============================================================

Write-Host ""

if ($PDFGerado) {

    Write-Host "RELATÓRIO PDF GERADO COM SUCESSO" `
        -ForegroundColor Green

    Write-Host ""
    Write-Host "Arquivo:"
    Write-Host $CaminhoPDF

}
else {

    Write-Host "Não foi possível gerar o PDF automaticamente." `
        -ForegroundColor Yellow

    if ($CaminhoHTML -and (Test-Path $CaminhoHTML)) {

        Write-Host ""
        Write-Host "Relatório HTML disponível em:"
        Write-Host $CaminhoHTML
    }
}


# ============================================================
# FINAL
# ============================================================

Write-Host ""
Write-Host "============================================================"

Write-Host "Diagnóstico concluído."

Write-Host `
    "Tempo total: $($Duracao.Minutes) min $($Duracao.Seconds) s"

Write-Host "============================================================"

Write-Host ""

Write-Host "IMPORTANTE:"

Write-Host `
    "Este diagnóstico não garante que o disco não irá falhar."

Write-Host `
    "Ele avalia somente os indicadores disponibilizados pelo"

Write-Host `
    "Windows e pelo dispositivo durante este teste."

Write-Host ""

pause
