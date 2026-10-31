# Unleashed PTBR — atualizações pelo HMM

Tradução por Oitikq. Página do mod: https://gamebanana.com/mods/733539

Este repositório hospeda os arquivos consumidos pelo atualizador do Hedge Mod Manager. O endereço configurado no mod é:

```
https://raw.githubusercontent.com/Oitikq/Unleashed-PTBR-Updates/main/UnleashedPTBR/
```

A versão inicial publicada é 1.1.1, com compatibilidade opcional com Foreign Input. O anúncio no GameBanana e a publicação neste servidor são passos separados.

## Publicar uma próxima versão

1. Prepare e teste a nova versão do mod, incluindo os dois estados da compatibilidade.
2. Atualize os arquivos em UnleashedPTBR e mantenha as cópias antigas necessárias para usuários de versões anteriores.
3. Registre os arquivos necessários em mod_files.txt. Use add para baixar e delete para remover caminhos antigos. Mantenha add mod.ini no final.
4. Atualize Version no mod.ini, VersionString no mod_version.ini, DownloadSizeString e changelog.md. Confira as configurações padrão: o mod.ini distribuído começa com a compatibilidade desativada.
5. Publique todos os arquivos e metadados no mesmo commit. Teste com uma instalação de uma versão anterior antes de anunciar no GameBanana.

O manifesto atual oferece o pacote completo. O HMM não acompanha automaticamente os uploads do GameBanana. A substituição de mod.ini pode restaurar a opção de compatibilidade ao padrão; confira essa opção após atualizar. Não use Git LFS para estes downloads: o HMM precisa receber os arquivos binários reais.
