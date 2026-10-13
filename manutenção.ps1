# ============================================================
# SEATTLE - LR TECNOLOGIA
# Módulo: Manutenção básica do Windows
# Versão 2.1.0
#
# Atenção:
# - Execute como administrador para tarefas de sistema.
# - Não desativa o UAC nem remove conteúdo geral de ProgramData.
# - Alterações em serviços são individuais e registradas para reversão.
# - Teste em equipamento próprio antes de utilizar remotamente.
# ============================================================

$ErrorActionPreference = "Continue"
$Versao = "2.1.0"
$PastaBase = Join-Path $env:LOCALAPPDATA "LR Tecnologia"
$PastaLogs = Join-Path $PastaBase "Logs"
$PastaBackups = Join-Path $PastaBase "Backups"
foreach ($Pasta in @($PastaLogs, $PastaBackups)) {
    try { New-Item -Path $Pasta -ItemType Directory -Force | Out-Null } catch {}
}
$ArquivoLog = Join-Path $PastaLogs "Seattle-Manutencao.log"
$ArquivoServicos = Join-Path $PastaBackups "Servicos-antes-da-alteracao.json"

function Log {
    param([string]$Mensagem)
    try { Add-Content -LiteralPath $ArquivoLog -Encoding UTF8 -Value "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Mensagem" } catch {}
}

