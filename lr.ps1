Skip to content
leoklyvert
seattle
Repository navigation
Code
Issues
Pull requests
Agents
Actions
Projects
Security and quality
Insights
Settings
Files
Go to file
t
T
README.md
lr.ps1
office.ps1
personalizacao.ps1
programas.ps1
seattle
/
lr.ps1
in
main

Edit

Preview
Indent mode

Spaces
Indent size

4
Line wrap mode

No wrap
Editing lr.ps1 file contents
  1
  2
  3
  4
  5
  6
  7
  8
  9
 10
 11
 12
 13
 14
 15
 16
 17
 18
 19
 20
 21
 22
 23
 24
 25
 26
 27
 28
 29
 30
 31
 32
 33
 34
 35
 36
# ============================================================
# LR TECNOLOGIA
# Assistente Técnico
# ============================================================

Clear-Host

while ($true) {

    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host "             LR TECNOLOGIA" -ForegroundColor Cyan
    Write-Host "          ASSISTENTE TECNICO" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "1 - Instalacao de Programas"
    Write-Host "2 - Instalar Office"
    Write-Host "0 - Sair"
    Write-Host ""
    Write-Host "Escolha uma opcao:" -ForegroundColor Yellow

    # Aguarda apenas uma tecla.
    # Nao precisa pressionar ENTER.
    $Tecla = [System.Console]::ReadKey($true)

    switch ($Tecla.KeyChar) {

        "1" {

            Clear-Host

            Write-Host ""
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host "       INSTALACAO DE PROGRAMAS" -ForegroundColor Cyan
            Write-Host "============================================" -ForegroundColor Cyan
            Write-Host ""
Use Control + Shift + m to toggle the tab key moving focus. Alternatively, use esc then tab to move to the next interactive element on the page.
 
