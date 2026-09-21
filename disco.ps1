# ============================================================
# LR TECNOLOGIA
# SEATTLE - DIAGNOSTICO COMPLETO DO ARMAZENAMENTO
#
# Versao: 1.0
#
# Funcionalidades:
#   - Identificacao HDD / SSD / NVMe
#   - Capacidade
#   - HealthStatus
#   - Storage Reliability Counter
#   - Temperatura
#   - Horas de uso
#   - Desgaste
#   - Erros de leitura/gravação
#   - CHKDSK /SCAN
#   - Eventos de armazenamento do Windows
#   - Teste de leitura/desempenho com WinSAT
#
# NAO EXECUTA:
#   - CHKDSK /F
#   - CHKDSK /R
#   - Formatação
#   - Escrita de dados de teste
#   - Alterações no disco
#
# Desenvolvido por Leonardo M. Batista
# LR Tecnologia
# ============================================================


$ErrorActionPreference = "SilentlyContinue"

Clear-Host


# ============================================================
# CONFIGURAÇÕES
# ============================================================

$Inicio = Get-Date

$Resultado = "NORMAL"

$Alertas = New-Object System.Collections.Generic.List[string]

$Avisos = New-Object System.Collections.Generic.List[string]


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


# ============================================================
# CABEÇALHO
# ============================================================

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "       LR TECNOLOGIA - DIAGNÓSTICO DO ARMAZENAMENTO" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Computador : $env:COMPUTERNAME"
Write-Host "Usuário    : $env:USERNAME"
Write-Host "Windows    : $([System.Environment]::OSVersion.Version)"
Write-Host "Data       : $(Get-Date -Format 'dd/MM/yyyy HH:mm:ss')"
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

    Write-Host "AVISO: o PowerShell não está sendo executado como Administrador." `
        -ForegroundColor Yellow

    Write-Host ""
    Write-Host "Alguns testes poderão não fornecer todas as informações."
    Write-Host ""
}


# ============================================================
# IDENTIFICAR DISCO DO SISTEMA
# ============================================================

$ParticaoSistema = Get-CimInstance Win32_LogicalDisk `
    -Filter "DeviceID='C:'"

if ($ParticaoSistema) {

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

    Write-Host "UNIDADE DO SISTEMA"
    Mostrar-Linha

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

    Write-Host ""
}


# ============================================================
# DISCOS FÍSICOS
# ============================================================

Write-Host ""
Write-Host "DISCOS FÍSICOS"
Mostrar-Linha

$Discos = Get-PhysicalDisk

