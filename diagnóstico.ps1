# ============================================================
# IDENTIFICAÇÃO DO CLIENTE
# ============================================================

$cliente = Selecionar-Cliente

if ($null -eq $cliente) {

    Write-Host ""
    Write-Host "Diagnóstico cancelado." -ForegroundColor Yellow
    Write-Host ""

    return
}
