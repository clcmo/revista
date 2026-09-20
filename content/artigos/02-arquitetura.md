---
titulo: Como esta revista é montada
autor: Seu Nome
secao: Bastidores
ordem: 2
resumo: Model, ViewModel e View aplicados a um documento LaTeX.
imagem: abstract geometric pattern
---
A arquitetura segue o padrão **MVVM**, adaptado a um documento.

- **Model:** os arquivos Markdown, a edição (`issue.lua`) e o registro de imagens.
- **ViewModel:** scripts em Lua que ordenam, convertem e decidem o que vai para a página.
- **View:** a classe `revista.cls`, que só define o desenho.

## Poucas imagens, por decisão de projeto

A edição tem um *orçamento* de imagens. Quando ele acaba, o ViewModel ignora o excesso e avisa no log. A capa e os destaques podem ser vetoriais, então uma revista sem nenhuma foto continua bonita.

### Créditos

Toda imagem baixada por API carrega autoria e licença, e o crédito sai impresso automaticamente. Veja a documentação do [Openverse](https://openverse.org) para conhecer as licenças.

1. Escreva o artigo.
2. Envie para o GitHub.
3. Baixe o PDF publicado.

---

Fim do artigo de exemplo, com símbolos especiais: 100% de cobertura, R$ 5 & mais, snake_case e #hashtag.
