Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Backup do perfil do Windows'
$form.StartPosition = 'CenterScreen'
$form.Size = New-Object System.Drawing.Size(790, 455)
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false

$title = New-Object System.Windows.Forms.Label
$title.Text = 'Copie as pastas do perfil e outras pastas escolhidas para um HD externo.'
$title.Location = New-Object System.Drawing.Point(18, 18)
$title.Size = New-Object System.Drawing.Size(740, 28)
$form.Controls.Add($title)

$choose = New-Object System.Windows.Forms.Button
$choose.Text = 'Escolher pasta no HD externo…'
$choose.Location = New-Object System.Drawing.Point(18, 52)
$choose.Size = New-Object System.Drawing.Size(205, 34)
$form.Controls.Add($choose)

$destinationLabel = New-Object System.Windows.Forms.Label
$destinationLabel.Text = 'Nenhum destino selecionado.'
$destinationLabel.Location = New-Object System.Drawing.Point(235, 56)
$destinationLabel.Size = New-Object System.Drawing.Size(535, 36)
$form.Controls.Add($destinationLabel)

$customHeader = New-Object System.Windows.Forms.Label
$customHeader.Text = 'Pastas adicionais para incluir (de qualquer unidade):'
$customHeader.Location = New-Object System.Drawing.Point(18, 96)
$customHeader.Size = New-Object System.Drawing.Size(540, 22)
$form.Controls.Add($customHeader)

$customList = New-Object System.Windows.Forms.ListBox
$customList.Location = New-Object System.Drawing.Point(18, 120)
$customList.Size = New-Object System.Drawing.Size(570, 90)
$form.Controls.Add($customList)

$addCustom = New-Object System.Windows.Forms.Button
$addCustom.Text = 'Adicionar pasta…'
$addCustom.Location = New-Object System.Drawing.Point(605, 120)
$addCustom.Size = New-Object System.Drawing.Size(165, 34)
$addCustom.Enabled = $false
$form.Controls.Add($addCustom)

$removeCustom = New-Object System.Windows.Forms.Button
$removeCustom.Text = 'Remover selecionada'
$removeCustom.Location = New-Object System.Drawing.Point(605, 162)
$removeCustom.Size = New-Object System.Drawing.Size(165, 34)
$removeCustom.Enabled = $false
$form.Controls.Add($removeCustom)

$status = New-Object System.Windows.Forms.Label
$status.Text = 'Lista vazia: perfil padrão. Com pastas escolhidas: copia somente as selecionadas.'
$status.Location = New-Object System.Drawing.Point(18, 222)
$status.Size = New-Object System.Drawing.Size(740, 24)
$form.Controls.Add($status)

$privacy = New-Object System.Windows.Forms.Label
$privacy.Text = 'No backup padrão, o Wi-Fi exportado contém senhas legíveis no HD externo.'
$privacy.Location = New-Object System.Drawing.Point(18, 248)
$privacy.Size = New-Object System.Drawing.Size(740, 22)
$privacy.ForeColor = [System.Drawing.Color]::DarkRed
$form.Controls.Add($privacy)

$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(18, 278)
$progressBar.Size = New-Object System.Drawing.Size(740, 20)
$progressBar.Minimum = 0
$progressBar.Maximum = 100
$progressBar.Value = 0
$form.Controls.Add($progressBar)

$progressText = New-Object System.Windows.Forms.Label
$progressText.Text = 'Aguardando início.'
$progressText.Location = New-Object System.Drawing.Point(18, 304)
$progressText.Size = New-Object System.Drawing.Size(740, 24)
$form.Controls.Add($progressText)

$start = New-Object System.Windows.Forms.Button
$start.Text = 'Iniciar backup'
$start.Location = New-Object System.Drawing.Point(18, 350)
$start.Size = New-Object System.Drawing.Size(145, 36)
$start.Enabled = $false
$form.Controls.Add($start)