if (-not $Discos) {

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

        # ----------------------------------------------------
        # TIPO
        # ----------------------------------------------------

        switch ($Disco.MediaType) {

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
                $TipoMidia = "Não identificado"
            }
        }

        $CapacidadeDisco = [math]::Round(
            $Disco.Size / 1GB,
            2
        )

        Write-Host "Tipo              : $TipoMidia"
        Write-Host "Modelo            : $($Disco.FriendlyName)"
        Write-Host "Fabricante        : $($Disco.Manufacturer)"
        Write-Host "Número de série   : $($Disco.SerialNumber)"
        Write-Host "Capacidade        : $CapacidadeDisco GB"
        Write-Host "HealthStatus      : $($Disco.HealthStatus)"
        Write-Host "OperationalStatus : $($Disco.OperationalStatus)"

        # ----------------------------------------------------
        # HEALTH STATUS
        # ----------------------------------------------------

        if ($Disco.HealthStatus -eq "Unhealthy") {

            Adicionar-Alerta `
                "O disco '$($Disco.FriendlyName)' está com HealthStatus UNHEALTHY."

            Nivel-Critico
        }

        elseif ($Disco.HealthStatus -eq "Warning") {

            Adicionar-Alerta `
                "O disco '$($Disco.FriendlyName)' está com HealthStatus WARNING."

            Nivel-Atencao
        }

        elseif ($Disco.HealthStatus -eq "Unknown") {

            Adicionar-Aviso `
                "O Windows não conseguiu determinar completamente a saúde de '$($Disco.FriendlyName)'."
        }


        # ====================================================
        # STORAGE RELIABILITY COUNTER
        # ====================================================

        Write-Host ""
        Write-Host "Indicadores de confiabilidade:" `
            -ForegroundColor Yellow

        $Contador = Get-StorageReliabilityCounter `
            -PhysicalDisk $Disco

        if ($Contador) {

            # ------------------------------------------------
            # TEMPERATURA
            # ------------------------------------------------

            if ($null -ne $Contador.Temperature) {

                Write-Host "Temperatura       : $($Contador.Temperature) °C"

                if ($Contador.Temperature -ge 70) {

                    Adicionar-Alerta `
                        "Temperatura muito elevada no disco '$($Disco.FriendlyName)': $($Contador.Temperature) °C."

                    Nivel-Critico
                }
                elseif ($Contador.Temperature -ge 60) {

                    Adicionar-Alerta `
                        "Temperatura elevada no disco '$($Disco.FriendlyName)': $($Contador.Temperature) °C."

                    Nivel-Atencao
                }
            }


            # ------------------------------------------------
            # HORAS DE USO
            # ------------------------------------------------

            if ($null -ne $Contador.PowerOnHours) {

                Write-Host "Horas ligado     : $($Contador.PowerOnHours) h"
            }


            # ------------------------------------------------
            # DESGASTE
            # ------------------------------------------------

            if ($null -ne $Contador.Wear) {

                Write-Host "Desgaste          : $($Contador.Wear)%"

                if ($Contador.Wear -ge 90) {

                    Adicionar-Alerta `
                        "Indicador de desgaste muito elevado: $($Contador.Wear)%."

                    Nivel-Critico
                }
                elseif ($Contador.Wear -ge 80) {

                    Adicionar-Alerta `
                        "Indicador de desgaste elevado: $($Contador.Wear)%."

                    Nivel-Atencao
                }
            }


            # ------------------------------------------------
            # ERROS DE LEITURA
            # ------------------------------------------------

            if ($null -ne $Contador.ReadErrorsUncorrected) {

                Write-Host "Erros leitura     : $($Contador.ReadErrorsUncorrected)"

                if ($Contador.ReadErrorsUncorrected -gt 0) {

                    Adicionar-Alerta `
                        "Existem erros de leitura não corrigidos."

                    Nivel-Critico
                }
            }


            # ------------------------------------------------
            # ERROS DE GRAVAÇÃO
            # ------------------------------------------------

            if ($null -ne $Contador.WriteErrorsUncorrected) {

                Write-Host "Erros gravação    : $($Contador.WriteErrorsUncorrected)"

                if ($Contador.WriteErrorsUncorrected -gt 0) {

                    Adicionar-Alerta `
                        "Existem erros de gravação não corrigidos."

                    Nivel-Critico
                }
            }


            # ------------------------------------------------
            # LATÊNCIA DE LEITURA
            # ------------------------------------------------

            if ($null -ne $Contador.ReadLatencyMax) {

                Write-Host "Latência leitura  : $($Contador.ReadLatencyMax) ms"

                if ($Contador.ReadLatencyMax -gt 10000) {

                    Adicionar-Alerta `
                        "Latência máxima de leitura superior a 10 segundos."

                    Nivel-Atencao
                }
            }


            # ------------------------------------------------
            # LATÊNCIA DE GRAVAÇÃO
            # ------------------------------------------------

            if ($null -ne $Contador.WriteLatencyMax) {

                Write-Host "Latência gravação : $($Contador.WriteLatencyMax) ms"

                if ($Contador.WriteLatencyMax -gt 10000) {

                    Adicionar-Alerta `
                        "Latência máxima de gravação superior a 10 segundos."

                    Nivel-Atencao
                }
            }

        }
        else {

            Write-Host "Contadores não disponíveis." `
                -ForegroundColor Yellow

            Adicionar-Aviso `
                "O dispositivo não forneceu todos os contadores de confiabilidade."
        }

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
Write-Host "Executando CHKDSK /SCAN..."
Write-Host "Este teste não executa correção automática."
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
    $ChkDiskTexto -match "Windows found problems" -or
    $ChkDiskTexto -match "problemas" -and
    $ChkDiskTexto -match "encontr"
) {

    Adicionar-Alerta `
        "O CHKDSK indicou possíveis problemas no sistema de arquivos."

    Nivel-Atencao
}


# ============================================================
# EVENTOS DE DISCO
# ============================================================

Write-Host ""
Write-Host "EVENTOS RECENTES DE ARMAZENAMENTO" `
    -ForegroundColor Cyan

Mostrar-Linha

Write-Host ""
Write-Host "Consultando eventos dos últimos 7 dias..."

$DataInicio = (Get-Date).AddDays(-7)

$EventosDisco = Get-WinEvent `
    -FilterHashtable @{
        LogName = "System"
        StartTime = $DataInicio
    } `
    -ErrorAction SilentlyContinue |
    Where-Object {

        $_.ProviderName -match `
        "disk|storahci|stornvme|iaStor|Ntfs|volmgr"
    }

