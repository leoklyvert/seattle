# ============================================================
# SEATTLE - LR TECNOLOGIA
# ============================================================
# Módulo: Diagnóstico Preventivo
# Versão: 2.1.0
#
# SOMENTE LEITURA
#
# O diagnóstico coleta informações técnicas do computador.
# Não solicita cadastro ou identificação de cliente.
#
# O inventário é enviado para a HostGator.
# O relatório PDF é gerado LOCALMENTE.
# ============================================================

$ErrorActionPreference = "SilentlyContinue"


# ============================================================
# CONFIGURAÇÃO
# ============================================================

$UrlServidor = "https://lrtecnologia.net.br/seattle/receber_inventario.php"

# MANTENHA A MESMA CHAVE QUE JÁ ESTÁ NO SEU ARQUIVO ATUAL.
$ChaveSeattle = "COLOQUE_AQUI_A_MESMA_CHAVE_DO_ARQUIVO_ATUAL"

# Pasta dos relatórios
$PastaRelatorios = "C:\ProgramData\LR Tecnologia\Relatorios"


# ============================================================
# PREPARAÇÃO DA PASTA DE RELATÓRIOS
# ============================================================

try {

    if (-not (Test-Path $PastaRelatorios)) {

        New-Item `
            -Path $PastaRelatorios `
            -ItemType Directory `
            -Force |
            Out-Null
    }

}
catch {}


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

        default {
            return "Desconhecido"
        }
    }
}


function Pausar-Diagnostico {

    Write-Host ""
    Write-Host "Pressione qualquer tecla para continuar..." -ForegroundColor Gray

    try {
        [System.Console]::ReadKey($true) | Out-Null
    }
    catch {
        Read-Host "Pressione ENTER para continuar" | Out-Null
    }
}


# ============================================================
# ESCAPAR TEXTO PARA HTML
# ============================================================

function Html {

    param(
        [AllowNull()]
        $Texto
    )

    if ($null -eq $Texto) {

        return ""
    }

    try {

        return [System.Net.WebUtility]::HtmlEncode(
            [string]$Texto
        )

    }
    catch {

        return [System.Security.SecurityElement]::Escape(
            [string]$Texto
        )
    }
}


# ============================================================
# LOCALIZAR CHROME OU EDGE
# ============================================================

function Obter-CaminhoNavegador {

    $Candidatos = @(

        "$env:ProgramFiles\Google\Chrome\Application\chrome.exe"

        "$env:ProgramFiles(x86)\Google\Chrome\Application\chrome.exe"

        "$env:ProgramFiles\Microsoft\Edge\Application\msedge.exe"

        "$env:ProgramFiles(x86)\Microsoft\Edge\Application\msedge.exe"

        "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"

        "$env:LOCALAPPDATA\Microsoft\Edge\Application\msedge.exe"
    )

    foreach ($Caminho in $Candidatos) {

        if (
            $Caminho -and
            (Test-Path $Caminho)
        ) {

            return $Caminho
        }
    }

    return $null
}


# ============================================================
# GERAR PDF
# ============================================================

function Gerar-PDF {

    param(
        $Objeto,
        [string]$CaminhoPDF
    )


    # --------------------------------------------------------
    # LOCALIZAR NAVEGADOR
    # --------------------------------------------------------

    $Navegador = Obter-CaminhoNavegador

    if (-not $Navegador) {

        throw "Google Chrome ou Microsoft Edge não foi encontrado neste computador."
    }


    # --------------------------------------------------------
    # ALERTAS
    # --------------------------------------------------------

    $HtmlAlertas = ""

    if (
        $null -ne $Objeto.alertas -and
        $Objeto.alertas.Count -gt 0
    ) {

        foreach ($Alerta in $Objeto.alertas) {

            $HtmlAlertas += @"
<div class="alerta">
    <strong>ATENÇÃO</strong><br>
    $(Html $Alerta)
</div>
"@
        }

    }
    else {

        $HtmlAlertas = @"
<div class="ok">
    <strong>NORMAL</strong><br>
    Nenhum alerta preventivo identificado.
</div>
"@
    }


    # --------------------------------------------------------
    # MÓDULOS DE MEMÓRIA
    # --------------------------------------------------------

    $HtmlRAM = ""

    if (
        $null -ne $Objeto.memoria.modulos -and
        $Objeto.memoria.modulos.Count -gt 0
    ) {

        foreach ($RAM in $Objeto.memoria.modulos) {

            $HtmlRAM += @"
<tr>
    <td>$(Html $RAM.Slot)</td>
    <td>$(Html $RAM.Fabricante)</td>
    <td>$(Html $RAM.NumeroSerie)</td>
    <td>$($RAM.CapacidadeGB) GB</td>
    <td>$($RAM.VelocidadeMHz) MHz</td>
    <td>$(Html $RAM.Tipo)</td>
</tr>
"@
        }

    }
    else {

        $HtmlRAM = @"
<tr>
    <td colspan="6">Informações dos módulos de memória não disponíveis.</td>
</tr>
"@
    }


    # --------------------------------------------------------
    # DISCOS FÍSICOS
    # --------------------------------------------------------

    $HtmlDiscos = ""

    if (
        $null -ne $Objeto.armazenamento.discos_fisicos -and
        $Objeto.armazenamento.discos_fisicos.Count -gt 0
    ) {

        foreach ($Disco in $Objeto.armazenamento.discos_fisicos) {

            $Vida = "N/D"

            if ($null -ne $Disco.VidaRestantePct) {

                $Vida = "$($Disco.VidaRestantePct)%"
            }

            $Temperatura = "N/D"

            if ($null -ne $Disco.TemperaturaC) {

                $Temperatura = "$($Disco.TemperaturaC) °C"
            }

            $HtmlDiscos += @"
<tr>
    <td>$(Html $Disco.Modelo)</td>
    <td>$(Html $Disco.Tipo)</td>
    <td>$(Html $Disco.Interface)</td>
    <td>$($Disco.CapacidadeGB) GB</td>
    <td>$(Html $Disco.SaudeStatus)</td>
    <td>$Vida</td>
    <td>$Temperatura</td>
</tr>
"@
        }

    }
    else {

        $HtmlDiscos = @"
<tr>
    <td colspan="7">Nenhum disco físico identificado.</td>
</tr>
"@
    }


    # --------------------------------------------------------
    # UNIDADES LÓGICAS
    # --------------------------------------------------------

    $HtmlUnidades = ""

    if (
        $null -ne $Objeto.armazenamento.unidades -and
        $Objeto.armazenamento.unidades.Count -gt 0
    ) {

        foreach ($Disco in $Objeto.armazenamento.unidades) {

            $HtmlUnidades += @"
<tr>
    <td>$(Html $Disco.Unidade)</td>
    <td>$($Disco.TamanhoGB) GB</td>
    <td>$($Disco.LivreGB) GB</td>
    <td>$($Disco.Uso)%</td>
</tr>
"@
        }

    }
    else {

        $HtmlUnidades = @"
<tr>
    <td colspan="4">Nenhuma unidade lógica identificada.</td>
</tr>
"@
    }


    # --------------------------------------------------------
    # PROGRAMAS DE INICIALIZAÇÃO
    # --------------------------------------------------------

    $HtmlInicializacao = ""

    if (
        $null -ne $Objeto.inicializacao.programas -and
        $Objeto.inicializacao.programas.Count -gt 0
    ) {

        foreach ($Programa in $Objeto.inicializacao.programas) {

            $HtmlInicializacao += @"
<tr>
    <td>$(Html $Programa.Name)</td>
    <td>$(Html $Programa.Command)</td>
</tr>
"@
        }

    }
    else {

        $HtmlInicializacao = @"
<tr>
    <td colspan="2">Nenhum programa de inicialização identificado.</td>
</tr>
"@
    }


    # --------------------------------------------------------
    # PROCESSOS
    # --------------------------------------------------------

    $HtmlProcessos = ""

    if (
        $null -ne $Objeto.processos -and
        $Objeto.processos.Count -gt 0
    ) {

        foreach ($Processo in $Objeto.processos) {

            $HtmlProcessos += @"
<tr>
    <td>$(Html $Processo.Processo)</td>
    <td>$($Processo.MemoriaMB) MB</td>
</tr>
"@
        }

    }
    else {

        $HtmlProcessos = @"
<tr>
    <td colspan="2">Informações de processos não disponíveis.</td>
</tr>
"@
    }


    # --------------------------------------------------------
    # EVENTOS
    # --------------------------------------------------------

    $HtmlEventos = ""

    if (
        $null -ne $Objeto.eventos -and
        $Objeto.eventos.Count -gt 0
    ) {

        foreach ($Evento in $Objeto.eventos) {

            $DataEvento = ""

            if ($Evento.Data) {

                try {

                    $DataEvento =
                        ([datetime]$Evento.Data).ToString(
                            "dd/MM/yyyy HH:mm:ss"
                        )

                }
                catch {

                    $DataEvento =
                        [string]$Evento.Data
                }
            }

            $HtmlEventos += @"
<tr>
    <td>$(Html $DataEvento)</td>
    <td>$($Evento.ID)</td>
    <td>$(Html $Evento.Origem)</td>
</tr>
"@
        }

    }
    else {

        $HtmlEventos = @"
<tr>
    <td colspan="3">Nenhum evento crítico ou erro recente encontrado.</td>
</tr>
"@
    }


    # --------------------------------------------------------
    # TEMPO LIGADO
    # --------------------------------------------------------

    $TempoLigadoTexto = "Não disponível"

    if (
        $null -ne $Objeto.sistema.tempo_ligado_horas
    ) {

        $TempoLigadoTexto =
            "$($Objeto.sistema.tempo_ligado_horas) horas"
    }


    # --------------------------------------------------------
    # HTML DO RELATÓRIO
    # --------------------------------------------------------

    $HtmlRelatorio = @"
<!DOCTYPE html>

<html lang="pt-BR">

<head>

<meta charset="UTF-8">

<title>Diagnóstico Preventivo - LR Tecnologia</title>

<style>

@page {
    size: A4;
    margin: 15mm;
}

* {
    box-sizing: border-box;
}

body {
    font-family: Arial, Helvetica, sans-serif;
    color: #222;
    font-size: 10pt;
    margin: 0;
}

h1 {
    font-size: 22pt;
    margin: 0 0 4px 0;
}

h2 {
    font-size: 14pt;
    margin-top: 24px;
    margin-bottom: 10px;
    border-bottom: 2px solid #222;
    padding-bottom: 5px;
}

h3 {
    font-size: 11pt;
    margin-top: 18px;
}

.cabecalho {
    border-bottom: 3px solid #222;
    padding-bottom: 12px;
    margin-bottom: 18px;
}

.subtitulo {
    color: #666;
    font-size: 9pt;
}

.grid {
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 8px;
}

.card {
    border: 1px solid #ccc;
    padding: 9px;
    border-radius: 4px;
}

.label {
    color: #666;
    font-size: 8pt;
    margin-bottom: 3px;
}

.valor {
    font-size: 10pt;
    font-weight: bold;
    word-break: break-word;
}

table {
    width: 100%;
    border-collapse: collapse;
    margin-top: 8px;
    font-size: 8pt;
}

th {
    background: #eeeeee;
    text-align: left;
    font-weight: bold;
}

th,
td {
    border: 1px solid #ccc;
    padding: 5px;
    vertical-align: top;
    word-break: break-word;
}

.ok {
    border: 1px solid #198754;
    padding: 10px;
    margin: 8px 0;
    background: #f4fff8;
}

.alerta {
    border: 1px solid #dc3545;
    padding: 10px;
    margin: 8px 0;
    background: #fff5f5;
}

.pequeno {
    font-size: 8pt;
    color: #666;
}

.page-break {
    page-break-before: always;
}

.nao-quebrar {
    page-break-inside: avoid;
}

</style>

</head>

<body>

<div class="cabecalho">

<h1>LR Tecnologia</h1>

<div>
<strong>Diagnóstico Preventivo</strong>
</div>

<div class="subtitulo">
Relatório técnico gerado automaticamente pelo Seattle
</div>

<div class="subtitulo">
Data do diagnóstico: $(Html $Objeto.data)
</div>

</div>


<!-- ===================================================== -->
<!-- IDENTIFICAÇÃO -->
<!-- ===================================================== -->

<h2>Identificação do equipamento</h2>

<div class="grid">

<div class="card">
<div class="label">Computador</div>
<div class="valor">$(Html $Objeto.computador)</div>
</div>

<div class="card">
<div class="label">Usuário</div>
<div class="valor">$(Html $Objeto.usuario)</div>
</div>

<div class="card">
<div class="label">Fabricante</div>
<div class="valor">$(Html $Objeto.sistema.fabricante)</div>
</div>

<div class="card">
<div class="label">Modelo</div>
<div class="valor">$(Html $Objeto.sistema.modelo)</div>
</div>

<div class="card">
<div class="label">Número de série</div>
<div class="valor">$(Html $Objeto.sistema.serial)</div>
</div>

<div class="card">
<div class="label">Windows</div>
<div class="valor">$(Html $Objeto.sistema.windows)</div>
</div>

<div class="card">
<div class="label">Build</div>
<div class="valor">$(Html $Objeto.sistema.build)</div>
</div>

<div class="card">
<div class="label">Tempo ligado</div>
<div class="valor">$(Html $TempoLigadoTexto)</div>
</div>

</div>


<!-- ===================================================== -->
<!-- PROCESSADOR -->
<!-- ===================================================== -->

<h2>Processador</h2>

<div class="grid">

<div class="card">
<div class="label">Modelo</div>
<div class="valor">$(Html $Objeto.processador.modelo)</div>
</div>

<div class="card">
<div class="label">Uso no momento do diagnóstico</div>
<div class="valor">$($Objeto.processador.uso_percentual)%</div>
</div>

<div class="card">
<div class="label">Núcleos</div>
<div class="valor">$($Objeto.processador.nucleos)</div>
</div>

<div class="card">
<div class="label">Threads</div>
<div class="valor">$($Objeto.processador.threads)</div>
</div>

</div>


<!-- ===================================================== -->
<!-- MEMÓRIA -->
<!-- ===================================================== -->

<h2>Memória RAM</h2>

<div class="grid">

<div class="card">
<div class="label">Memória total</div>
<div class="valor">$($Objeto.memoria.total_gb) GB</div>
</div>

<div class="card">
<div class="label">Memória livre</div>
<div class="valor">$($Objeto.memoria.livre_gb) GB</div>
</div>

<div class="card">
<div class="label">Uso atual</div>
<div class="valor">$($Objeto.memoria.uso_percentual)%</div>
</div>

<div class="card">
<div class="label">Módulos encontrados</div>
<div class="valor">$($Objeto.memoria.modulos.Count)</div>
</div>

</div>

<h3>Módulos instalados</h3>

<table>

<tr>
<th>Slot</th>
<th>Fabricante</th>
<th>Serial</th>
<th>Capacidade</th>
<th>Velocidade</th>
<th>Tipo</th>
</tr>

$HtmlRAM

</table>


<!-- ===================================================== -->
<!-- ARMAZENAMENTO -->
<!-- ===================================================== -->

<h2>Armazenamento</h2>

<h3>Discos físicos</h3>

<table>

<tr>
<th>Modelo</th>
<th>Tipo</th>
<th>Interface</th>
<th>Capacidade</th>
<th>Saúde</th>
<th>Vida restante</th>
<th>Temperatura</th>
</tr>

$HtmlDiscos

</table>


<h3>Unidades lógicas</h3>

<table>

<tr>
<th>Unidade</th>
<th>Tamanho</th>
<th>Livre</th>
<th>Uso</th>
</tr>

$HtmlUnidades

</table>


<!-- ===================================================== -->
<!-- ALERTAS -->
<!-- ===================================================== -->

<h2>Análise preventiva</h2>

$HtmlAlertas


<div class="page-break"></div>


<!-- ===================================================== -->
<!-- INICIALIZAÇÃO -->
<!-- ===================================================== -->

<h2>Programas de inicialização</h2>

<p>
Quantidade identificada:
<strong>$($Objeto.inicializacao.quantidade)</strong>
</p>

<table>

<tr>
<th>Programa</th>
<th>Comando</th>
</tr>

$HtmlInicializacao

</table>


<!-- ===================================================== -->
<!-- PROCESSOS -->
<!-- ===================================================== -->

<h2>Processos com maior consumo de memória</h2>

<table>

<tr>
<th>Processo</th>
<th>Memória</th>
</tr>

$HtmlProcessos

</table>


<!-- ===================================================== -->
<!-- EVENTOS -->
<!-- ===================================================== -->

<h2>Eventos críticos e erros recentes</h2>

<table>

<tr>
<th>Data</th>
<th>ID</th>
<th>Origem</th>
</tr>

$HtmlEventos

</table>


<!-- ===================================================== -->
<!-- RODAPÉ -->
<!-- ===================================================== -->

<h2>Observações</h2>

<p>
Este relatório foi gerado automaticamente pelo módulo
<strong>Diagnóstico Preventivo</strong> do Seattle - LR Tecnologia.
</p>

<p>
O diagnóstico é realizado em modo de somente leitura.
Nenhuma configuração do Windows, programa ou arquivo pessoal
é alterado pelo módulo.
</p>

<p class="pequeno">
Relatório técnico para uso da LR Tecnologia.
</p>

</body>

</html>
"@


    # --------------------------------------------------------
    # ARQUIVO HTML TEMPORÁRIO
    # --------------------------------------------------------

    $NomeBase =
        [System.IO.Path]::GetFileNameWithoutExtension(
            $CaminhoPDF
        )

    $CaminhoHTML =
        Join-Path `
            $env:TEMP `
            "$NomeBase.html"


    try {

        $UTF8SemBOM =
            New-Object System.Text.UTF8Encoding(
                $false
            )

        [System.IO.File]::WriteAllText(
            $CaminhoHTML,
            $HtmlRelatorio,
            $UTF8SemBOM
        )

    }
    catch {

        throw "Não foi possível criar o relatório HTML temporário: $($_.Exception.Message)"
    }


    # --------------------------------------------------------
    # REMOVER PDF ANTERIOR
    # --------------------------------------------------------

    if (Test-Path $CaminhoPDF) {

        Remove-Item `
            $CaminhoPDF `
            -Force `
            -ErrorAction SilentlyContinue
    }


    # --------------------------------------------------------
    # CONVERTER HTML PARA PDF
    # --------------------------------------------------------

    $ArquivoHTMLSeguro =
        $CaminhoHTML.Replace("\", "/")

    $ArquivoPDFSeguro =
        $CaminhoPDF.Replace("\", "/")

    $Argumentos = @(
        "--headless"
        "--disable-gpu"
        "--no-sandbox"
        "--no-pdf-header-footer"
        "--print-to-pdf=$ArquivoPDFSeguro"
        "file:///$ArquivoHTMLSeguro"
    )


    try {

        $ProcessoPDF =
            Start-Process `
                -FilePath $Navegador `
                -ArgumentList $Argumentos `
                -Wait `
                -PassThru `
                -WindowStyle Hidden

    }
    catch {

        Remove-Item `
            $CaminhoHTML `
            -Force `
            -ErrorAction SilentlyContinue

        throw "Não foi possível executar o navegador para gerar o PDF: $($_.Exception.Message)"
    }


    # --------------------------------------------------------
    # AGUARDAR ARQUIVO
    # --------------------------------------------------------

    $Tentativas = 0

    while (
        -not (Test-Path $CaminhoPDF) -and
        $Tentativas -lt 20
    ) {

        Start-Sleep -Milliseconds 500

        $Tentativas++
    }


    # --------------------------------------------------------
    # VALIDAR PDF
    # --------------------------------------------------------

    if (-not (Test-Path $CaminhoPDF)) {

        Remove-Item `
            $CaminhoHTML `
            -Force `
            -ErrorAction SilentlyContinue

        throw "O navegador foi executado, mas o arquivo PDF não foi criado."
    }


    try {

        $TamanhoPDF =
            (Get-Item $CaminhoPDF).Length

        if ($TamanhoPDF -lt 1000) {

            throw "O arquivo PDF foi criado, mas possui tamanho inválido."
        }

    }
    catch {

        Remove-Item `
            $CaminhoHTML `
            -Force `
            -ErrorAction SilentlyContinue

        throw $_
    }


    # --------------------------------------------------------
    # LIMPAR HTML TEMPORÁRIO
    # --------------------------------------------------------

    Remove-Item `
        $CaminhoHTML `
        -Force `
        -ErrorAction SilentlyContinue


    return $true
}


# ============================================================
# CABEÇALHO
# ============================================================

Clear-Host

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "              ROBÔ LR TECNOLOGIA" -ForegroundColor Cyan
Write-Host "          DIAGNÓSTICO PREVENTIVO v2.1.0" -ForegroundColor Cyan
Write-Host ""
Write-Host "                  SOMENTE LEITURA" -ForegroundColor Yellow
Write-Host "       Não altera configurações do computador" -ForegroundColor Gray
Write-Host "       Não remove programas" -ForegroundColor Gray
Write-Host "       Gera relatório técnico em PDF" -ForegroundColor Gray
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""


# ============================================================
# IDENTIFICAÇÃO
# ============================================================

Write-Host "[1/6] Coletando identificação..." -ForegroundColor Cyan

$Sistema =
    Get-CimInstance Win32_ComputerSystem

$BIOS =
    Get-CimInstance Win32_BIOS

$SO =
    Get-CimInstance Win32_OperatingSystem

$Computador =
    $env:COMPUTERNAME

$Usuario =
    $env:USERNAME

$Fabricante =
    $Sistema.Manufacturer

$Modelo =
    $Sistema.Model

$Serial =
    $BIOS.SerialNumber


# ============================================================
# WINDOWS
# ============================================================

Write-Host "[2/6] Coletando informações do Windows..." -ForegroundColor Cyan

$Windows =
    Get-ItemProperty `
        "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion"

$VersaoWindows =
    "$($Windows.ProductName) $($Windows.DisplayVersion)"

$BuildWindows =
    $Windows.CurrentBuild

$UBRWindows =
    $Windows.UBR


# ============================================================
# TEMPO LIGADO
# ============================================================

$Boot = $null
$TempoLigado = $null

try {

    $ValorBoot =
        $SO.LastBootUpTime

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

        $Boot =
            $ValorBoot
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

$CPU =
    $CPUInfo.Name

$Nucleos =
    $CPUInfo.NumberOfCores

$Threads =
    $CPUInfo.NumberOfLogicalProcessors

$UsoCPU = 0

try {

    $ContadorCPU =
        Get-Counter `
            "\Processor(_Total)\% Processor Time" `
            -SampleInterval 1 `
            -MaxSamples 2

    $AmostraCPU =
        $ContadorCPU.CounterSamples |
        Select-Object -Last 1

    if ($AmostraCPU) {

        $UsoCPU =
            [math]::Round(
                $AmostraCPU.CookedValue,
                1
            )
    }

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

$RAMUso = 0

if (
    $SO.TotalVisibleMemorySize -gt 0
) {

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
}

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

                if (
                    $null -ne $Contador.Wear
                ) {

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

                Tipo =
                    $null

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

                VidaRestantePct =
                    $null

                TemperaturaC =
                    $null
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

    if (
        $D.Size -gt 0
    ) {

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


if (
    $RAMUso -gt 80
) {

    $Alertas +=
        "Uso elevado de memória RAM."
}


if (
    $UsoCPU -gt 80
) {

    $Alertas +=
        "Uso elevado de CPU."
}


foreach ($D in $Discos) {

    if (
        $D.Uso -gt 85
    ) {

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
# GERAR RELATÓRIO PDF
# ============================================================

Write-Host ""
Write-Host "Gerando relatório PDF..." -ForegroundColor Yellow

$DataArquivo =
    Get-Date -Format "yyyyMMdd_HHmmss"

$CaminhoPDF =
    Join-Path `
        $PastaRelatorios `
        "Diagnostico_Preventivo_$DataArquivo.pdf"

$StatusPDF =
    "NÃO GERADO"


try {

    Gerar-PDF `
        -Objeto $Objeto `
        -CaminhoPDF $CaminhoPDF |
        Out-Null

    $StatusPDF =
        "GERADO"

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host "             RELATÓRIO PDF GERADO" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Arquivo:" -NoNewline
    Write-Host " $CaminhoPDF" -ForegroundColor Cyan

}
catch {

    $StatusPDF =
        "ERRO"

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host "          FALHA AO GERAR RELATÓRIO PDF" -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host $_.Exception.Message -ForegroundColor Red
}


# ============================================================
# ENVIO PARA O SERVIDOR
# ============================================================

Write-Host ""
Write-Host "Enviando inventário para LR Tecnologia..." -ForegroundColor Yellow
Write-Host ""

$StatusServidor =
    "NÃO TESTADO"


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


    if (
        $Resposta.sucesso -eq $true
    ) {

        $StatusServidor =
            "OK"

        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Green
        Write-Host "       INVENTÁRIO ENVIADO COM SUCESSO!" -ForegroundColor Green
        Write-Host "============================================================" -ForegroundColor Green

    }
    else {

        $StatusServidor =
            "RECUSADO"

        Write-Host ""
        Write-Host "O servidor recusou o inventário." -ForegroundColor Red

        if ($Resposta.mensagem) {

            Write-Host `
                $Resposta.mensagem `
                -ForegroundColor Red
        }
    }

}
catch {

    $StatusServidor =
        "OFFLINE"

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host "        FALHA NO ENVIO DO INVENTÁRIO" -ForegroundColor Red
    Write-Host "============================================================" -ForegroundColor Red
    Write-Host ""

    Write-Host `
        $_.Exception.Message `
        -ForegroundColor Red

    Write-Host ""
    Write-Host "O relatório PDF local não foi afetado pelo erro do servidor." -ForegroundColor Yellow
}


# ============================================================
# RESUMO
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "                 DIAGNÓSTICO FINALIZADO" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Computador : " -NoNewline
Write-Host `
    $Computador `
    -ForegroundColor Yellow

Write-Host "Usuário    : " -NoNewline
Write-Host `
    $Usuario `
    -ForegroundColor Yellow

Write-Host "Fabricante : " -NoNewline
Write-Host `
    $Fabricante `
    -ForegroundColor Yellow

Write-Host "Modelo     : " -NoNewline
Write-Host `
    $Modelo `
    -ForegroundColor Yellow

Write-Host "Windows    : " -NoNewline
Write-Host `
    $VersaoWindows `
    -ForegroundColor Yellow

Write-Host "CPU        : " -NoNewline
Write-Host `
    "$UsoCPU %" `
    -ForegroundColor Yellow

Write-Host "RAM        : " -NoNewline
Write-Host `
    "$RAMTotal GB / $RAMUso %" `
    -ForegroundColor Yellow


# ============================================================
# STATUS DO PDF
# ============================================================

Write-Host "PDF        : " -NoNewline

if (
    $StatusPDF -eq "GERADO"
) {

    Write-Host `
        "GERADO" `
        -ForegroundColor Green

    Write-Host "Arquivo    : " -NoNewline

    Write-Host `
        $CaminhoPDF `
        -ForegroundColor Cyan

}
else {

    Write-Host `
        $StatusPDF `
        -ForegroundColor Red
}


# ============================================================
# STATUS DO SERVIDOR
# ============================================================

Write-Host "Servidor   : " -NoNewline

if (
    $StatusServidor -eq "OK"
) {

    Write-Host `
        "ONLINE - INVENTÁRIO ARMAZENADO" `
        -ForegroundColor Green

}
else {

    Write-Host `
        $StatusServidor `
        -ForegroundColor Red
}


# ============================================================
# ALERTAS
# ============================================================

Write-Host ""

if (
    $Alertas.Count -gt 0
) {

    Write-Host `
        "ALERTAS PREVENTIVOS:" `
        -ForegroundColor Red

    Write-Host ""

    foreach ($A in $Alertas) {

        Write-Host `
            " - $A" `
            -ForegroundColor Yellow
    }

}
else {

    Write-Host `
        "Nenhum alerta preventivo identificado." `
        -ForegroundColor Green
}


# ============================================================
# ABRIR PDF AUTOMATICAMENTE
# ============================================================

if (
    $StatusPDF -eq "GERADO" -and
    (Test-Path $CaminhoPDF)
) {

    Write-Host ""
    Write-Host "Abrindo relatório PDF..." -ForegroundColor Cyan

    try {

        Start-Process `
            -FilePath $CaminhoPDF `
            -ErrorAction SilentlyContinue

    }
    catch {}
}


# ============================================================
# FINAL
# ============================================================

Write-Host ""

Pausar-Diagnostico
