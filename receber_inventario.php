<?php

// ============================================================
// SEATTLE - LR TECNOLOGIA
// Receptor de inventário
// Versão 2.1
//
// Recebe JSON via POST
// Valida chave
// Salva JSON
// Gera relatório HTML
// Mantém histórico
// ============================================================

header('Content-Type: application/json; charset=utf-8');

// ============================================================
// CONFIGURAÇÃO
// ============================================================

// Use aqui a MESMA chave que está no manutencao.ps1
$CHAVE_CORRETA = ')#twPMPaKsj>d23}y3covTxvmr1Ht*EA3iHc=WQQEFVB424H>}';

// Pasta principal
$BASE = __DIR__ . '/resultado_inventario';

// Logo da empresa (fica na raiz do site, fora da pasta seattle)
$LOGO_URL = 'https://lrtecnologia.net.br/logo-lr.png';

// ============================================================
// FUNÇÕES
// ============================================================

function resposta($sucesso, $mensagem, $dados = [])
{
    http_response_code($sucesso ? 200 : 400);

    echo json_encode(
        array_merge(
            [
                'sucesso' => $sucesso,
                'mensagem' => $mensagem
            ],
            $dados
        ),
        JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES
    );

    exit;
}

function escapar($valor)
{
    return htmlspecialchars(
        (string)$valor,
        ENT_QUOTES,
        'UTF-8'
    );
}

function tamanhoClasse($uso)
{
    if ($uso >= 85) {
        return 'critico';
    }

    if ($uso >= 70) {
        return 'atencao';
    }

    return 'normal';
}

function saudeClasse($status)
{
    $ok = ['healthy', 'ok'];

    if (in_array(strtolower((string)$status), $ok, true)) {
        return 'normal';
    }

    return 'critico';
}

// ============================================================
// CONVERSÃO DE DATAS DO POWERSHELL
// ============================================================
// O PowerShell (ConvertTo-Json) salva datas no formato
// "/Date(1786472273500)/", onde o número é a data em
// milissegundos. Esta função detecta esse formato e converte
// para uma data legível. Se o valor já vier em outro formato
// (ou vazio), devolve como está, sem quebrar o relatório.
// ============================================================

function converterDataPS($valor)
{
    if (empty($valor)) {
        return '-';
    }

    if (
        preg_match(
            '/\/Date\((\d+)\)\//',
            (string)$valor,
            $m
        )
    ) {

        $timestamp = (int)($m[1] / 1000);

        return date('d/m/Y H:i:s', $timestamp);
    }

    return (string)$valor;
}

// ============================================================
// SOMENTE POST
// ============================================================

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {

    resposta(
        false,
        'Método não permitido. O SEATTLE deve utilizar POST.'
    );
}

// ============================================================
// VALIDA CHAVE
// ============================================================

$chaveRecebida = $_SERVER['HTTP_X_SEATTLE_KEY'] ?? '';

if (
    empty($chaveRecebida) ||
    !hash_equals($CHAVE_CORRETA, $chaveRecebida)
) {

    resposta(
        false,
        'Chave de acesso inválida.'
    );
}

// ============================================================
// RECEBE JSON
// ============================================================

$conteudo = file_get_contents('php://input');

if (empty($conteudo)) {

    resposta(
        false,
        'Nenhum conteúdo foi recebido.'
    );
}

// ============================================================
// CONVERTE JSON
// ============================================================

$inventario = json_decode($conteudo, true);

if (
    json_last_error() !== JSON_ERROR_NONE ||
    !is_array($inventario)
) {

    resposta(
        false,
        'JSON inválido.'
    );
}

// ============================================================
// IDENTIFICA COMPUTADOR
// ============================================================

$computador = $inventario['computador'] ?? 'DESCONHECIDO';

// Remove caracteres perigosos do nome da pasta
$computadorPasta = preg_replace(
    '/[^a-zA-Z0-9._-]/',
    '_',
    $computador
);

if (empty($computadorPasta)) {
    $computadorPasta = 'DESCONHECIDO';
}

