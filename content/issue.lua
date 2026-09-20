-- MODELO (dados da edição). Só dados: nenhuma lógica aqui.
return {
  titulo      = "urbanna em revista",
  numero      = 2,
  data        = "Setembro de 2026",
  lema        = "Música, cultura e poder em circulação",

  cor         = nil,   -- hex sem '#', ex.: "1B4F72". nil = gerada a partir do número
  max_imagens = 11,    -- capa + 10 artigos automatizados

  capa_busca  = nil,
  capa_imagem = "assets/cache/auto-01-quando-o-universo-dos-poderosos-contaminou-o-cen-rio-musical.jpeg",
  capa_secao  = "Destaque",
  capa_titulo = "Quando o universo dos poderosos contaminou o cenário musical",
  capa_chamada = "Quando dinheiro, música e influência passam a disputar os mesmos espaços.",

  expediente  = {
    "Direção editorial: Seu Nome",
    "Textos: autoras e autores de cada artigo",
    "Composição: LuaLaTeX · Código-fonte no GitHub",
  },
}