$close = New-Object System.Windows.Forms.Button
$close.Text = 'Fechar'
$close.Location = New-Object System.Drawing.Point(174, 350)
$close.Size = New-Object System.Drawing.Size(90, 36)
$form.Controls.Add($close)
$close.Add_Click({ $form.Close() })

$cancel = New-Object System.Windows.Forms.Button
$cancel.Text = 'Cancelar backup'
$cancel.Location = New-Object System.Drawing.Point(278, 350)
$cancel.Size = New-Object System.Drawing.Size(135, 36)
$cancel.Enabled = $false
$form.Controls.Add($cancel)

$picker = New-Object System.Windows.Forms.FolderBrowserDialog
$picker.Description = 'Selecione uma pasta no HD externo. O backup será criado dentro dela.'
$picker.ShowNewFolderButton = $true
$script:destinationRoot = $null
$script:customFolderPaths = New-Object System.Collections.ArrayList
$script:cancelRequested = $false
$customPicker = New-Object System.Windows.Forms.FolderBrowserDialog
$customPicker.Description = 'Selecione qualquer pasta que deseja acrescentar ao backup.'
$customPicker.ShowNewFolderButton = $false

function Get-TreeBytes([string]$Path) {
    [long]$sum = 0
    if (-not (Test-Path -LiteralPath $Path -PathType Container)) { return $sum }
    try {
        Get-ChildItem -LiteralPath $Path -File -Recurse -Force -ErrorAction SilentlyContinue | ForEach-Object { $sum += $_.Length }
    } catch { }
    return $sum
}

function Format-Size([long]$Bytes) {
    if ($Bytes -ge 1TB) { return ('{0:N1} TB' -f ($Bytes / 1TB)) }
    if ($Bytes -ge 1GB) { return ('{0:N1} GB' -f ($Bytes / 1GB)) }
    if ($Bytes -ge 1MB) { return ('{0:N1} MB' -f ($Bytes / 1MB)) }
    return ('{0:N1} KB' -f ($Bytes / 1KB))
}

$choose.Add_Click({
    if ($picker.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $selected = [System.IO.Path]::GetFullPath($picker.SelectedPath)
        $systemRoot = [System.IO.Path]::GetPathRoot($env:SystemRoot)
        $selectedRoot = [System.IO.Path]::GetPathRoot($selected)
        if ($selectedRoot -ieq $systemRoot) {
            [System.Windows.Forms.MessageBox]::Show('Escolha uma pasta em outra unidade, correspondente ao HD externo.', 'Destino inválido', 'OK', 'Warning') | Out-Null
            return
        }
        $script:destinationRoot = $selected
        $destinationLabel.Text = $selected
        $start.Enabled = $true
        $addCustom.Enabled = $true
    }
})