// ============================================================
// CRIA ESTRUTURA
// ============================================================

$pastaPC = $BASE . '/' . $computadorPasta;
$pastaHistorico = $pastaPC . '/historico';

if (!is_dir($pastaHistorico)) {

    if (!mkdir($pastaHistorico, 0755, true)) {

        resposta(
            false,
            'Não foi possível criar a pasta do computador.'
        );
    }
}

// ============================================================
// DATA
// ============================================================

$dataArquivo = date('Ymd_His');

// ============================================================
// JSON
// ============================================================

$arquivoAtualJSON = $pastaPC . '/atual.json';

$arquivoHistoricoJSON =
    $pastaHistorico .
    '/inventario_' .
    $dataArquivo .
    '.json';

$jsonFormatado = json_encode(
    $inventario,
    JSON_PRETTY_PRINT |
    JSON_UNESCAPED_UNICODE |
    JSON_UNESCAPED_SLASHES
);

if (
    file_put_contents(
        $arquivoAtualJSON,
        $jsonFormatado,
        LOCK_EX
    ) === false
) {

    resposta(
        false,
        'Não foi possível salvar o JSON atual.'
    );
}

file_put_contents(
    $arquivoHistoricoJSON,
    $jsonFormatado,
    LOCK_EX
);

// ============================================================
// DADOS PARA HTML
// ============================================================

$usuario = $inventario['usuario'] ?? '-';

$sistema = $inventario['sistema'] ?? [];

$fabricante = $sistema['fabricante'] ?? '-';
$modelo = $sistema['modelo'] ?? '-';
$serial = $sistema['serial'] ?? '-';
$windows = $sistema['windows'] ?? '-';
$build = $sistema['build'] ?? '-';
$boot = converterDataPS($sistema['boot'] ?? null);
$tempoLigado = $sistema['tempo_ligado_horas'] ?? '-';

$processador = $inventario['processador'] ?? [];

$cpu = $processador['modelo'] ?? '-';
$nucleos = $processador['nucleos'] ?? '-';
$threads = $processador['threads'] ?? '-';
$usoCPU = $processador['uso_percentual'] ?? 0;

$memoria = $inventario['memoria'] ?? [];

$ramTotal = $memoria['total_gb'] ?? '-';
$ramLivre = $memoria['livre_gb'] ?? '-';
$ramUso = $memoria['uso_percentual'] ?? 0;

// ------------------------------------------------------------
// Armazenamento: suporta tanto o formato novo
// (armazenamento.discos_fisicos + armazenamento.unidades)
// quanto o formato antigo (armazenamento como lista simples),
// para não quebrar caso algum PC ainda envie dados antigos.
// ------------------------------------------------------------

$armazenamento = $inventario['armazenamento'] ?? [];

if (isset($armazenamento['unidades']) || isset($armazenamento['discos_fisicos'])) {

    $discosFisicos = $armazenamento['discos_fisicos'] ?? [];
    $unidades = $armazenamento['unidades'] ?? [];

}
else {

    // Formato antigo: armazenamento era a própria lista de unidades
    $discosFisicos = [];
    $unidades = is_array($armazenamento) ? $armazenamento : [];
}

$inicializacao = $inventario['inicializacao'] ?? [];

$processos = $inventario['processos'] ?? [];

$eventos = $inventario['eventos'] ?? [];

$alertas = $inventario['alertas'] ?? [];

$dataRelatorio = $inventario['data'] ?? date('Y-m-d H:i:s');

// ============================================================
// HTML
// ============================================================

$html = '<!DOCTYPE html>
<html lang="pt-BR">

<head>

<meta charset="UTF-8">

<meta name="viewport"
content="width=device-width, initial-scale=1.0">

<title>Relatório - ' .
escapar($computador) .
'</title>

<style>

* {
    box-sizing: border-box;
}

body {
    margin: 0;
    padding: 30px;
    background: #f3f4f6;
    font-family: Arial, Helvetica, sans-serif;
    color: #1f2937;
}

