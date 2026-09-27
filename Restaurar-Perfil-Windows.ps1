Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

$form = New-Object System.Windows.Forms.Form
$form.Text = 'Restaurar backup do perfil do Windows'
$form.StartPosition = 'CenterScreen'
$form.Size = New-Object System.Drawing.Size(700, 500)
$form.FormBorderStyle = 'FixedDialog'
$form.MaximizeBox = $false

$title = New-Object System.Windows.Forms.Label
$title.Text = 'Selecione um backup no HD externo e marque o que deseja restaurar.'
$title.Location = New-Object System.Drawing.Point(18, 18)
$title.Size = New-Object System.Drawing.Size(650, 28)
$form.Controls.Add($title)

$choose = New-Object System.Windows.Forms.Button
$choose.Text = 'Escolher pasta do backup…'
$choose.Location = New-Object System.Drawing.Point(18, 56)
$choose.Size = New-Object System.Drawing.Size(205, 34)
$form.Controls.Add($choose)

$backupLabel = New-Object System.Windows.Forms.Label
$backupLabel.Text = 'Nenhum backup selecionado.'
$backupLabel.Location = New-Object System.Drawing.Point(235, 60)
$backupLabel.Size = New-Object System.Drawing.Size(430, 38)
$form.Controls.Add($backupLabel)

$list = New-Object System.Windows.Forms.CheckedListBox
$list.Location = New-Object System.Drawing.Point(18, 105)
$list.Size = New-Object System.Drawing.Size(647, 235)
$list.CheckOnClick = $true
$list.Items.AddRange([object[]]@(
    'Área de Trabalho', 'Documentos', 'Downloads', 'Contatos', 'Favoritos do Windows',
    'Imagens', 'Músicas', 'Vídeos', 'Favoritos do Edge', 'Favoritos do Chrome',
    'Favoritos do Firefox', 'Perfis e senhas de Wi-Fi'
))
$form.Controls.Add($list)

$warning = New-Object System.Windows.Forms.Label
$warning.Text = 'Arquivos com o mesmo nome podem ser substituídos. O Firefox também pode restaurar histórico.'
$warning.Location = New-Object System.Drawing.Point(18, 350)
$warning.Size = New-Object System.Drawing.Size(647, 36)
$warning.ForeColor = [System.Drawing.Color]::DarkRed
$form.Controls.Add($warning)

$status = New-Object System.Windows.Forms.Label
$status.Text = 'Escolha o backup e os itens que deseja restaurar.'
$status.Location = New-Object System.Drawing.Point(18, 389)
$status.Size = New-Object System.Drawing.Size(647, 24)
$form.Controls.Add($status)

$restore = New-Object System.Windows.Forms.Button
$restore.Text = 'Restaurar selecionados'
$restore.Location = New-Object System.Drawing.Point(18, 420)
$restore.Size = New-Object System.Drawing.Size(190, 36)
$restore.Enabled = $false
$form.Controls.Add($restore)

$close = New-Object System.Windows.Forms.Button
$close.Text = 'Fechar'
$close.Location = New-Object System.Drawing.Point(220, 420)
$close.Size = New-Object System.Drawing.Size(90, 36)
$form.Controls.Add($close)
$close.Add_Click({ $form.Close() })

$picker = New-Object System.Windows.Forms.FolderBrowserDialog
$picker.Description = 'Selecione a pasta Backup-USUARIO-DATA no HD externo.'
$picker.ShowNewFolderButton = $false
$script:backupRoot = $null

$choose.Add_Click({
    if ($picker.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $selected = [System.IO.Path]::GetFullPath($picker.SelectedPath)
        if ((Split-Path -Leaf $selected) -notlike 'Backup-*') {
            [System.Windows.Forms.MessageBox]::Show('Selecione a pasta Backup-USUARIO-DATA, não a pasta pai do HD.', 'Pasta inválida', 'OK', 'Warning') | Out-Null
            return
        }
        $script:backupRoot = $selected
        $backupLabel.Text = $selected
        $restore.Enabled = $true
    }
})

