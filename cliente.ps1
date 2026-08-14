# ============================================================
# SEATTLE - LR TECNOLOGIA
# MÓDULO DE IDENTIFICAÇÃO DO CLIENTE
# Versão 1.0.0
# ============================================================

function Mostrar-Cabecalho-Cliente {

    Clear-Host

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host "                 DIAGNÓSTICO LR TECNOLOGIA" -ForegroundColor Cyan
    Write-Host "============================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Ler-Tecla {

    param(
        [string]$Mensagem = "Escolha uma opção:"
    )

    Write-Host ""
    Write-Host $Mensagem -ForegroundColor Yellow

    $tecla = [System.Console]::ReadKey($true)

    return $tecla.KeyChar
}

function Normalizar-NomeCliente {

    param(
        [string]$Nome
    )

    if ([string]::IsNullOrWhiteSpace($Nome)) {
        return "CLIENTE_NAO_INFORMADO"
    }

    # Remove caracteres que podem causar problemas em nomes
    # de pastas no Windows e na hospedagem.
    $Nome = $Nome.Trim()

    $Nome = $Nome -replace '[\\/:*?"<>|]', '_'

    $Nome = $Nome -replace '\s+', ' '

    return $Nome
}

function Selecionar-ClienteContrato {

    while ($true) {

        Mostrar-Cabecalho-Cliente

        Write-Host "                    CONTRATO MENSAL" -ForegroundColor Green
        Write-Host ""

        Write-Host "1 - A Casa do Panificador"
        Write-Host "2 - Escritório Real de Contabilidade"
        Write-Host "3 - Impacto Contabilidade"
        Write-Host "4 - Futura Contabilidade"
        Write-Host "0 - Voltar"
        Write-Host ""

        $tecla = Ler-Tecla

        switch ($tecla) {

            "1" {
                return @{
                    Nome = "A Casa do Panificador"
                    Tipo = "Contrato Mensal"
                }
            }

            "2" {
                return @{
                    Nome = "Escritório Real de Contabilidade"
                    Tipo = "Contrato Mensal"
                }
            }

            "3" {
                return @{
                    Nome = "Impacto Contabilidade"
                    Tipo = "Contrato Mensal"
                }
            }

            "4" {
                return @{
                    Nome = "Futura Contabilidade"
                    Tipo = "Contrato Mensal"
                }
            }

            "0" {
                return $null
            }
        }
    }
}

function Selecionar-ClienteParticular {

    Mostrar-Cabecalho-Cliente

    Write-Host "                 SEM CONTRATO / PARTICULAR" -ForegroundColor Green
    Write-Host ""

    do {

        $nome = Read-Host "Digite o nome do cliente"

        if ([string]::IsNullOrWhiteSpace($nome)) {

            Write-Host ""
            Write-Host "O nome do cliente não pode ficar vazio." -ForegroundColor Red
            Write-Host ""

        }

    } while ([string]::IsNullOrWhiteSpace($nome))

    return @{
        Nome = Normalizar-NomeCliente $nome
        Tipo = "Sem Contrato / Particular"
    }
}

function Selecionar-ClienteNovo {

    Mostrar-Cabecalho-Cliente

    Write-Host "                       CLIENTE NOVO" -ForegroundColor Green
    Write-Host ""

    do {

        $nome = Read-Host "Digite o nome do cliente"

        if ([string]::IsNullOrWhiteSpace($nome)) {

            Write-Host ""
            Write-Host "O nome do cliente não pode ficar vazio." -ForegroundColor Red
            Write-Host ""

        }

    } while ([string]::IsNullOrWhiteSpace($nome))

    return @{
        Nome = Normalizar-NomeCliente $nome
        Tipo = "Cliente Novo"
    }
}

function Selecionar-Cliente {

    while ($true) {

        Mostrar-Cabecalho-Cliente

        Write-Host "1 - Cliente Existente"
        Write-Host "2 - Cliente Novo"
        Write-Host "0 - Voltar"
        Write-Host ""

        $tecla = Ler-Tecla

        switch ($tecla) {

            "1" {

                while ($true) {

                    Mostrar-Cabecalho-Cliente

                    Write-Host "                  CLIENTE EXISTENTE" -ForegroundColor Green
                    Write-Host ""

                    Write-Host "1 - Contrato Mensal"
                    Write-Host "2 - Sem Contrato / Particular"
                    Write-Host "0 - Voltar"
                    Write-Host ""

                    $subTecla = Ler-Tecla

                    switch ($subTecla) {

                        "1" {

                            $cliente = Selecionar-ClienteContrato

                            if ($null -ne $cliente) {
                                return $cliente
                            }

                        }

                        "2" {

                            return Selecionar-ClienteParticular
                        }

                        "0" {

                            break
                        }
                    }
                }
            }

            "2" {

                return Selecionar-ClienteNovo
            }

            "0" {

                return $null
            }
        }
    }
}