.container {
    max-width: 1100px;
    margin: auto;
}

.header {
    background: #111827;
    color: white;
    padding: 28px;
    border-radius: 14px;
    margin-bottom: 20px;
    display: flex;
    align-items: center;
    gap: 20px;
}

.header img {
    height: 56px;
    width: auto;
    border-radius: 8px;
    background: white;
    padding: 6px;
}

.header-texto h1 {
    margin: 0 0 8px 0;
    font-size: 26px;
}

.header-texto p {
    margin: 4px 0;
    color: #d1d5db;
}

.card {
    background: white;
    padding: 22px;
    border-radius: 14px;
    margin-bottom: 18px;
    box-shadow: 0 2px 8px rgba(0,0,0,.06);
}

.card h2 {
    margin-top: 0;
    font-size: 19px;
    border-bottom: 1px solid #e5e7eb;
    padding-bottom: 10px;
}

.grid {
    display: grid;
    grid-template-columns:
        repeat(auto-fit, minmax(220px, 1fr));
    gap: 12px;
}

.item {
    background: #f9fafb;
    padding: 14px;
    border-radius: 10px;
}

.label {
    font-size: 12px;
    color: #6b7280;
    margin-bottom: 5px;
}

.value {
    font-weight: bold;
    word-break: break-word;
}

table {
    width: 100%;
    border-collapse: collapse;
}

th,
td {
    text-align: left;
    padding: 11px;
    border-bottom: 1px solid #e5e7eb;
}

th {
    background: #f9fafb;
}

.normal {
    color: #15803d;
    font-weight: bold;
}

.atencao {
    color: #b45309;
    font-weight: bold;
}

.critico {
    color: #dc2626;
    font-weight: bold;
}

.alerta {
    background: #fff7ed;
    border-left: 5px solid #f97316;
    padding: 12px;
    margin-bottom: 8px;
    border-radius: 6px;
}

.ok {
    background: #f0fdf4;
    border-left: 5px solid #16a34a;
    padding: 14px;
    border-radius: 6px;
    color: #166534;
    font-weight: bold;
}

.footer {
    text-align: center;
    color: #6b7280;
    font-size: 12px;
    margin-top: 25px;
}

.subtitulo {
    font-size: 13px;
    color: #6b7280;
    margin: 18px 0 10px 0;
}

@media print {

    body {
        background: white;
        padding: 0;
    }

    .card {
        box-shadow: none;
        border: 1px solid #ddd;
    }

}

</style>

</head>

<body>

<div class="container">

<div class="header">

<img src="' .
escapar($LOGO_URL) .
'" alt="LR Tecnologia">

<div class="header-texto">

<h1>Robô LR Tecnologia</h1>

<p><strong>Relatório de Diagnóstico Preventivo</strong></p>

<p>Computador: ' .
escapar($computador) .
'</p>

<p>Data: ' .
escapar($dataRelatorio) .
'</p>

</div>

</div>';

// ============================================================
// IDENTIFICAÇÃO
// ============================================================

$html .= '

<div class="card">

<h2>Identificação</h2>

<div class="grid">

<div class="item">
<div class="label">Computador</div>
<div class="value">' .
escapar($computador) .
'</div>
</div>

<div class="item">
<div class="label">Usuário</div>
<div class="value">' .
escapar($usuario) .
'</div>
</div>

<div class="item">
<div class="label">Fabricante</div>
<div class="value">' .
escapar($fabricante) .
'</div>
</div>

<div class="item">
<div class="label">Modelo</div>
<div class="value">' .
escapar($modelo) .
'</div>
</div>

<div class="item">
<div class="label">Número de série</div>
<div class="value">' .
escapar($serial) .
'</div>
</div>

</div>

</div>';

// ============================================================
// WINDOWS
// ============================================================

$html .= '

<div class="card">

<h2>Sistema operacional</h2>

<div class="grid">

<div class="item">
<div class="label">Windows</div>
<div class="value">' .
escapar($windows) .
'</div>
</div>