$EventosErro = $EventosDisco |
    Where-Object {
        $_.LevelDisplayName -eq "Error" -or
        $_.LevelDisplayName -eq "Critical"
    }

$TotalEventos = @($EventosDisco).Count
$TotalErros = @($EventosErro).Count

Write-Host "Eventos encontrados : $TotalEventos"
Write-Host "Erros críticos      : $TotalErros"

if ($TotalErros -gt 0) {

    Write-Host ""
    Write-Host "Eventos de erro encontrados:" `
        -ForegroundColor Yellow

    $EventosErro |
        Select-Object -First 10 |
        ForEach-Object {

            Write-Host ""
            Write-Host "Data: $($_.TimeCreated)"
            Write-Host "Origem: $($_.ProviderName)"
            Write-Host "ID: $($_.Id)"
            Write-Host "Mensagem: $($_.Message)"
        }

    Adicionar-Alerta `
        "Foram encontrados eventos de erro relacionados ao armazenamento nos últimos 7 dias."

    Nivel-Atencao
}
else {

    Write-Host "Nenhum erro crítico de armazenamento encontrado." `
        -ForegroundColor Green
}


# ============================================================
# TESTE DE DESEMPENHO / LEITURA
# ============================================================

Write-Host ""
Write-Host "TESTE DE DESEMPENHO DO DISCO" `
    -ForegroundColor Cyan

Mostrar-Linha

Write-Host ""

$WinSAT = Get-Command winsat.exe -ErrorAction SilentlyContinue

if ($WinSAT) {

    Write-Host "Executando avaliação de armazenamento do Windows..."
    Write-Host "Aguarde..."
    Write-Host ""

    $WinSATResultado = & winsat.exe disk -drive c 2>&1

    Write-Host $WinSATResultado

    # --------------------------------------------------------
    # TENTAR IDENTIFICAR RESULTADOS
    # --------------------------------------------------------

    $ResultadosMB = @()

    foreach ($Linha in $WinSATResultado) {

        if (
            $Linha -match "Sequential Read" -or
            $Linha -match "Sequential Write" -or
            $Linha -match "Random Read" -or
            $Linha -match "Random Write"
        ) {

            Write-Host $Linha
        }
    }

}
else {

    Write-Host "WinSAT não está disponível neste Windows." `
        -ForegroundColor Yellow

    Adicionar-Aviso `
        "O WinSAT não está disponível para realizar o teste de desempenho."
}


# ============================================================
# TESTE DE LATÊNCIA
# ============================================================

Write-Host ""
Write-Host "TESTE SIMPLES DE ACESSO AO DISCO" `
    -ForegroundColor Cyan

Mostrar-Linha

Write-Host ""

$ArquivoTeste = Join-Path $env:TEMP "LR_Tecnologia_Disco_Test.tmp"

try {

    $TamanhoTesteMB = 100

    Write-Host "Criando arquivo temporário de teste: $TamanhoTesteMB MB"
    Write-Host "O arquivo será removido ao final."

    $Dados = New-Object byte[] (1MB)

    $Stream = [System.IO.File]::Open(
        $ArquivoTeste,
        [System.IO.FileMode]::Create,
        [System.IO.FileAccess]::Write,
        [System.IO.FileShare]::None
    )

    $Cronometro = [System.Diagnostics.Stopwatch]::StartNew()

    for ($i = 0; $i -lt $TamanhoTesteMB; $i++) {

        $Stream.Write($Dados, 0, $Dados.Length)
    }

    $Stream.Flush()
    $Stream.Close()

    $Cronometro.Stop()

    $TempoEscrita = $Cronometro.Elapsed.TotalSeconds

    if ($TempoEscrita -gt 0) {

        $VelocidadeEscrita = [math]::Round(
            $TamanhoTesteMB / $TempoEscrita,
            2
        )

        Write-Host ""
        Write-Host "Velocidade aproximada de gravação:"
        Write-Host "$VelocidadeEscrita MB/s"
    }


    # --------------------------------------------------------
    # TESTE DE LEITURA
    # --------------------------------------------------------

    $Buffer = New-Object byte[] (1MB)

    $Stream = [System.IO.File]::Open(
        $ArquivoTeste,
        [System.IO.FileMode]::Open,
        [System.IO.FileAccess]::Read,
        [System.IO.FileShare]::Read
    )

    $Cronometro.Restart()

    while ($Stream.Read($Buffer, 0, $Buffer.Length) -gt 0) {
        # leitura
    }

    $Stream.Close()

    $Cronometro.Stop()

    $TempoLeitura = $Cronometro.Elapsed.TotalSeconds

    if ($TempoLeitura -gt 0) {

        $VelocidadeLeitura = [math]::Round(
            $TamanhoTesteMB / $TempoLeitura,
            2
        )

        Write-Host ""
        Write-Host "Velocidade aproximada de leitura:"
        Write-Host "$VelocidadeLeitura MB/s"
    }


}
catch {

    Write-Host ""
    Write-Host "Não foi possível realizar o teste temporário." `
        -ForegroundColor Yellow

    Adicionar-Aviso `
        "O teste temporário de leitura/gravação não pôde ser concluído."
}
finally {

    if (Test-Path $ArquivoTeste) {

        Remove-Item `
            $ArquivoTeste `
            -Force `
            -ErrorAction SilentlyContinue
    }
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