$restore.Add_Click({
    $selectedItems = @($list.CheckedItems | ForEach-Object { $_.ToString() })
    if ($selectedItems.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show('Marque pelo menos um item para restaurar.', 'Nada selecionado', 'OK', 'Information') | Out-Null
        return
    }
    $answer = [System.Windows.Forms.MessageBox]::Show('A restauração pode substituir arquivos existentes nos locais de destino. Ela não apaga arquivos que existam apenas no computador. Deseja continuar?', 'Confirmar restauração', 'YesNo', 'Warning')
    if ($answer -ne [System.Windows.Forms.DialogResult]::Yes) { return }
    $browserItems = @('Favoritos do Edge', 'Favoritos do Chrome', 'Favoritos do Firefox')
    if (@($selectedItems | Where-Object { $_ -in $browserItems }).Count -gt 0) {
        $browserAnswer = [System.Windows.Forms.MessageBox]::Show('Feche Edge, Chrome e Firefox antes de restaurar os favoritos. O arquivo do Firefox pode incluir o histórico. Já fechou os navegadores?', 'Feche os navegadores', 'YesNo', 'Warning')
        if ($browserAnswer -ne [System.Windows.Forms.DialogResult]::Yes) { return }
    }

    $restore.Enabled = $false
    $choose.Enabled = $false
    $close.Enabled = $false
    $logPath = Join-Path $script:backupRoot 'restore.log'
    $failures = @()
    $folderMap = [ordered]@{
        'Área de Trabalho' = @{ Backup = 'Desktop'; Destination = [Environment]::GetFolderPath('Desktop') }
        'Documentos' = @{ Backup = 'Documents'; Destination = [Environment]::GetFolderPath('MyDocuments') }
        'Downloads' = @{ Backup = 'Downloads'; Destination = Join-Path $env:USERPROFILE 'Downloads' }
        'Contatos' = @{ Backup = 'Contacts'; Destination = Join-Path $env:USERPROFILE 'Contacts' }
        'Favoritos do Windows' = @{ Backup = 'Favorites'; Destination = Join-Path $env:USERPROFILE 'Favorites' }
        'Imagens' = @{ Backup = 'Pictures'; Destination = [Environment]::GetFolderPath('MyPictures') }
        'Músicas' = @{ Backup = 'Music'; Destination = [Environment]::GetFolderPath('MyMusic') }
        'Vídeos' = @{ Backup = 'Videos'; Destination = [Environment]::GetFolderPath('MyVideos') }
    }
    try {
        try {
            $userShell = Get-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders' -ErrorAction Stop
            if ($userShell.'{374DE290-123F-4565-9164-39C4925E467B}') { $folderMap['Downloads'].Destination = [Environment]::ExpandEnvironmentVariables($userShell.'{374DE290-123F-4565-9164-39C4925E467B}') }
            if ($userShell.'{56784854-C6CB-462B-8169-88E350ACB882}') { $folderMap['Contatos'].Destination = [Environment]::ExpandEnvironmentVariables($userShell.'{56784854-C6CB-462B-8169-88E350ACB882}') }
            if ($userShell.Favorites) { $folderMap['Favoritos do Windows'].Destination = [Environment]::ExpandEnvironmentVariables($userShell.Favorites) }
        } catch { }

        "Restauração iniciada: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')`r`nBackup: $script:backupRoot`r`nDestino: $env:USERDOMAIN\$env:USERNAME`r`n" | Set-Content -LiteralPath $logPath -Encoding UTF8
        $step = 0
        foreach ($label in $selectedItems) {
            $step++
            $status.Text = "Restaurando $label ($step/$($selectedItems.Count))…"
            [System.Windows.Forms.Application]::DoEvents()
            if ($folderMap.Contains($label)) {
                $source = Join-Path $script:backupRoot $folderMap[$label].Backup
                $destination = $folderMap[$label].Destination
                if (-not (Test-Path -LiteralPath $source -PathType Container)) {
                    "PULADO: $label — não encontrado no backup." | Add-Content -LiteralPath $logPath -Encoding UTF8
                    continue
                }
                $null = New-Item -ItemType Directory -Path $destination -Force
                $argumentLine = '"{0}" "{1}" /E /COPY:DAT /DCOPY:DAT /XJ /R:2 /W:2 /FFT "/LOG+:{2}"' -f $source, $destination, $logPath
                $copyProcess = Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\robocopy.exe') -ArgumentList $argumentLine -WindowStyle Hidden -PassThru
                while (-not $copyProcess.HasExited) { [System.Windows.Forms.Application]::DoEvents(); Start-Sleep -Milliseconds 250 }
                $copyProcess.Refresh()
                if ($copyProcess.ExitCode -ge 8) { $failures += $label }
                continue
            }

            if ($label -in @('Favoritos do Edge', 'Favoritos do Chrome')) {
                $browserName = if ($label -eq 'Favoritos do Edge') { 'Edge' } else { 'Chrome' }
                $userDataRoot = if ($browserName -eq 'Edge') { Join-Path $env:LOCALAPPDATA 'Microsoft\Edge\User Data' } else { Join-Path $env:LOCALAPPDATA 'Google\Chrome\User Data' }
                $backupProfiles = Join-Path (Join-Path $script:backupRoot 'Browser-Favorites') $browserName
                if (Test-Path -LiteralPath $backupProfiles -PathType Container) {
                    foreach ($profile in Get-ChildItem -LiteralPath $backupProfiles -Directory -ErrorAction SilentlyContinue) {
                        $targetProfile = Join-Path $userDataRoot $profile.Name
                        if (Test-Path -LiteralPath $targetProfile -PathType Container) {
                            foreach ($fileName in @('Bookmarks', 'Bookmarks.bak')) {
                                $sourceFile = Join-Path $profile.FullName $fileName
                                if (Test-Path -LiteralPath $sourceFile -PathType Leaf) { Copy-Item -LiteralPath $sourceFile -Destination (Join-Path $targetProfile $fileName) -Force }
                            }
                        } else { "PULADO: $browserName perfil $($profile.Name) não existe no computador." | Add-Content -LiteralPath $logPath -Encoding UTF8 }
                    }
                } else { "PULADO: favoritos do $browserName não encontrados no backup." | Add-Content -LiteralPath $logPath -Encoding UTF8 }
                continue
            }

            if ($label -eq 'Favoritos do Firefox') {
                $sourceProfiles = Join-Path (Join-Path $script:backupRoot 'Browser-Favorites') 'Firefox'
                $targetProfiles = Join-Path $env:APPDATA 'Mozilla\Firefox\Profiles'
                if (Test-Path -LiteralPath $sourceProfiles -PathType Container) {
                    foreach ($profile in Get-ChildItem -LiteralPath $sourceProfiles -Directory -ErrorAction SilentlyContinue) {
                        $targetProfile = Join-Path $targetProfiles $profile.Name
                        if (Test-Path -LiteralPath $targetProfile -PathType Container) {
                            foreach ($fileName in @('places.sqlite', 'places.sqlite-wal', 'places.sqlite-shm')) {
                                $sourceFile = Join-Path $profile.FullName $fileName
                                if (Test-Path -LiteralPath $sourceFile -PathType Leaf) { Copy-Item -LiteralPath $sourceFile -Destination (Join-Path $targetProfile $fileName) -Force }
                            }
                            $sourceBackups = Join-Path $profile.FullName 'bookmarkbackups'
                            if (Test-Path -LiteralPath $sourceBackups -PathType Container) {
                                $targetBackups = Join-Path $targetProfile 'bookmarkbackups'
                                $null = New-Item -ItemType Directory -Path $targetBackups -Force
                                Copy-Item -Path (Join-Path $sourceBackups '*') -Destination $targetBackups -Force
                            }
                        } else { "PULADO: Firefox perfil $($profile.Name) não existe no computador." | Add-Content -LiteralPath $logPath -Encoding UTF8 }
                    }
                } else { 'PULADO: favoritos do Firefox não encontrados no backup.' | Add-Content -LiteralPath $logPath -Encoding UTF8 }
                continue
            }

            if ($label -eq 'Perfis e senhas de Wi-Fi') {
                $wifiFolder = Join-Path $script:backupRoot 'WiFi-Profiles'
                $wifiFiles = @(Get-ChildItem -LiteralPath $wifiFolder -Filter '*.xml' -File -ErrorAction SilentlyContinue)
                if ($wifiFiles.Count -eq 0) {
                    'PULADO: nenhum perfil Wi-Fi encontrado no backup.' | Add-Content -LiteralPath $logPath -Encoding UTF8
                } else {
                    foreach ($wifiFile in $wifiFiles) {
                        $netshOutput = & netsh wlan add profile "filename=$($wifiFile.FullName)" user=current 2>&1 | Out-String
                        $netshCode = $LASTEXITCODE
                        if ($netshOutput.Trim()) { $netshOutput.Trim() | Add-Content -LiteralPath $logPath -Encoding UTF8 }
                        if ($netshCode -ne 0) { $failures += "Wi-Fi $($wifiFile.Name)" }
                    }
                }
            }
        }
        if ($failures.Count -eq 0) {
            $status.Text = 'Restauração concluída.'
            [System.Windows.Forms.MessageBox]::Show("Restauração concluída.`r`n`r`nConsulte restore.log na pasta do backup e verifique os arquivos no computador.", 'Restauração concluída', 'OK', 'Information') | Out-Null
        } else {
            $status.Text = 'Restauração concluída com itens para verificar.'
            [System.Windows.Forms.MessageBox]::Show("Alguns itens apresentaram falha: $($failures -join ', ').`r`nConsulte restore.log na pasta do backup.", 'Verifique o registro', 'OK', 'Warning') | Out-Null
        }
    } catch {
        $status.Text = 'Não foi possível concluir a restauração.'
        if ($logPath) { "ERRO: $($_.Exception.Message)" | Add-Content -LiteralPath $logPath -Encoding UTF8 }
        [System.Windows.Forms.MessageBox]::Show("Erro: $($_.Exception.Message)", 'Falha na restauração', 'OK', 'Error') | Out-Null
    } finally {
        $restore.Enabled = $true
        $choose.Enabled = $true
        $close.Enabled = $true
    }
})

[void]$form.ShowDialog()



