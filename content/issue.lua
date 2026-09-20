-- MODELO (dados da edição). Só dados: nenhuma lógica aqui.
return {
  titulo      = "Revista Modelo",
  numero      = 1,
  data        = "Setembro de 2026",
  lema        = "Ciência, escrita e código numa só edição",

  cor         = nil,   -- hex sem '#', ex.: "1B4F72". nil = gerada a partir do número
  max_imagens = 2,     -- orçamento TOTAL de imagens (capa + artigos). 0 = revista 100% vetorial

  capa_busca  = nil,   -- termo para a API de imagens (ex.: "night sky"). nil = capa vetorial
  capa_imagem = nil,   -- ou um arquivo local, ex.: "assets/minha-capa.jpg"

  expediente  = {
    "Direção editorial: Seu Nome",
    "Textos: autoras e autores de cada artigo",
    "Composição: LuaLaTeX · Código-fonte no GitHub",
  },
}
