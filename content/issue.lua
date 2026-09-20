-- MODELO (dados da edição). Só dados: nenhuma lógica aqui.
return {
  titulo      = "urbanna em revista",
  numero      = 1,
  data        = "Setembro de 2026",
  lema        = "Música, cultura e poder em circulação",

  cor         = "B4492F",   -- terracota do tema urbanna
  max_imagens = 11,    -- orçamento total; a foto do destaque na capa e no artigo conta uma vez só

  -- Destaque: aberto em 2 páginas e usado na capa (foto, título e chamada vêm dele).
  -- Aceita prefixo do arquivo ("auto-01" = post mais recente importado) ou posição (número).
  -- Também vale `destaque: sim` no cabeçalho de um artigo. Sem nada, usa o 1º artigo com imagem.
  destaque    = "auto-01",

  capa_busca  = nil,
  capa_molde  = "assets/cover/capa_molde.png",
  capa_secao  = "Destaque",
  capa_chamada = "Quando dinheiro, música e influência passam a disputar os mesmos espaços.",

  expediente  = {
    "Direção editorial: Camila L. Oliveira",
    "Textos: autoras e autores de cada artigo",
    "Composição: LuaLaTeX · Código-fonte no GitHub",
  },
}
