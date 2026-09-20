-- VIEWMODEL (parte 1): converte um subconjunto de Markdown em LaTeX seguro.
-- Suporta: parágrafos, #/##/### (intertítulos), **negrito**, *itálico*, `código`,
-- [texto](url), listas (- e 1.), citações (>), separador (---).
-- Imagens NÃO entram pelo texto: vêm do campo `imagem:` (orçamento controlado).
local M = {}

local especiais = {
  ["\\"] = "\\textbackslash{}", ["&"] = "\\&", ["%"] = "\\%", ["$"] = "\\$",
  ["#"] = "\\#", ["_"] = "\\_", ["{"] = "\\{", ["}"] = "\\}",
  ["~"] = "\\textasciitilde{}", ["^"] = "\\textasciicircum{}",
}

function M.escapar(s)
  return (tostring(s):gsub("[\\&%%$#_{}~^]", especiais))
end

local inline
inline = function(s)
  local guardados = {}
  local function guardar(t)
    guardados[#guardados + 1] = t
    return "\1" .. #guardados .. "\2"
  end
  s = s:gsub("`([^`]+)`", function(c)
    return guardar("\\texttt{" .. M.escapar(c) .. "}")
  end)
  s = s:gsub("%[([^%]]+)%]%(([^%)]+)%)", function(t, u)
    local url = u:gsub("([%%#])", "\\%1")
    return guardar("\\href{" .. url .. "}{" .. inline(t) .. "}")
  end)
  s = M.escapar(s)
  s = s:gsub("%*%*(.-)%*%*", "\\textbf{%1}")
  s = s:gsub("%*(.-)%*", "\\emph{%1}")
  s = s:gsub("\1(%d+)\2", function(n) return guardados[tonumber(n)] end)
  return s
end
M.inline = inline

-- URL como link clicável cujo texto pode quebrar linha (metadados da publicação).
function M.link_url(url)
  local alvo = url:gsub("([%%#])", "\\%1")
  local texto = M.escapar(url):gsub("([/%-%?=&])", "%1\\allowbreak{}")
  return "\\href{" .. alvo .. "}{" .. texto .. "}"
end

function M.converter(texto)
  texto = texto:gsub("\r\n", "\n")
  local saida, bloco, itens = {}, nil, {}
  local function out(x) saida[#saida + 1] = x end
  local function fechar()
    if bloco == "p" then
      out(inline(table.concat(itens, " ")))
    elseif bloco == "ul" or bloco == "ol" then
      local amb = (bloco == "ul") and "itemize" or "enumerate"
      local l = { "\\begin{" .. amb .. "}" }
      for _, it in ipairs(itens) do l[#l + 1] = "\\item " .. inline(it) end
      l[#l + 1] = "\\end{" .. amb .. "}"
      out(table.concat(l, "\n"))
    elseif bloco == "quote" then
      out("\\begin{citacao}" .. inline(table.concat(itens, " ")) .. "\\end{citacao}")
    end
    bloco, itens = nil, {}
  end
  local function abrir(tipo)
    if bloco ~= tipo then fechar(); bloco = tipo end
  end

  for linha in (texto .. "\n"):gmatch("(.-)\n") do
    if linha:match("^%s*$") then
      fechar()
    elseif linha:match("^#+%s") then
      fechar()
      local n, t = linha:match("^(#+)%s+(.-)%s*$")
      out((#n >= 3 and "\\subintertitulo{" or "\\intertitulo{") .. inline(t) .. "}")
    elseif linha:match("^%-%-%-+%s*$") then
      fechar(); out("\\separador{}")
    elseif linha:match("^!%[") then
      fechar()
      texio.write_nl("AVISO: imagens no corpo do texto são ignoradas; use 'imagem:' no cabeçalho.")
    elseif linha:match("^%s*[-*+]%s+") then
      abrir("ul"); itens[#itens + 1] = linha:match("^%s*[-*+]%s+(.*)$")
    elseif linha:match("^%s*%d+[%.%)]%s+") then
      abrir("ol"); itens[#itens + 1] = linha:match("^%s*%d+[%.%)]%s+(.*)$")
    elseif linha:match("^>") then
      abrir("quote"); itens[#itens + 1] = linha:match("^>%s?(.*)$")
    else
      abrir("p"); itens[#itens + 1] = linha:match("^%s*(.-)%s*$")
    end
  end
  fechar()
  return table.concat(saida, "\n\n")
end

return M
