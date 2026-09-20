#!/usr/bin/env python3
"""Gera uma visualizacao HTML local dos artigos importados."""
import html
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ARTICLES = ROOT / "content" / "artigos"
OUTPUT = ROOT / "site" / "preview.html"


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


def markdown(value):
    value = html.escape(value)
    value = re.sub(r"^### (.+)$", r"<h4>\1</h4>", value, flags=re.M)
    value = re.sub(r"^## (.+)$", r"<h3>\1</h3>", value, flags=re.M)
    value = re.sub(r"^# (.+)$", r"<h2>\1</h2>", value, flags=re.M)
    value = re.sub(r"\*\*(.+?)\*\*", r"<strong>\1</strong>", value)
    value = re.sub(r"\*(.+?)\*", r"<em>\1</em>", value)
    paragraphs = re.split(r"\n\s*\n", value)
    return "".join(f"<p>{part.replace(chr(10), '<br>')}</p>" for part in paragraphs if part.strip())


def article_card(path):
    metadata, body = read_article(path)
    image = metadata.get("imagem_arquivo", "")
    image_html = f'<img src="../{image}" alt="" loading="lazy">' if image else ""
    return f"""<article class="story">{image_html}<div class="story-body">
      <p class="eyebrow">{html.escape(metadata.get('secao', 'Importados'))}</p>
      <h2>{html.escape(metadata.get('titulo', path.stem))}</h2>
      <p class="summary">{html.escape(metadata.get('resumo', ''))}</p>
      <p class="byline">{html.escape(metadata.get('autor', 'Fonte externa'))}</p>
      <div class="copy">{markdown(body)}</div>
    </div></article>"""


def main():
    stories = "\n".join(
        article_card(path)
        for path in sorted(ARTICLES.glob("auto-*.md"))
    )
    OUTPUT.write_text(f"""<!doctype html>
<html lang="pt-BR"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Revista | Preview Ourbanna</title>
<style>
:root {{ --ink:#20252b; --paper:#f4f0e8; --accent:#b4492f; --muted:#746c63; }}
* {{ box-sizing:border-box; }} body {{ margin:0; background:var(--paper); color:var(--ink); font-family:Georgia,serif; }}
header {{ padding:clamp(2rem,7vw,6rem) 7vw 3rem; background:var(--ink); color:#f8f3e9; }}
header h1 {{ max-width:900px; margin:0; font-size:clamp(3rem,8vw,7rem); line-height:.9; font-weight:400; }}
header p {{ color:#d9cfc1; font:600 .75rem/1.4 Arial,sans-serif; letter-spacing:.12em; text-transform:uppercase; }}
main {{ max-width:1180px; margin:0 auto; padding:2rem 7vw 6rem; }}
.story {{ display:grid; grid-template-columns:minmax(180px,32%) 1fr; gap:clamp(1.5rem,4vw,4rem); padding:3rem 0; border-bottom:1px solid #cfc5b8; }}
.story img {{ width:100%; aspect-ratio:4/3; object-fit:cover; }} .story-body {{ max-width:720px; }}
.eyebrow {{ color:var(--accent); font:bold .7rem Arial,sans-serif; letter-spacing:.13em; text-transform:uppercase; }}
.story h2 {{ margin:.35rem 0 .8rem; font-size:clamp(1.8rem,4vw,3.6rem); line-height:1; font-weight:400; }}
.summary {{ color:var(--muted); font-size:1.1rem; }} .byline {{ font:600 .75rem Arial,sans-serif; text-transform:uppercase; letter-spacing:.08em; }}
.copy {{ font-size:1.05rem; line-height:1.65; }} .copy h3,.copy h4 {{ line-height:1.1; }}
@media (max-width:700px) {{ .story {{ display:block; }} .story img {{ margin-bottom:1.5rem; }} }}
</style></head><body><header><p>Visualizacao local · branch test/ourbanna-content</p><h1>Ourbanna<br>em revista</h1></header>
<main>{stories or '<p>Nenhum artigo importado.</p>'}</main></body></html>""", encoding="utf-8")
    print(f"preview: {OUTPUT}")


if __name__ == "__main__":
    main()