<div class="item">
<div class="label">Build</div>
<div class="value">' .
escapar($build) .
'</div>
</div>

<div class="item">
<div class="label">Último boot</div>
<div class="value">' .
escapar($boot) .
'</div>
</div>

<div class="item">
<div class="label">Tempo ligado</div>
<div class="value">' .
escapar($tempoLigado) .
' horas</div>
</div>

</div>

</div>';

// ============================================================
// HARDWARE
// ============================================================

$html .= '

<div class="card">

<h2>Hardware</h2>

<div class="grid">

<div class="item">
<div class="label">Processador</div>
<div class="value">' .
escapar($cpu) .
'</div>
</div>

<div class="item">
<div class="label">Núcleos</div>
<div class="value">' .
escapar($nucleos) .
'</div>
</div>

<div class="item">
<div class="label">Threads</div>
<div class="value">' .
escapar($threads) .
'</div>
</div>

<div class="item">
<div class="label">Uso da CPU</div>
<div class="value ' .
tamanhoClasse($usoCPU) .
'">' .
escapar($usoCPU) .
'%</div>
</div>

<div class="item">
<div class="label">Memória RAM</div>
<div class="value">' .
escapar($ramTotal) .
' GB</div>
</div>

<div class="item">
<div class="label">RAM em uso</div>
<div class="value ' .
tamanhoClasse($ramUso) .
'">' .
escapar($ramUso) .
'%</div>
</div>

<div class="item">
<div class="label">RAM livre</div>
<div class="value">' .
escapar($ramLivre) .
' GB</div>
</div>

</div>

</div>';

// ============================================================
// ARMAZENAMENTO - DISCOS FÍSICOS (hardware, saúde)
// ============================================================

$html .= '

<div class="card">

<h2>Armazenamento</h2>

<p class="subtitulo">Discos físicos (hardware)</p>

<table>

<thead>

<tr>
<th>Fabricante</th>
<th>Modelo</th>
<th>Tipo</th>
<th>Interface</th>
<th>Capacidade</th>
<th>Saúde</th>
<th>Vida restante</th>
</tr>

</thead>

<tbody>
';

if (count($discosFisicos) > 0) {

    foreach ($discosFisicos as $disco) {

        $vida = $disco['VidaRestantePct'] ?? null;

        $html .= '
<tr>

<td>' .
escapar($disco['Fabricante'] ?? '-') .
'</td>

<td>' .
escapar($disco['Modelo'] ?? '-') .
'</td>

<td>' .
escapar($disco['Tipo'] ?? '-') .
'</td>

<td>' .
escapar($disco['Interface'] ?? '-') .
'</td>

<td>' .
escapar($disco['CapacidadeGB'] ?? '-') .
' GB</td>

<td class="' .
saudeClasse($disco['SaudeStatus'] ?? '') .
'">' .
escapar($disco['SaudeStatus'] ?? '-') .
'</td>

<td>' .
($vida !== null ? escapar($vida) . '%' : '-') .
'</td>

</tr>';
    }

}
else {

    $html .= '
<tr>
<td colspan="7">Nenhuma informação de disco físico disponível.</td>
</tr>';
}

$html .= '

</tbody>

</table>

<p class="subtitulo">Unidades (espaço em disco)</p>

<table>

<thead>

<tr>
<th>Unidade</th>
<th>Tamanho</th>
<th>Livre</th>
<th>Uso</th>
</tr>

</thead>

<tbody>
';

if (count($unidades) > 0) {

    foreach ($unidades as $disco) {

        $uso = $disco['Uso'] ?? 0;

        $html .= '
<tr>

<td>' .
escapar($disco['Unidade'] ?? '-') .
'</td>

<td>' .
escapar($disco['TamanhoGB'] ?? '-') .
' GB</td>

<td>' .
escapar($disco['LivreGB'] ?? '-') .
' GB</td>

<td class="' .
tamanhoClasse($uso) .
'">' .
escapar($uso) .
'%</td>

</tr>';
    }

}
else {

    $html .= '
<tr>
<td colspan="4">Nenhuma unidade encontrada.</td>
</tr>';
}

