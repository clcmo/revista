-- MODEL: acesso a dados. Lê edição, artigos (front matter + corpo) e o lockfile
-- de imagens. Não formata nada e não conhece LaTeX.
local M = {}

local function ler(caminho)
  local f = io.open(caminho, "rb")
  if not f then return nil end
  local s = f:read("*a"); f:close()
  return s
end

local function separar_front_matter(texto)
  local meta, corpo = {}, texto
  local fm, resto = texto:match("^%-%-%-\r?\n(.-)\r?\n%-%-%-\r?\n?(.*)$")
  if fm then
    for linha in fm:gmatch("[^\r\n]+") do
      local k, v = linha:match("^([%w_]+):%s*(.-)%s*$")
      if k then
        v = v:gsub('^"(.*)"$', "%1"):gsub("^'(.*)'$", "%1")
        meta[k] = v
      end
    end
    corpo = resto
  end
  return meta, corpo
end

function M.existe(caminho)
  local f = io.open(caminho, "rb")
  if f then f:close(); return true end
  return false
end

function M.carregar()
  local issue = dofile("content/issue.lua")

  local nomes = {}
  for nome in lfs.dir("content/artigos") do
    if nome:match("%.md$") then nomes[#nomes + 1] = nome end
  end
  table.sort(nomes)

  local artigos = {}
  for _, nome in ipairs(nomes) do
    local meta, corpo = separar_front_matter(ler("content/artigos/" .. nome))
    meta.slug = nome:gsub("%.md$", "")
    if meta.publicar ~= "nao" then
      artigos[#artigos + 1] = { meta = meta, corpo = corpo, arquivo = nome }
    end
  end

  local lock = {}
  local f = loadfile("assets/images.lock.lua")
  if f then lock = f() end

  return { issue = issue, artigos = artigos, imagens = lock }
end

return M