$addCustom.Add_Click({
    if ($customPicker.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $selected = [System.IO.Path]::GetFullPath($customPicker.SelectedPath).TrimEnd('\')
        $destination = [System.IO.Path]::GetFullPath($script:destinationRoot).TrimEnd('\')
        if ($selected -ieq $destination -or $destination.StartsWith($selected + '\', [System.StringComparison]::OrdinalIgnoreCase) -or $selected.StartsWith($destination + '\', [System.StringComparison]::OrdinalIgnoreCase)) {
            [System.Windows.Forms.MessageBox]::Show('Essa seleção se sobrepõe à pasta de destino do backup. Escolha outra pasta para evitar copiar o HD para dentro de si mesmo.', 'Pasta inválida', 'OK', 'Warning') | Out-Null
            return
        }
        if ($script:customFolderPaths -contains $selected) {
            [System.Windows.Forms.MessageBox]::Show('Essa pasta já está na lista.', 'Pasta repetida', 'OK', 'Information') | Out-Null
            return
        }
        $null = $script:customFolderPaths.Add($selected)
        $null = $customList.Items.Add($selected)
        $removeCustom.Enabled = $true
        $status.Text = "Modo pastas escolhidas: serão copiadas somente $($script:customFolderPaths.Count) pasta(s)."
    }
})

$removeCustom.Add_Click({
    $index = $customList.SelectedIndex
    if ($index -ge 0) {
        $script:customFolderPaths.RemoveAt($index)
        $customList.Items.RemoveAt($index)
    }
    $removeCustom.Enabled = ($customList.Items.Count -gt 0)
    if ($script:customFolderPaths.Count -eq 0) {
        $status.Text = 'Lista vazia: perfil padrão. Com pastas escolhidas: copia somente as selecionadas.'
    } else {
        $status.Text = "Modo pastas escolhidas: serão copiadas somente $($script:customFolderPaths.Count) pasta(s)."
    }
})

$cancel.Add_Click({
    $script:cancelRequested = $true
    $cancel.Enabled = $false
    $status.Text = 'Cancelando… interrompendo a cópia atual.'
    [System.Windows.Forms.Application]::DoEvents()
})

$start.Add_Click({
    $browserChoice = [System.Windows.Forms.MessageBox]::Show('Feche o Edge, Chrome e Firefox antes de continuar para que os arquivos de favoritos sejam copiados com segurança. Deseja iniciar o backup agora?', 'Feche os navegadores', 'YesNo', 'Question')
    if ($browserChoice -ne [System.Windows.Forms.DialogResult]::Yes) { return }
    $start.Enabled = $false
    $choose.Enabled = $false
    $close.Enabled = $false
    $cancel.Enabled = $true
    $script:cancelRequested = $false
    try {
        $timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
        $userName = $env:USERNAME -replace '[\\/:*?"<>|]', '_'
        $computerName = $env:COMPUTERNAME -replace '[\\/:*?"<>|]', '_'
        $backupRoot = Join-Path $script:destinationRoot ("Backup-{0}-{1}-{2}" -f $computerName, $userName, $timestamp)
        $null = New-Item -ItemType Directory -Path $backupRoot -ErrorAction Stop
        $logPath = Join-Path $backupRoot 'backup.log'

        $downloads = Join-Path $env:USERPROFILE 'Downloads'
        $contacts = Join-Path $env:USERPROFILE 'Contacts'
        $favorites = Join-Path $env:USERPROFILE 'Favorites'
        try {
            $userShell = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -ErrorAction Stop
            if ($userShell.'{374DE290-123F-4565-9164-39C4925E467B}') {
                $downloads = [Environment]::ExpandEnvironmentVariables($userShell.'{374DE290-123F-4565-9164-39C4925E467B}')
            }
            if ($userShell.'{56784854-C6CB-462B-8169-88E350ACB882}') {
                $contacts = [Environment]::ExpandEnvironmentVariables($userShell.'{56784854-C6CB-462B-8169-88E350ACB882}')
            }
            if ($userShell.Favorites) {
                $favorites = [Environment]::ExpandEnvironmentVariables($userShell.Favorites)
            }
        } catch { }

        $profileFolders = @(
            @{ Id = 'Desktop'; Name = 'Área de Trabalho'; Source = [Environment]::GetFolderPath('Desktop'); TargetRelative = 'Desktop' },
            @{ Id = 'Documents'; Name = 'Documentos'; Source = [Environment]::GetFolderPath('MyDocuments'); TargetRelative = 'Documents' },
            @{ Id = 'Downloads'; Name = 'Downloads'; Source = $downloads; TargetRelative = 'Downloads' },
            @{ Id = 'Contacts'; Name = 'Contatos'; Source = $contacts; TargetRelative = 'Contacts' },
            @{ Id = 'Favorites'; Name = 'Favoritos do Windows'; Source = $favorites; TargetRelative = 'Favorites' },
            @{ Id = 'Pictures'; Name = 'Imagens'; Source = [Environment]::GetFolderPath('MyPictures'); TargetRelative = 'Pictures' },
            @{ Id = 'Music'; Name = 'Músicas'; Source = [Environment]::GetFolderPath('MyMusic'); TargetRelative = 'Music' },
            @{ Id = 'Videos'; Name = 'Vídeos'; Source = [Environment]::GetFolderPath('MyVideos'); TargetRelative = 'Videos' }
        )
        if ($script:customFolderPaths.Count -eq 0) {
            $folders = @($profileFolders)
        } else {
            $folders = @()
            "MODO: somente pastas adicionais selecionadas ($($script:customFolderPaths.Count)); pastas padrão, navegadores e Wi-Fi não serão incluídos." | Add-Content -LiteralPath $logPath -Encoding UTF8
        }

        $customManifest = @()
        $customIndex = 0
        foreach ($customPath in $script:customFolderPaths) {
            $customIndex++
            $folderId = 'Folder-{0:D2}' -f $customIndex
            $customManifest += [pscustomobject]@{
                Id = $folderId
                DisplayName = (Split-Path -Leaf $customPath)
                SourcePath = $customPath
                BackupRelativePath = Join-Path 'Custom-Folders' $folderId
            }
            $folders += @{ Id = $folderId; Name = "Pasta adicional: $(Split-Path -Leaf $customPath)"; Source = $customPath; TargetRelative = (Join-Path 'Custom-Folders' $folderId) }
        }
        if ($customManifest.Count -gt 0) {
            $customManifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $backupRoot 'Custom-Folders.json') -Encoding UTF8
        }

        $progressBar.Style = 'Marquee'
        $progressText.Text = 'Calculando o tamanho aproximado das pastas…'
        [System.Windows.Forms.Application]::DoEvents()
        [long]$totalBytes = 0
        $folderSizes = @{}
        foreach ($folder in $folders) {
            $source = [Environment]::ExpandEnvironmentVariables($folder.Source)
            $folderSizes[$folder.Id] = Get-TreeBytes $source
            $totalBytes += $folderSizes[$folder.Id]
        }
        $progressBar.Style = 'Continuous'
        $progressBar.Value = 0
        $progressText.Text = "Tamanho a copiar: $(Format-Size $totalBytes) — estimativa começa durante a cópia."
        [System.Windows.Forms.Application]::DoEvents()
        $copyStarted = Get-Date
        [long]$completedBytes = 0

        "Backup iniciado: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`r`nUsuário: $env:USERDOMAIN\$env:USERNAME`r`nDestino: $backupRoot`r`n" | Set-Content -LiteralPath $logPath -Encoding UTF8
        $failures = @()
        $wasCancelled = $false
        foreach ($folder in $folders) {
            $source = [Environment]::ExpandEnvironmentVariables($folder.Source)
            $target = Join-Path $backupRoot $folder.TargetRelative
            $status.Text = "Copiando $($folder.Name)…"
            [System.Windows.Forms.Application]::DoEvents()
            if (-not $source -or -not (Test-Path -LiteralPath $source -PathType Container)) {
                "PULADA: $($folder.Name) — pasta não encontrada: $source" | Add-Content -LiteralPath $logPath -Encoding UTF8
                continue
            }
            $null = New-Item -ItemType Directory -Path $target -Force
            $argumentLine = '"{0}" "{1}" /E /COPY:DAT /DCOPY:DAT /XJ /R:2 /W:2 /FFT /NP "/LOG+:{2}"' -f $source, $target, $logPath
            $copyProcess = Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\robocopy.exe') -ArgumentList $argumentLine -WindowStyle Hidden -PassThru
            while (-not $copyProcess.HasExited) {
                [System.Windows.Forms.Application]::DoEvents()
                if ($script:cancelRequested) {
                    try { $copyProcess.Kill(); $copyProcess.WaitForExit() } catch { }
                    $wasCancelled = $true
                    break
                }
                Start-Sleep -Milliseconds 900
                $currentBytes = Get-TreeBytes $target
                $measuredBytes = [Math]::Min($totalBytes, ($completedBytes + $currentBytes))
                if ($totalBytes -gt 0) {
                    $percent = [int][Math]::Min(99, [Math]::Floor(100 * $measuredBytes / $totalBytes))
                    $progressBar.Value = [Math]::Max(0, $percent)
                    $elapsedSeconds = [Math]::Max(1, ((Get-Date) - $copyStarted).TotalSeconds)
                    $remainingSeconds = [Math]::Max([double]0, [Math]::Ceiling(([double]$totalBytes - [double]$measuredBytes) * [double]$elapsedSeconds / [Math]::Max([double]1, [double]$measuredBytes)))
                    $eta = [TimeSpan]::FromSeconds($remainingSeconds)
                    $progressText.Text = "${percent}% — $(Format-Size $measuredBytes) de $(Format-Size $totalBytes) — restante estimado: $($eta.ToString('hh\:mm\:ss'))"
                } else {
                    $progressText.Text = "Copiando $($folder.Name)…"
                }
            }
            if ($wasCancelled) {
                'BACKUP CANCELADO PELO USUÁRIO. A pasta contém uma cópia parcial; não considere este backup concluído.' | Add-Content -LiteralPath $logPath -Encoding UTF8
                break
            }
            $copyProcess.Refresh()
            $copyCode = $copyProcess.ExitCode
            if ($copyCode -ge 8) {
                $failures += $folder.Name
            }
            $completedBytes += $folderSizes[$folder.Id]
        }

        if (-not $wasCancelled -and $script:customFolderPaths.Count -eq 0) {
        $browserRoot = Join-Path $backupRoot 'Browser-Favorites'
        $browserProfiles = @(
            @{ Name = 'Edge'; Root = Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\User Data'; Type = 'Chromium' },
            @{ Name = 'Chrome'; Root = Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data'; Type = 'Chromium' },
            @{ Name = 'Firefox'; Root = Join-Path $env:APPDATA 'Mozilla\Firefox\Profiles'; Type = 'Firefox' }
        )
        foreach ($browser in $browserProfiles) {
            if (-not (Test-Path -LiteralPath $browser.Root -PathType Container)) {
                "NAVEGADOR PULADO: $($browser.Name) — perfis não encontrados." | Add-Content -LiteralPath $logPath -Encoding UTF8
                continue
            }
            $profiles = Get-ChildItem -LiteralPath $browser.Root -Directory -ErrorAction SilentlyContinue
            foreach ($profile in $profiles) {
                $profileTarget = Join-Path (Join-Path $browserRoot $browser.Name) $profile.Name
                if ($browser.Type -eq 'Chromium') {
                    $bookmarkFiles = @('Bookmarks', 'Bookmarks.bak')
                    $found = $false
                    foreach ($fileName in $bookmarkFiles) {
                        $filePath = Join-Path $profile.FullName $fileName
                        if (Test-Path -LiteralPath $filePath -PathType Leaf) {
                            $null = New-Item -ItemType Directory -Path $profileTarget -Force
                            Copy-Item -LiteralPath $filePath -Destination (Join-Path $profileTarget $fileName) -Force
                            $found = $true
                        }
                    }
                    if ($found) { "FAVORITOS COPIADOS: $($browser.Name) — perfil $($profile.Name)" | Add-Content -LiteralPath $logPath -Encoding UTF8 }
                } else {
                    $places = Join-Path $profile.FullName 'places.sqlite'
                    if (Test-Path -LiteralPath $places -PathType Leaf) {
                        $null = New-Item -ItemType Directory -Path $profileTarget -Force
                        foreach ($fileName in @('places.sqlite', 'places.sqlite-wal', 'places.sqlite-shm')) {
                            $filePath = Join-Path $profile.FullName $fileName
                            if (Test-Path -LiteralPath $filePath -PathType Leaf) {
                                Copy-Item -LiteralPath $filePath -Destination (Join-Path $profileTarget $fileName) -Force
                            }
                        }
                        $backupFolder = Join-Path $profile.FullName 'bookmarkbackups'
                        if (Test-Path -LiteralPath $backupFolder -PathType Container) {
                            Copy-Item -LiteralPath $backupFolder -Destination $profileTarget -Recurse -Force
                        }
                        "FAVORITOS COPIADOS: Firefox — perfil $($profile.Name)" | Add-Content -LiteralPath $logPath -Encoding UTF8
                    }
                }
            }
        }

        $wifiRoot = Join-Path $backupRoot 'WiFi-Profiles'
        $null = New-Item -ItemType Directory -Path $wifiRoot -Force
        $status.Text = 'Exportando perfis Wi-Fi…'
        [System.Windows.Forms.Application]::DoEvents()
        $wifiOutput = & netsh wlan export profile "folder=$wifiRoot" key=clear 2>&1 | Out-String
        $wifiCode = $LASTEXITCODE
        if ($wifiOutput.Trim()) { $wifiOutput.Trim() | Add-Content -LiteralPath $logPath -Encoding UTF8 }
        if ($wifiCode -eq 0 -and (Get-ChildItem -LiteralPath $wifiRoot -Filter '*.xml' -File -ErrorAction SilentlyContinue | Measure-Object).Count -gt 0) {
            'PERFIS WI-FI EXPORTADOS. Os arquivos XML contêm senhas legíveis.' | Add-Content -LiteralPath $logPath -Encoding UTF8
        } else {
            'AVISO: não foi possível confirmar a exportação dos perfis Wi-Fi. Verifique privilégios e adaptador Wi-Fi.' | Add-Content -LiteralPath $logPath -Encoding UTF8
            $failures += 'Wi-Fi'
        }
        } elseif ($wasCancelled) {
            'PULADO: favoritos dos navegadores e perfis Wi-Fi — backup cancelado.' | Add-Content -LiteralPath $logPath -Encoding UTF8
        } else {
            'PULADO: favoritos dos navegadores e perfis Wi-Fi — modo de cópia somente das pastas selecionadas.' | Add-Content -LiteralPath $logPath -Encoding UTF8
        }

        if ($wasCancelled) {
            $status.Text = 'Backup cancelado. A cópia parcial foi mantida no HD externo.'
            [System.Windows.Forms.MessageBox]::Show("Backup cancelado. A cópia parcial foi mantida e não deve ser usada como backup completo.`r`n`r`nPasta:`r`n$backupRoot`r`n`r`nConsulte backup.log.", 'Backup cancelado', 'OK', 'Warning') | Out-Null
        } elseif ($failures.Count -eq 0) {
            $status.Text = 'Backup concluído.'
            $progressBar.Value = 100
            $progressText.Text = '100% — backup concluído.'
            [System.Windows.Forms.MessageBox]::Show("Backup concluído.`r`n`r`nPasta criada:`r`n$backupRoot`r`n`r`nConfira o arquivo backup.log antes de encerrar o atendimento.", 'Backup concluído', 'OK', 'Information') | Out-Null
        } else {
            $status.Text = 'Backup finalizado com falhas em algumas pastas.'
            $progressBar.Value = 100
            $progressText.Text = 'Cópia concluída com itens para verificar no registro.'
            [System.Windows.Forms.MessageBox]::Show("O backup terminou, mas houve falha em: $($failures -join ', ').`r`nConsulte backup.log em:`r`n$backupRoot", 'Verifique o registro', 'OK', 'Warning') | Out-Null
        }
    } catch {
        $status.Text = 'Não foi possível concluir o backup.'
        [System.Windows.Forms.MessageBox]::Show("Erro: $($_.Exception.Message)", 'Falha no backup', 'OK', 'Error') | Out-Null
    } finally {
        $start.Enabled = $true
        $choose.Enabled = $true
        $close.Enabled = $true
        $cancel.Enabled = $false
    }
})

[void]$form.ShowDialog()



