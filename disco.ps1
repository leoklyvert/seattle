# ============================================================
# LR TECNOLOGIA
# SEATTLE - TESTE E DIAGNÓSTICO DE ARMAZENAMENTO
#
# Versão: 2.0.0
#
# Avaliação somente leitura:
#   - Identificação HDD / SSD / NVMe
#   - HealthStatus / OperationalStatus
#   - Storage Reliability Counter
#   - Temperatura
#   - Horas de uso
#   - Desgaste
#   - Erros de leitura/gravação
#   - Latência máxima
#   - Espaço livre
#   - CHKDSK /SCAN
#   - Eventos de armazenamento do Windows
#   - Teste de leitura com WinSAT
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

    Write-Host "AVISO: PowerShell não está sendo executado como Administrador." `
        -ForegroundColor Yellow

    Write-Host ""
    Write-Host "Algumas informações de confiabilidade podem não estar disponíveis."
    Write-Host ""
}


# ============================================================
# UNIDADE DO SISTEMA
# ============================================================

Write-Host "UNIDADE DO SISTEMA" -ForegroundColor Cyan
Mostrar-Linha

$ParticaoSistema = Get-CimInstance Win32_LogicalDisk `
    -Filter "DeviceID='C:'"

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
        # IDENTIFICAÇÃO DO TIPO
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


        # Detectar NVMe pelo barramento/modelo quando possível

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
        # STORAGE RELIABILITY COUNTER
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
            else {

                Write-Host "Temperatura       : Não disponível"
            }


            # ------------------------------------------------
            # HORAS DE USO
            # ------------------------------------------------

            if ($null -ne $Contador.PowerOnHours) {

                Write-Host "Horas ligado      : $($Contador.PowerOnHours) h"
            }

            else {

                Write-Host "Horas ligado      : Não disponível"
            }


            # ------------------------------------------------
            # DESGASTE
            # ------------------------------------------------

            if ($null -ne $Contador.Wear) {

                Write-Host "Desgaste          : $($Contador.Wear)%"

                # O significado de Wear pode variar conforme
                # fabricante e dispositivo.

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
            # LATÊNCIA DE LEITURA
            # ------------------------------------------------

            if ($null -ne $Contador.ReadLatencyMax) {

                Write-Host "Latência leitura  : $($Contador.ReadLatencyMax) ms"

                if ($Contador.ReadLatencyMax -gt 10000) {

                    Adicionar-Alerta `
                        "Latência máxima de leitura superior a 10 segundos no disco '$($Disco.FriendlyName)'."

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


if ($EventosErro.Count -gt 0) {

    Write-Host ""
    Write-Host "Eventos de erro encontrados:" `
        -ForegroundColor Yellow


    $EventosErro |
        Select-Object -First 10 |
        ForEach-Object {

            Write-Host ""
            Write-Host "Data    : $($_.TimeCreated)"
            Write-Host "Origem  : $($_.ProviderName)"
            Write-Host "ID      : $($_.Id)"
            Write-Host "Mensagem: $($_.Message)"
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
Write-Host "Este teste não cria arquivo temporário"
Write-Host "e não grava dados no disco."
Write-Host ""


$WinSAT = Get-Command winsat.exe `
    -ErrorAction SilentlyContinue


if ($WinSAT) {

    Write-Host "Executando teste de leitura do Windows..."
    Write-Host "Aguarde..."
    Write-Host ""


    # Somente operações de leitura.
    #
    # Não utilizar:
    #
    # winsat disk -drive c
    #
    # porque a avaliação completa pode incluir operações
    # de gravação.

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