$html .= '

</tbody>

</table>

</div>';

// ============================================================
// INICIALIZAÇÃO
// ============================================================

$html .= '

<div class="card">

<h2>Programas iniciados com o Windows</h2>

<p>
<strong>Quantidade:</strong>
' .
escapar($inicializacao['quantidade'] ?? 0) .
'
</p>

<table>

<thead>
<tr>
<th>Nome</th>
<th>Comando</th>
</tr>
</thead>

<tbody>
';

foreach (
    ($inicializacao['programas'] ?? []) as $item
) {

    $html .= '
<tr>

<td>' .
escapar($item['Name'] ?? '-') .
'</td>

<td>' .
escapar($item['Command'] ?? '-') .
'</td>

</tr>';
}

$html .= '

</tbody>

</table>

</div>';

// ============================================================
// PROCESSOS
// ============================================================

$html .= '

<div class="card">

<h2>Processos com maior consumo de memória</h2>

<table>

<thead>
<tr>
<th>Processo</th>
<th>Memória</th>
</tr>
</thead>

<tbody>
';

foreach ($processos as $processo) {

    $html .= '
<tr>

<td>' .
escapar($processo['Processo'] ?? '-') .
'</td>

<td>' .
escapar($processo['MemoriaMB'] ?? '-') .
' MB</td>

</tr>';
}

$html .= '

</tbody>

</table>

</div>';

// ============================================================
// EVENTOS
// ============================================================

$html .= '

<div class="card">

<h2>Eventos do Windows</h2>

<table>

<thead>

<tr>
<th>Data</th>
<th>ID</th>
<th>Origem</th>
</tr>

</thead>

<tbody>
';

foreach ($eventos as $evento) {

    $html .= '
<tr>

<td>' .
escapar(converterDataPS($evento['Data'] ?? null)) .
'</td>

<td>' .
escapar($evento['ID'] ?? '-') .
'</td>

<td>' .
escapar($evento['Origem'] ?? '-') .
'</td>

</tr>';
}

$html .= '

</tbody>

</table>

</div>';

// ============================================================
// ALERTAS
// ============================================================

$html .= '

<div class="card">

<h2>Diagnóstico preventivo</h2>
';

if (count($alertas) > 0) {

    foreach ($alertas as $alerta) {

        $html .= '
<div class="alerta">
⚠️ ' .
escapar($alerta) .
'
</div>';
    }

}
else {

    $html .= '
<div class="ok">
✅ Nenhuma anomalia preventiva identificada.
</div>';
}

$html .= '

</div>';

// ============================================================
// RODAPÉ
// ============================================================

$html .= '

<div class="footer">

Relatório gerado automaticamente pelo
<strong>Seattle - LR Tecnologia</strong>.

</div>

</div>

</body>

</html>
';

// ============================================================
// SALVA HTML ATUAL
// ============================================================

$arquivoAtualHTML = $pastaPC . '/atual.html';

$arquivoHistoricoHTML =
    $pastaHistorico .
    '/inventario_' .
    $dataArquivo .
    '.html';

if (
    file_put_contents(
        $arquivoAtualHTML,
        $html,
        LOCK_EX
    ) === false
) {

    resposta(
        false,
        'JSON salvo, mas não foi possível salvar o HTML.'
    );
}

file_put_contents(
    $arquivoHistoricoHTML,
    $html,
    LOCK_EX
);

// ============================================================
// RESPOSTA
// ============================================================

resposta(
    true,
    'Inventário recebido e armazenado com sucesso.',
    [
        'computador' => $computador,
        'arquivo_json' => 'atual.json',
        'arquivo_html' => 'atual.html',
        'historico_json' =>
            'historico/inventario_' .
            $dataArquivo .
            '.json',
        'historico_html' =>
            'historico/inventario_' .
            $dataArquivo .
            '.html'
    ]
);