if ($Resultado -eq "NORMAL") {

    Write-Host "                 RESULTADO: NORMAL" `
        -ForegroundColor Green
}
elseif ($Resultado -eq "ATENÇÃO") {

    Write-Host "                 RESULTADO: ATENÇÃO" `
        -ForegroundColor Yellow
}
else {

    Write-Host "                 RESULTADO: CRÍTICO" `
        -ForegroundColor Red
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

    Write-Host "Nenhum indicador crítico foi identificado." `
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
Write-Host "RECOMENDAÇÃO:" -ForegroundColor Cyan
Write-Host ""

switch ($Resultado) {

    "NORMAL" {

        Write-Host "Não foram encontrados indícios relevantes de falha"
        Write-Host "nos testes realizados."

        Write-Host ""
        Write-Host "Manter backup periódico dos dados."
    }

    "ATENÇÃO" {

        Write-Host "Foram encontrados indicadores que merecem investigação."

        Write-Host ""
        Write-Host "Recomenda-se:"
        Write-Host "1. Fazer backup dos dados importantes."
        Write-Host "2. Investigar os alertas apresentados."
        Write-Host "3. Repetir o diagnóstico se necessário."
        Write-Host "4. Considerar teste específico do fabricante."
    }

    "CRÍTICO" {

        Write-Host "Foram encontrados indicadores compatíveis com"
        Write-Host "possível problema no armazenamento." `
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
# FINAL
# ============================================================

Write-Host ""
Write-Host "============================================================"
Write-Host "Diagnóstico concluído."
Write-Host "Tempo total: $($Duracao.Minutes) min $($Duracao.Seconds) s"
Write-Host "============================================================"
Write-Host ""

Write-Host "IMPORTANTE:"
Write-Host "Este diagnóstico não garante que o disco não irá falhar."
Write-Host "Ele avalia somente os indicadores disponibilizados pelo"
Write-Host "Windows e pelo dispositivo durante este teste."
Write-Host ""

pause