function Eh-Administrador {
    try {
        $id = [Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object Security.Principal.WindowsPrincipal($id)
        return $p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
    } catch { return $false }
}

function Confirmar {
    param([string]$Mensagem)
    return ((Read-Host "$Mensagem (S/N)") -match '^(S|SIM)$')
}

function Pausar {
    Write-Host ""
    Write-Host "Pressione qualquer tecla para voltar ao menu..." -ForegroundColor DarkGray
    try { [void][Console]::ReadKey($true) } catch { [void](Read-Host "Pressione Enter") }
}

function Formatar-Tamanho {
    param([long]$Bytes)
    if ($Bytes -ge 1GB) { return ("{0:N2} GB" -f ($Bytes / 1GB)) }
    if ($Bytes -ge 1MB) { return ("{0:N2} MB" -f ($Bytes / 1MB)) }
    if ($Bytes -ge 1KB) { return ("{0:N2} KB" -f ($Bytes / 1KB)) }
    return "$Bytes bytes"
}

function Tamanho-Pasta {
    param([string]$Caminho)
    if (-not (Test-Path -LiteralPath $Caminho -PathType Container)) { return [long]0 }
    try {
        $s = (Get-ChildItem -LiteralPath $Caminho -Force -File -Recurse -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
        if ($null -eq $s) { return [long]0 }
        return [long]$s
    } catch { return [long]0 }
}

function Limpar-Pasta {
    param([string]$Caminho, [string]$Descricao)
    if ([string]::IsNullOrWhiteSpace($Caminho) -or -not (Test-Path -LiteralPath $Caminho -PathType Container)) {
        Write-Host "Pasta não encontrada: $Descricao" -ForegroundColor DarkGray
        return [long]0
    }
    Write-Host "Limpando $Descricao..." -ForegroundColor Cyan
    $antes = Tamanho-Pasta $Caminho
    $falhas = 0
    foreach ($item in @(Get-ChildItem -LiteralPath $Caminho -Force -ErrorAction SilentlyContinue)) {
        try { Remove-Item -LiteralPath $item.FullName -Force -Recurse -ErrorAction Stop }
        catch { $falhas++; Log "Falha ao remover '$($item.FullName)': $($_.Exception.Message)" }
    }
    $depois = Tamanho-Pasta $Caminho
    $liberado = [Math]::Max([long]0, ($antes - $depois))
    Write-Host "Espaço estimado liberado: $(Formatar-Tamanho $liberado)" -ForegroundColor Green
    if ($falhas) { Write-Host "$falhas item(ns) ignorados por estarem em uso ou sem permissão." -ForegroundColor Yellow }
    Log "Limpeza '$Caminho'; espaço estimado: $(Formatar-Tamanho $liberado); falhas=$falhas"
    return $liberado
}

function Limpar-Temporarios {
    Write-Host "`nSerão limpas apenas pastas temporárias conhecidas." -ForegroundColor Yellow
    Write-Host "Arquivos em uso serão ignorados. Pastas pessoais e ProgramData não serão apagadas."
    if (-not (Confirmar "Continuar com a limpeza")) { return }
    $total = [long]0
    $pastas = @()
    if ($env:TEMP) { $pastas += [pscustomobject]@{Path=$env:TEMP; Nome="Temporários do usuário"} }
    $localTemp = Join-Path $env:LOCALAPPDATA "Temp"
    if ($localTemp -and $localTemp -ne $env:TEMP) { $pastas += [pscustomobject]@{Path=$localTemp; Nome="Temporários locais do usuário"} }
    $pastas += [pscustomobject]@{Path=(Join-Path $env:WINDIR "Temp"); Nome="Temporários do Windows"}
    if (Test-Path "C:\Temp") { $pastas += [pscustomobject]@{Path="C:\Temp"; Nome="C:\Temp"} }
    foreach ($pasta in $pastas) { $total += Limpar-Pasta -Caminho $pasta.Path -Descricao $pasta.Nome }
    Write-Host "`nTotal estimado liberado: $(Formatar-Tamanho $total)" -ForegroundColor Green
    Log "Limpeza temporária concluída: $(Formatar-Tamanho $total)"
}

function Limpar-Lixeira {
    if (-not (Confirmar "Esvaziar a Lixeira? Esta ação não pode ser desfeita.")) { return }
    try {
        Clear-RecycleBin -Force -ErrorAction Stop
        Write-Host "Lixeira esvaziada." -ForegroundColor Green
        Log "Lixeira esvaziada."
    } catch { Write-Host "Falha ao esvaziar a Lixeira: $($_.Exception.Message)" -ForegroundColor Red; Log "Falha ao esvaziar Lixeira." }
}

function Limpar-DNS {
    try {
        Clear-DnsClientCache -ErrorAction Stop
        Write-Host "Cache DNS limpo." -ForegroundColor Green
        Log "Cache DNS limpo."
    } catch { Write-Host "Falha ao limpar DNS: $($_.Exception.Message)" -ForegroundColor Red }
}

function Backup-Registro {
    $data = Get-Date -Format "yyyyMMdd-HHmmss"
    $destinoUsuario = Join-Path $PastaBackups "HKCU-Software-$data.reg"
    $destinoSistema = Join-Path $PastaBackups "HKLM-Software-$data.reg"
    try {
        & reg.exe export "HKCU\Software" $destinoUsuario /y | Out-Null
        if ($LASTEXITCODE -eq 0) { Write-Host "Backup do usuário: $destinoUsuario" -ForegroundColor Green }
        else { Write-Host "Não foi possível exportar HKCU\Software." -ForegroundColor Yellow }
        if (Eh-Administrador) {
            & reg.exe export "HKLM\SOFTWARE" $destinoSistema /y | Out-Null
            if ($LASTEXITCODE -eq 0) { Write-Host "Backup do sistema: $destinoSistema" -ForegroundColor Green }
            else { Write-Host "Não foi possível exportar HKLM\SOFTWARE." -ForegroundColor Yellow }
        } else { Write-Host "Execute como administrador para incluir HKLM." -ForegroundColor Yellow }
    } catch { Write-Host "Erro no backup: $($_.Exception.Message)" -ForegroundColor Red }
    Log "Rotina de backup do Registro executada."
}

function Verificar-Registro {
    $caminhos = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )
    $contagem = 0
    foreach ($caminho in $caminhos) {
        try { $contagem += @((Get-ItemProperty -Path $caminho -ErrorAction SilentlyContinue | Where-Object DisplayName)).Count } catch {}
    }
    Write-Host "Entradas de programas encontradas: $contagem" -ForegroundColor Green
    Write-Host "A contagem não identifica erros. Nenhuma chave será apagada." -ForegroundColor Yellow
    Log "Verificação somente leitura do Registro: $contagem entradas."
}

function Limpar-ComponentesWindows {
    if (-not (Eh-Administrador)) { Write-Host "Esta tarefa exige administrador." -ForegroundColor Red; return }
    Write-Host "O DISM limpa componentes substituídos do Windows e pode demorar." -ForegroundColor Yellow
    if (-not (Confirmar "Executar DISM StartComponentCleanup")) { return }
    try {
        $proc = Start-Process dism.exe -ArgumentList @("/Online","/Cleanup-Image","/StartComponentCleanup") -Wait -PassThru -NoNewWindow
        if ($proc.ExitCode -eq 0) { Write-Host "Limpeza concluída." -ForegroundColor Green }
        else { Write-Host "DISM retornou código $($proc.ExitCode)." -ForegroundColor Yellow }
        Log "DISM executado; código=$($proc.ExitCode)"
    } catch { Write-Host "Erro no DISM: $($_.Exception.Message)" -ForegroundColor Red }
}

function Configurar-Energia {
    Write-Host "`nPERFIL DE ENERGIA: DESEMPENHO MÁXIMO" -ForegroundColor Cyan
    Write-Host "Pode aumentar consumo, temperatura e ruído, especialmente em notebooks."
    if (-not (Confirmar "Ativar ou selecionar o perfil")) { return }
    try {
        $lista = (& powercfg.exe /list 2>&1 | Out-String)
        $guid = "e9a42b02-d5df-448d-aa00-03f14749eb61"
        $match = [regex]::Match($lista, "(?i)[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}.*$([regex]::Escape($guid))")
        if ($lista -match "(?i)$guid") {
            $plano = $guid
        } else {
            $saida = & powercfg.exe -duplicatescheme $guid 2>&1 | Out-String
            $novo = [regex]::Match($saida, "(?i)[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}")
            if (-not $novo.Success) { throw "Não foi possível criar o plano: $saida" }
            $plano = $novo.Value
        }
        & powercfg.exe /setactive $plano
        if ($LASTEXITCODE -eq 0) { Write-Host "Plano de desempenho máximo ativado." -ForegroundColor Green; Log "Plano de energia de desempenho máximo ativado: $plano" }
        else { Write-Host "Não foi possível ativar o plano." -ForegroundColor Yellow }
    } catch { Write-Host "Erro de energia: $($_.Exception.Message)" -ForegroundColor Red }
}

function Abrir-Energia {
    Start-Process "powercfg.cpl"
}

function Configurar-Suspensao {
    Write-Host "`nEsta opção desativa a hibernação e define monitor, disco e suspensão para Nunca." -ForegroundColor Yellow
    Write-Host "Em notebooks, isso pode gastar bateria e impedir economia automática de energia."
    if (-not (Eh-Administrador)) { Write-Host "Execute como administrador." -ForegroundColor Red; return }
    if (-not (Confirmar "Aplicar estas configurações de energia")) { return }
    $comandos = @(
        @("/change","monitor-timeout-ac","0"),
        @("/change","monitor-timeout-dc","0"),
        @("/change","disk-timeout-ac","0"),
        @("/change","disk-timeout-dc","0"),
        @("/change","standby-timeout-ac","0"),
        @("/change","standby-timeout-dc","0"),
        @("/change","hibernate-timeout-ac","0"),
        @("/change","hibernate-timeout-dc","0"),
        @("/hibernate","off")
    )
    foreach ($args in $comandos) {
        & powercfg.exe @args
        if ($LASTEXITCODE -ne 0) { Write-Host "Comando powercfg falhou: $($args -join ' ')" -ForegroundColor Yellow }
    }
    Log "Configurações de suspensão aplicadas; hibernação desativada."
    Write-Host "Configurações aplicadas." -ForegroundColor Green
}

function Sincronizar-Horario {
    if (-not (Eh-Administrador)) { Write-Host "Esta tarefa exige administrador." -ForegroundColor Red; return }
    $servidores = "a.st1.ntp.br c.st1.ntp.br d.st1.ntp.br e.st1.ntp.br"
    Write-Host "`nServidores NTP: $servidores" -ForegroundColor Cyan
    if (-not (Confirmar "Configurar e sincronizar o horário")) { return }
    try {
        & w32tm.exe /config "/manualpeerlist:$servidores" /syncfromflags:manual /update
        Set-Service -Name W32Time -StartupType Automatic -ErrorAction Stop
        Start-Service -Name W32Time -ErrorAction SilentlyContinue
        Restart-Service -Name W32Time -Force -ErrorAction Stop
        Start-Sleep -Seconds 3
        & w32tm.exe /resync /force
        Write-Host "`nFonte atual:" -ForegroundColor Cyan
        & w32tm.exe /query /source
        Write-Host "`nStatus:" -ForegroundColor Cyan
        & w32tm.exe /query /status
        Log "Configuração NTP aplicada."
    } catch { Write-Host "Falha na sincronização: $($_.Exception.Message)" -ForegroundColor Red; Log "Falha na configuração NTP." }
}

function Abrir-ConfiguracaoNavegador {
    Write-Host "O Windows controla o navegador padrão; o comando antigo do Chrome não é confiável nas versões atuais." -ForegroundColor Yellow
    try { Start-Process "ms-settings:defaultapps" } catch { Write-Host "Abra Configurações > Aplicativos > Aplicativos padrão." }
    Write-Host "Selecione Google Chrome na tela do Windows para defini-lo como padrão."
}

function Desinstalar-OneDrive {
    Write-Host "A remoção do OneDrive pode interromper sincronização e acesso a arquivos em nuvem." -ForegroundColor Yellow
    if (-not (Confirmar "Tentar desinstalar o OneDrive deste computador")) { return }
    $candidatos = @(
        (Join-Path $env:SystemRoot "System32\OneDriveSetup.exe"),
        (Join-Path $env:SystemRoot "SysWOW64\OneDriveSetup.exe")
    )
    $setup = $candidatos | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
    if (-not $setup) { Write-Host "Instalador do OneDrive não encontrado." -ForegroundColor Yellow; return }
    try {
        Start-Process -FilePath $setup -ArgumentList "/uninstall" -Wait
        Write-Host "Comando de desinstalação concluído. Verifique Aplicativos instalados." -ForegroundColor Green
        Log "Comando de desinstalação do OneDrive executado."
    } catch { Write-Host "Falha: $($_.Exception.Message)" -ForegroundColor Red }
}

function Limpar-PastasInstalacaoConhecidas {
    $alvos = @(
        [pscustomobject]@{Path="C:\Office"; Nome="C:\Office"},
        [pscustomobject]@{Path="C:\InstaladoresDotNet"; Nome="Instaladores .NET"},
        [pscustomobject]@{Path="C:\InstaladoresVCpp"; Nome="Instaladores Visual C++"}
    )
    Write-Host "Só serão considerados os diretórios listados abaixo; ProgramData e Prefetch não serão apagados." -ForegroundColor Yellow
    foreach ($a in $alvos) {
        if (Test-Path -LiteralPath $a.Path) { Write-Host " - $($a.Path)" }
    }
    if (-not (Confirmar "Apagar o conteúdo das pastas de instalação existentes acima")) { return }
    foreach ($a in $alvos) {
        if (Test-Path -LiteralPath $a.Path) {
            Limpar-Pasta -Caminho $a.Path -Descricao $a.Nome | Out-Null
        }
    }
}

function Desativar-ServicosOpcionais {
    if (-not (Eh-Administrador)) { Write-Host "É necessário executar como administrador." -ForegroundColor Red; return }

    # Nomes internos conhecidos. "Serviços do Sbox" precisa do nome interno exato
    # para ser adicionado com segurança.
    $catalogo = @(
        [pscustomobject]@{Name="Fax"; Label="Fax"; Aviso="Pode afetar envio/recebimento de fax."},
        [pscustomobject]@{Name="WSearch"; Label="Windows Search"; Aviso="Pode prejudicar indexação e pesquisas no menu Iniciar/Explorador."},
        [pscustomobject]@{Name="SysMain"; Label="SysMain (Superfetch)"; Aviso="O efeito depende do equipamento; pode afetar desempenho."},
        [pscustomobject]@{Name="XpsSvc"; Label="XPS Services"; Aviso="Pode afetar impressão/visualização de documentos XPS."},
        [pscustomobject]@{Name="RemoteRegistry"; Label="Remote Registry"; Aviso="Desativar geralmente reduz superfície de acesso remoto ao Registro."},
        [pscustomobject]@{Name="DiagTrack"; Label="Connected User Experiences and Telemetry"; Aviso="Reduz telemetria; pode afetar alguns recursos de diagnóstico."},
        [pscustomobject]@{Name="WerSvc"; Label="Windows Error Reporting"; Aviso="Desativa relatórios de falha que ajudam no diagnóstico."}
    )

    Write-Host "`nSERVIÇOS OPCIONAIS" -ForegroundColor Cyan
    Write-Host "Cada serviço será apresentado individualmente. Não escolha serviços sem confirmar a necessidade do cliente."
    $existentes = @()
    foreach ($s in $catalogo) {
        $svc = Get-CimInstance Win32_Service -Filter "Name='$($s.Name)'" -ErrorAction SilentlyContinue
        if ($svc) { $existentes += [pscustomobject]@{Catalogo=$s; Servico=$svc} }
    }
    if (-not $existentes.Count) { Write-Host "Nenhum dos serviços foi encontrado."; return }

    foreach ($item in $existentes) {
        $s = $item.Catalogo
        $svc = $item.Servico
        Write-Host "`n$($s.Label) [$($s.Name)] - Estado: $($svc.State); Inicialização: $($svc.StartMode)" -ForegroundColor Yellow
        Write-Host $s.Aviso -ForegroundColor Gray
        if (-not (Confirmar "Parar e desativar '$($s.Label)'")) { continue }

        try {
            $estadoAnterior = [pscustomobject]@{
                Name = $svc.Name
                DisplayName = $svc.DisplayName
                State = $svc.State
                StartMode = $svc.StartMode
                CapturedAt = (Get-Date).ToString("o")
            }
            $historico = @()
            if (Test-Path -LiteralPath $ArquivoServicos) {
                try { $historico = @(Get-Content -LiteralPath $ArquivoServicos -Raw | ConvertFrom-Json) } catch {}
            }
            $historico += $estadoAnterior
            $historico | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $ArquivoServicos -Encoding UTF8

            if ($svc.State -eq "Running") { Stop-Service -Name $svc.Name -Force -ErrorAction Stop }
            Set-Service -Name $svc.Name -StartupType Disabled -ErrorAction Stop
            Write-Host "Serviço desativado: $($s.Label)" -ForegroundColor Green
            Log "Serviço desativado: $($svc.Name); estado anterior=$($svc.State); inicialização anterior=$($svc.StartMode)"
        } catch {
            Write-Host "Não foi possível alterar $($s.Label): $($_.Exception.Message)" -ForegroundColor Red
            Log "Falha ao desativar $($s.Name): $($_.Exception.Message)"
        }
    }
    Write-Host "`nRegistro das configurações anteriores: $ArquivoServicos" -ForegroundColor Cyan
}

function Restaurar-Servicos {
    if (-not (Eh-Administrador)) { Write-Host "É necessário executar como administrador." -ForegroundColor Red; return }
    if (-not (Test-Path -LiteralPath $ArquivoServicos)) {
        Write-Host "Não há arquivo de backup de serviços neste perfil." -ForegroundColor Yellow
        return
    }
    if (-not (Confirmar "Restaurar configurações anteriores dos serviços registrados")) { return }
    try {
        $historico = @(Get-Content -LiteralPath $ArquivoServicos -Raw | ConvertFrom-Json)
        foreach ($s in $historico) {
            try {
                $tipo = switch ($s.StartMode) {
                    "Auto" { "Automatic" }
                    "Manual" { "Manual" }
                    "Disabled" { "Disabled" }
                    default { "Manual" }
                }
                Set-Service -Name $s.Name -StartupType $tipo -ErrorAction Stop
                if ($s.State -eq "Running" -and $tipo -ne "Disabled") {
                    Start-Service -Name $s.Name -ErrorAction SilentlyContinue
                }
                Write-Host "Restaurado: $($s.Name) -> $tipo" -ForegroundColor Green
                Log "Serviço restaurado: $($s.Name) -> $tipo"
            } catch {
                Write-Host "Falha ao restaurar $($s.Name): $($_.Exception.Message)" -ForegroundColor Yellow
            }
        }
    } catch { Write-Host "Erro lendo backup: $($_.Exception.Message)" -ForegroundColor Red }
}

function Executar-Acao {
    param([scriptblock]$Acao)
    try { & $Acao }
    catch { Write-Host "Erro: $($_.Exception.Message)" -ForegroundColor Red; Log "Erro não tratado: $($_.Exception.Message)" }
    Pausar
}

function Menu-Manutencao {
    do {
        Clear-Host
        Write-Host ""
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "             MÓDULO SEATTLE - LR TECNOLOGIA" -ForegroundColor Cyan
        Write-Host "                  MANUTENÇÃO v$Versao" -ForegroundColor Cyan
        Write-Host "============================================================" -ForegroundColor Cyan
        Write-Host "Computador: $env:COMPUTERNAME | Usuário: $env:USERNAME" -ForegroundColor Gray
        if (Eh-Administrador) { Write-Host "Permissão: Administrador" -ForegroundColor Green }
        else { Write-Host "Permissão: Usuário comum - tarefas de sistema podem falhar" -ForegroundColor Yellow }
        Write-Host ""
        Write-Host "1 - Limpar arquivos temporários"
        Write-Host "2 - Esvaziar Lixeira"
        Write-Host "3 - Limpar cache DNS"
        Write-Host "4 - Fazer backup do Registro"
        Write-Host "5 - Verificação informativa do Registro"
        Write-Host "6 - Limpeza de componentes do Windows (DISM)"
        Write-Host "7 - Ativar plano de energia Desempenho Máximo"
        Write-Host "8 - Abrir opções de energia do Windows"
        Write-Host "9 - Desativar hibernação e suspensão automática"
        Write-Host "10 - Sincronizar horário com servidores NTP.br"
        Write-Host "11 - Abrir configuração de navegador padrão"
        Write-Host "12 - Tentar desinstalar OneDrive"
        Write-Host "13 - Limpar pastas de instaladores conhecidas"
        Write-Host "14 - Desativar serviços opcionais (um por vez)"
        Write-Host "15 - Restaurar configurações anteriores dos serviços"
        Write-Host "0 - Voltar ao menu principal" -ForegroundColor Yellow
        Write-Host ""
        $opcao = Read-Host "Selecione uma opção"
        switch ($opcao) {
            "1" { Executar-Acao { Limpar-Temporarios } }
            "2" { Executar-Acao { Limpar-Lixeira } }
            "3" { Executar-Acao { Limpar-DNS } }
            "4" { Executar-Acao { Backup-Registro } }
            "5" { Executar-Acao { Verificar-Registro } }
            "6" { Executar-Acao { Limpar-ComponentesWindows } }
            "7" { Executar-Acao { Configurar-Energia } }
            "8" { Executar-Acao { Abrir-Energia } }
            "9" { Executar-Acao { Configurar-Suspensao } }
            "10" { Executar-Acao { Sincronizar-Horario } }
            "11" { Executar-Acao { Abrir-ConfiguracaoNavegador } }
            "12" { Executar-Acao { Desinstalar-OneDrive } }
            "13" { Executar-Acao { Limpar-PastasInstalacaoConhecidas } }
            "14" { Executar-Acao { Desativar-ServicosOpcionais } }
            "15" { Executar-Acao { Restaurar-Servicos } }
            "0" { return }
            default { Write-Host "Opção inválida." -ForegroundColor Red; Start-Sleep -Seconds 1 }
        }
    } while ($true)
}

Log "Início do módulo de manutenção v$Versao."
Menu-Manutencao
Log "Fim do módulo de manutenção v$Versao."
