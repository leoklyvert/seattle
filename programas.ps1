# ============================================================
# LR TECNOLOGIA
# Instalação e Atualização de Programas
# ============================================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "           LR TECNOLOGIA" -ForegroundColor Cyan
Write-Host "      INSTALAÇÃO DE PROGRAMAS" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# INSTALAÇÃO DOS PROGRAMAS
# ============================================================

Write-Host "Iniciando instalação dos programas..." -ForegroundColor Yellow
Write-Host ""

# WhatsApp Beta
Write-Host "[1/13] Instalando WhatsApp Beta..." -ForegroundColor White
winget install --id=9NKSQGP7F2NH --source=msstore --exact --accept-package-agreements --accept-source-agreements

# VLC Media Player
Write-Host "[2/13] Instalando VLC Media Player..." -ForegroundColor White
winget install --id=VideoLAN.VLC --source=winget --exact --silent --accept-package-agreements --accept-source-agreements

# Avast Free Antivirus
Write-Host "[3/13] Instalando Avast Free Antivirus..." -ForegroundColor White
winget install --id=Avast.AvastFreeAntivirus --source=winget --exact --accept-package-agreements --accept-source-agreements

# CPUID HWMonitor
Write-Host "[4/13] Instalando CPUID HWMonitor..." -ForegroundColor White
winget install --id=CPUID.HWMonitor --source=winget --exact --accept-package-agreements --accept-source-agreements

# AnyDesk
Write-Host "[5/13] Instalando AnyDesk..." -ForegroundColor White
winget install --id=AnyDesk.AnyDesk -e --silent

# 7-Zip
Write-Host "[6/13] Instalando 7-Zip..." -ForegroundColor White
winget install --id=7zip.7zip -e --silent

# Mozilla Firefox
Write-Host "[7/13] Instalando Mozilla Firefox..." -ForegroundColor White
winget install --id=Mozilla.Firefox -e --silent

# Google Chrome
Write-Host "[8/13] Instalando Google Chrome..." -ForegroundColor White
winget install --id=Google.Chrome -e --silent

# Adobe Acrobat Reader
Write-Host "[9/13] Instalando Adobe Acrobat Reader..." -ForegroundColor White
winget install --id=Adobe.Acrobat.Reader.64-bit -e --silent

# Java x86
Write-Host "[10/13] Instalando Java x86..." -ForegroundColor White
winget install --id=Oracle.JavaRuntimeEnvironment --architecture x86 -e --silent

# Driver Booster
Write-Host "[11/13] Instalando Driver Booster..." -ForegroundColor White
winget install --id=IObit.DriverBooster -e --silent

# Lightshot
Write-Host "[12/13] Instalando Lightshot..." -ForegroundColor White
winget install --id=Skillbrains.Lightshot -e --silent

# Zoom
Write-Host "[13/13] Instalando Zoom..." -ForegroundColor White
winget install --id=Zoom.Zoom -e --silent --accept-package-agreements --accept-source-agreements


# ============================================================
# ATUALIZAÇÃO DOS APLICATIVOS INSTALADOS
# ============================================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "      ATUALIZAÇÃO DOS APLICATIVOS" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Verificando atualizações disponíveis..." -ForegroundColor Yellow
Write-Host ""

winget upgrade --all --silent --accept-package-agreements --accept-source-agreements


# ============================================================
# FINALIZAÇÃO
# ============================================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "       OPERAÇÃO CONCLUÍDA" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""