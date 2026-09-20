-- VIEWMODEL: transforma o Model em estado pronto para a View.
-- Regras de negócio moram aqui: ordenação, seções, orçamento de imagens,
-- tempo de leitura, créditos, cor da edição. A View (revista.cls) só desenha.
local model = dofile("lua/model.lua")
local md    = dofile("lua/md.lua")

local M = {}
local dados, estado = nil, { orcamento = 0, secao_anterior = nil }

-- Envia um valor ao TeX como macro global (a View lê \Nome).
local function definir(nome, valor)
  valor = tostring(valor or "")
  valor = valor:gsub("\n\n+", " \\par "):gsub("\n", " ")
  tex.sprint("\\long\\gdef\\" .. nome .. "{" .. valor .. "}")
end

local function aviso(msg) texio.write_nl("VIEWMODEL: " .. msg) end

local function hsv_hex(h, s, v)
  local c = v * s
  local x = c * (1 - math.abs((h / 60) % 2 - 1))
  local m = v - c
  local r, g, b
  if     h < 60  then r, g, b = c, x, 0
  elseif h < 120 then r, g, b = x, c, 0
  elseif h < 180 then r, g, b = 0, c, x
  elseif h < 240 then r, g, b = 0, x, c
  elseif h < 300 then r, g, b = x, 0, c
  else                r, g, b = c, 0, x end
  return string.format("%02X%02X%02X",
    math.floor((r + m) * 255 + .5), math.floor((g + m) * 255 + .5), math.floor((b + m) * 255 + .5))
end

-- Decide se uma imagem entra, respeitando o orçamento da edição.
local function resolver_imagem(chave, local_arquivo)
  local arquivo, credito
  if local_arquivo and local_arquivo ~= "" then
    arquivo = local_arquivo
  elseif dados.imagens[chave] then
    local i = dados.imagens[chave]
    arquivo = i.arquivo
    credito = string.format("Imagem: %s (%s, via %s)",
      i.criador or "autoria desconhecida", i.licenca or "licença n/d", i.fonte or "n/d")
  end
  if not arquivo then return nil end
  if not model.existe(arquivo) then aviso("arquivo de imagem não encontrado: " .. arquivo); return nil end
  if estado.orcamento <= 0 then aviso("orçamento de imagens esgotado; ignorando " .. arquivo); return nil end
  estado.orcamento = estado.orcamento - 1
  return arquivo, credito
end

function M.iniciar()
  dados = model.carregar()
  local ed = dados.issue
  estado.orcamento = ed.max_imagens or 0

  table.sort(dados.artigos, function(a, b)
    local oa, ob = tonumber(a.meta.ordem) or 999, tonumber(b.meta.ordem) or 999
    if oa ~= ob then return oa < ob end
    return a.arquivo < b.arquivo
  end)

  -- A capa vem primeiro na fila do orçamento; depois os artigos, em ordem.
  local capa, capa_cred = resolver_imagem("capa", ed.capa_imagem)
  for _, a in ipairs(dados.artigos) do
    a.imagem, a.credito = resolver_imagem(a.meta.slug, a.meta.imagem_arquivo)
  end

  local numero = tonumber(ed.numero) or 1
  definir("RevTitulo",     md.escapar(ed.titulo or "Revista"))
  definir("RevNumero",     md.escapar(numero))
  definir("RevData",       md.escapar(ed.data or ""))
  definir("RevLema",       md.inline(ed.lema or ""))
  definir("RevCor",        ed.cor or hsv_hex((numero * 47) % 360, .55, .50))
  definir("RevSemente",    numero % 7 + 2)
  definir("RevCapaImagem", capa or "")
  definir("RevCapaCredito", md.escapar(capa_cred or ""))
  definir("RevNumArtigos", #dados.artigos)
  local exp = {}
  for _, linha in ipairs(ed.expediente or {}) do exp[#exp + 1] = md.inline(linha) end
  definir("RevExpediente", table.concat(exp, "\n\n"))
end

function M.selecionar(i)
  local a = dados.artigos[i]
  local m = a.meta
  local palavras = 0
  for _ in a.corpo:gmatch("%S+") do palavras = palavras + 1 end

  local secao = m.secao or ""
  tex.sprint(secao ~= estado.secao_anterior and "\\ArtNovaSecaotrue" or "\\ArtNovaSecaofalse")
  estado.secao_anterior = secao

  definir("ArtTitulo",  md.inline(m.titulo or m.slug))
  definir("ArtAutor",   md.inline(m.autor or ""))
  definir("ArtSecao",   md.inline(secao))
  definir("ArtResumo",  md.inline(m.resumo or ""))
  definir("ArtLeitura", math.max(1, math.floor(palavras / 200 + .5)))
  definir("ArtImagem",  a.imagem or "")
  definir("ArtCredito", md.escapar(a.credito or ""))
  definir("ArtCorpo",   md.converter(a.corpo))
end

return M
