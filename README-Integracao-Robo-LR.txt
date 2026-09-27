INTEGRACAO DE BACKUP E RESTAURACAO NO SEATTLE / ROBO LR

Arquivos:
- lr.ps1: versão do menu principal com a opção 6.
- backup.ps1: submenu que abre backup ou restauração.
- Backup-Perfil-Windows.ps1: cria o backup no HD externo.
- Restaurar-Perfil-Windows.ps1: restaura categorias selecionadas nos locais correspondentes.

Pastas adicionais:
Na ferramenta de backup, use “Adicionar pasta…” para selecionar uma ou mais pastas
de qualquer unidade. O conteúdo é salvo em Custom-Folders e o índice
Custom-Folders.json registra o caminho original. Na restauração, marque a pasta
extra desejada para copiá-la de volta ao caminho exibido.

Publicação:
Coloque os quatro arquivos .ps1 na raiz do repositório leoklyvert/seattle e publique as alterações na branch main. Depois, ao abrir o Seattle e escolher 6, o robô carregará o submenu. Os scripts auxiliares são baixados do repositório para uma pasta temporária única e removidos ao sair.

Segurança:
Os perfis Wi-Fi exportados contêm senhas em texto legível no HD. A restauração pode substituir arquivos de mesmo nome. O Firefox pode restaurar histórico junto com favoritos.
