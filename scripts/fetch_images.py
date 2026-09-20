#!/usr/bin/env python3
"""Busca por API as imagens da edição, respeitando o orçamento (max_imagens).

Só baixa o que é necessário: capa (se houver `capa_busca`) e artigos com `imagem: <termo>`,
nessa ordem, até esgotar o orçamento. Guarda em assets/cache/ e registra autoria e licença
em assets/images.lock.json (fonte de verdade) e assets/images.lock.lua (lido pelo ViewModel).

Provedores: Unsplash (se UNSPLASH_ACCESS_KEY estiver definida) ou Openverse (sem chave).
Somente biblioteca padrão do Python.
"""
import json
import os
import re
import sys
import urllib.parse
import urllib.request
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
CACHE = RAIZ / "assets" / "cache"
LOCK_JSON = RAIZ / "assets" / "images.lock.json"
LOCK_LUA = RAIZ / "assets" / "images.lock.lua"
UA = {"User-Agent": "revista-lualatex/1.0"}


def http(url, headers=None):
    req = urllib.request.Request(url, headers={**UA, **(headers or {})})
    with urllib.request.urlopen(req, timeout=60) as r:
        return r.read(), r.headers.get_content_type()


def http_json(url, headers=None):
    corpo, _ = http(url, headers)
    return json.loads(corpo)


def buscar_unsplash(termo, chave):
    q = urllib.parse.urlencode({"query": termo, "per_page": 1, "orientation": "landscape"})
    dados = http_json(f"https://api.unsplash.com/search/photos?{q}",
                      {"Authorization": f"Client-ID {chave}"})
    if not dados.get("results"):
        return None
    r = dados["results"][0]
    try:  # exigido pelas diretrizes da API: registrar o uso da foto
        http(r["links"]["download_location"], {"Authorization": f"Client-ID {chave}"})
    except Exception as e:  # não é fatal
        print(f"  aviso: não registrou download no Unsplash ({e})")
    return {"url": r["urls"]["regular"], "criador": r["user"]["name"],
            "licenca": "Licença Unsplash", "fonte": "Unsplash", "pagina": r["links"]["html"]}


def buscar_openverse(termo):
    q = urllib.parse.urlencode({"q": termo, "page_size": 1, "license_type": "commercial",
                                "aspect_ratio": "wide", "extension": "jpg"})
    dados = http_json(f"https://api.openverse.org/v1/images/?{q}")
    if not dados.get("results"):
        return None
    r = dados["results"][0]
    lic, ver = (r.get("license") or "").lower(), r.get("license_version") or ""
    licenca = f"{lic.upper()} {ver}".strip() if lic in ("cc0", "pdm") else f"CC {lic.upper()} {ver}".strip()
    return {"url": r["url"], "criador": r.get("creator") or "autoria desconhecida",
            "licenca": licenca, "fonte": "Openverse", "pagina": r.get("foreign_landing_url", "")}


def buscar(termo):
    chave = os.environ.get("UNSPLASH_ACCESS_KEY")
    return buscar_unsplash(termo, chave) if chave else buscar_openverse(termo)


def ler_front_matter(caminho):
    texto = caminho.read_text(encoding="utf-8")
    m = re.match(r"^---\r?\n(.*?)\r?\n---", texto, re.S)
    meta = {}
    if m:
        for linha in m.group(1).splitlines():
            k, _, v = linha.partition(":")
            if _:
                meta[k.strip()] = v.strip().strip("\"'")
    return meta


def pedidos():
    """Lista (chave, termo) na mesma ordem de prioridade do ViewModel."""
    issue = (RAIZ / "content" / "issue.lua").read_text(encoding="utf-8")
    orcamento = int((re.search(r"^\s*max_imagens\s*=\s*(\d+)", issue, re.M) or [0, 0])[1])
    lista = []
    capa = re.search(r'^\s*capa_busca\s*=\s*"([^"]+)"', issue, re.M)
    if capa:
        lista.append(("capa", capa.group(1)))
    artigos = []
    for f in sorted((RAIZ / "content" / "artigos").glob("*.md")):
        meta = ler_front_matter(f)
        if meta.get("publicar") == "nao" or meta.get("imagem_arquivo") or not meta.get("imagem"):
            continue
        ordem = float(meta.get("ordem", 999))
        artigos.append((ordem, f.name, f.stem, meta["imagem"]))
    lista += [(slug, termo) for _, _, slug, termo in sorted(artigos)]
    return lista[:orcamento]


def gravar_lock(lock):
    LOCK_JSON.write_text(json.dumps(lock, ensure_ascii=False, indent=2), encoding="utf-8")
    def s(v):
        return '"' + str(v).replace("\\", "\\\\").replace('"', '\\"') + '"'
    linhas = ["-- Gerado por scripts/fetch_images.py. Não edite à mão.", "return {"]
    for chave, i in sorted(lock.items()):
        campos = ", ".join(f"{k} = {s(v)}" for k, v in i.items())
        linhas.append(f'  [{s(chave)}] = {{ {campos} }},')
    linhas.append("}")
    LOCK_LUA.write_text("\n".join(linhas) + "\n", encoding="utf-8")


def main():
    CACHE.mkdir(parents=True, exist_ok=True)
    lock = json.loads(LOCK_JSON.read_text(encoding="utf-8")) if LOCK_JSON.exists() else {}
    for chave, termo in pedidos():
        destino = CACHE / f"{chave}.jpg"
        if chave in lock and destino.exists():
            print(f"= {chave}: já em cache")
            continue
        print(f"+ {chave}: buscando '{termo}'")
        achado = buscar(termo)
        if not achado:
            print("  nada encontrado; a revista usará o visual vetorial")
            continue
        corpo, _ = http(achado["url"])
        destino.write_bytes(corpo)
        lock[chave] = {"arquivo": f"assets/cache/{chave}.jpg", "criador": achado["criador"],
                       "licenca": achado["licenca"], "fonte": achado["fonte"], "pagina": achado["pagina"]}
    gravar_lock(lock)
    print("ok")


if __name__ == "__main__":
    sys.exit(main())
