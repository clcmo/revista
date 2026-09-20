# Revista em LuaLaTeX (MVVM)

Modelo de revista em PDF. Os artigos são arquivos Markdown; o GitHub compila com LuaLaTeX
e publica o PDF numa página (GitHub Pages).

## Arquitetura MVVM

| Camada        | Onde                                        | Responsabilidade                                                                 |
|---------------|---------------------------------------------|----------------------------------------------------------------------------------|
| **Model**     | `content/`, `assets/images.lock.lua`, `lua/model.lua` | Dados: artigos (Markdown + cabeçalho), dados da edição, registro de imagens. |
| **ViewModel** | `lua/viewmodel.lua`, `lua/md.lua`           | Lógica: ordenar, agrupar seções, converter Markdown, orçamento de imagens, créditos, tempo de leitura. |
| **View**      | `revista.cls`, `main.tex`                   | Apenas desenho: capa, sumário, página de artigo, colofão.                         |

A View nunca lê arquivos: ela usa macros (`\ArtTitulo`, `\ArtCorpo`, `\RevCor`...) que o ViewModel
define a cada artigo. Trocar o visual = editar só `revista.cls`.

## Escrever um artigo

Crie `content/artigos/NN-nome.md`:

```markdown
---
titulo: Título do artigo
autor: Nome
secao: Reportagem
ordem: 4
resumo: Uma linha de chamada.
imagem: termo de busca em inglês      # opcional (API)
# imagem_arquivo: assets/foto.jpg     # opcional (arquivo próprio)
# publicar: nao                       # tira da edição
---
Texto em Markdown: **negrito**, *itálico*, `código`, [links](https://exemplo.org),
listas, citações (`>`), intertítulos (`##`) e separador (`---`).
```

Artigos da mesma seção devem ter `ordem` consecutiva (o sumário agrupa quando a seção muda).

## Poucas imagens, por design

1. `max_imagens` em `content/issue.lua` é o orçamento **total** da edição (capa + artigos). `0` = tudo vetorial.
2. A capa é vetorial (TikZ) se não houver imagem.
3. `scripts/fetch_images.py` busca por API **só o que cabe no orçamento**, guarda em `assets/cache/`
   e registra autoria e licença em `assets/images.lock.json` / `.lua`. O crédito sai impresso na página.
4. O LaTeX nunca acessa a rede: a compilação é reproduzível.

Provedores: Openverse (sem chave) ou Unsplash (defina `UNSPLASH_ACCESS_KEY`).

## Importar conteúdo de sites

Edite `content/sources.json` para informar feeds RSS/Atom e APIs JSON. Os
artigos importados recebem o prefixo `auto-`; artigos escritos à mão não são
alterados.

Exemplo de feed:

```json
{
   "max_artigos": 10,
   "feeds": [
      {"url": "https://exemplo.org/feed.xml", "secao": "Notícias"}
   ],
   "apis": []
}
```

Exemplo de API JSON:

```json
{
   "max_artigos": 10,
   "feeds": [],
   "apis": [{
      "url": "https://exemplo.org/api/posts",
      "items_path": "items",
      "secao": "Atualizações",
      "fields": {
         "title": "title",
         "url": "url",
         "summary": "excerpt",
         "content": "body",
         "author": "author.name",
         "image": "image.url"
      }
   }]
}
```

O script consulta o RSS/API, busca a página original quando necessário, extrai
texto e `og:image`/`twitter:image`, baixa a imagem para `assets/cache/` e cria
os Markdown antes da compilação. Para APIs autenticadas, use um endpoint
somente leitura ou adapte os headers sem colocar tokens no repositório.

## Compilar localmente

```bash
latexmk -lualatex main.tex        # ou: lualatex main.tex (duas vezes)
   python3 scripts/fetch_content.py  # importa RSS/APIs configurados
python3 scripts/fetch_images.py   # opcional: baixa imagens do orçamento
```

Requer TeX Live com LuaLaTeX, `babel-portuges` e as fontes TeX Gyre (já vêm no TeX Live completo).

## Publicar no GitHub

1. Suba o repositório e ative **Settings → Pages → Source: GitHub Actions**.
2. A cada `push` na `main`, `.github/workflows/build.yml` compila e publica o PDF em
   `https://SEU-USUARIO.github.io/NOME-DO-REPO/` (o arquivo é `revista.pdf`).
3. O PDF também fica disponível como *artifact* de cada execução.
4. Para imagens: **Actions → Buscar imagens da edição → Run workflow** (opcional: secret `UNSPLASH_ACCESS_KEY`).
