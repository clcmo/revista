#!/usr/bin/env python3
"""Gera uma visualizacao HTML local dos artigos importados."""
import html
import re
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ARTICLES = ROOT / "content" / "artigos"
OUTPUT = ROOT / "site" / "preview.html"
THEME_CSS = ROOT / "site" / "urbanna-theme.css"
PREVIEW_CSS = ROOT / "site" / "preview.css"
THEME_STYLESHEETS = (
    "https://ourbanna.com/wp-content/themes/urbanna-theme/assets/css/style.css?ver=1.1.0",
    "https://ourbanna.com/wp-content/themes/urbanna-theme/assets/css/theme-toggle.css?ver=1.1.0",
)


def read_article(path):
    source = path.read_text(encoding="utf-8")
    match = re.match(r"^---\n(.*?)\n---\n(.*)$", source, re.S)
    if not match:
        return {}, source
    metadata = {}
    for line in match.group(1).splitlines():
        key, separator, value = line.partition(":")
        if separator:
            metadata[key.strip()] = value.strip()
    return metadata, match.group(2).strip()


def summary(value, limit=320):
    value = re.sub(r"<[^>]+>", " ", value or "")
    value = re.sub(r"\s+", " ", html.unescape(value)).strip()
    return value if len(value) <= limit else value[:limit].rsplit(" ", 1)[0] + "..."


def article_card(path):
    metadata, _ = read_article(path)
    image = metadata.get("imagem_arquivo", "")
    image_html = f'<img src="../{image}" alt="" loading="lazy">' if image else ""
    return f"""<article class="story">{image_html}<div class="story-body">
      <p class="eyebrow">{html.escape(metadata.get('secao', 'Importados'))}</p>
      <h2>{html.escape(metadata.get('titulo', path.stem))}</h2>
      <p class="summary">{html.escape(summary(metadata.get('resumo', '')))}</p>
      <p class="byline">{html.escape(metadata.get('autor', 'Fonte externa'))}</p>
    </div></article>"""


def fetch_theme_css():
    chunks = []
    for url in THEME_STYLESHEETS:
        try:
            request = urllib.request.Request(url, headers={"User-Agent": "revista-preview/1.0"})
            with urllib.request.urlopen(request, timeout=20) as response:
                chunks.append(response.read().decode("utf-8", errors="replace"))
        except (OSError, urllib.error.URLError) as error:
            chunks.append(f"/* Não foi possível carregar {url}: {error} */")
    THEME_CSS.write_text("\n\n".join(chunks) + "\n", encoding="utf-8")


def main():
    fetch_theme_css()
    stories = "\n".join(
        article_card(path)
        for path in sorted(ARTICLES.glob("auto-*.md"))
    )
    OUTPUT.write_text(f"""<!doctype html>
<html lang="pt-BR"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>urbanna em revista | Assinantes</title>
<link rel="stylesheet" href="urbanna-theme.css">
<link rel="stylesheet" href="preview.css"></head><body><header><p>Área exclusiva para assinantes</p><h1>urbanna<br>em revista</h1></header>
<section class="subscriber-gate" id="subscriber-gate" aria-labelledby="gate-title">
    <p class="eyebrow">Conteúdo reservado</p>
    <h2 id="gate-title">Entre para ler a edição</h2>
    <p>Confirme o e-mail da sua assinatura para acessar os resumos desta edição.</p>
    <form id="subscriber-form"><label for="subscriber-email">E-mail da assinatura</label>
        <input id="subscriber-email" name="email" type="email" autocomplete="email" required>
        <button type="submit">Acessar edição</button>
    </form>
    <p class="gate-note">Esta visualização é exclusiva para assinantes.</p>
</section>
<main id="subscriber-content" hidden>{stories or '<p>Nenhum artigo importado.</p>'}</main>
<script>
    const form = document.querySelector('#subscriber-form');
    const gate = document.querySelector('#subscriber-gate');
    const content = document.querySelector('#subscriber-content');
    const key = 'urbanna-assinante';
    function unlock() {{ gate.hidden = true; content.hidden = false; }}
    if (localStorage.getItem(key) === 'true') unlock();
    form.addEventListener('submit', (event) => {{
        event.preventDefault();
        if (form.reportValidity()) {{ localStorage.setItem(key, 'true'); unlock(); }}
    }});
</script></body></html>""", encoding="utf-8")
    print(f"preview: {OUTPUT}")


if __name__ == "__main__":
    main()