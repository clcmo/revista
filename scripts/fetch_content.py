#!/usr/bin/env python3
"""Importa artigos de feeds RSS/Atom e APIs JSON para content/artigos."""
import html
import json
import re
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CONFIG = ROOT / "content" / "sources.json"
ARTICLES = ROOT / "content" / "artigos"
CACHE = ROOT / "assets" / "cache"
USER_AGENT = "revista-content-importer/1.0"
REQUEST_ATTEMPTS = 3


def request(url):
    req = urllib.request.Request(url, headers={"User-Agent": USER_AGENT})
    last_error = None
    for attempt in range(REQUEST_ATTEMPTS):
        try:
            with urllib.request.urlopen(req, timeout=30) as response:
                return response.read(), response.headers.get_content_type()
        except (urllib.error.URLError, TimeoutError) as error:
            last_error = error
            if attempt + 1 < REQUEST_ATTEMPTS:
                delay = 2 ** attempt
                print(f"aviso: falha de rede em {url}; nova tentativa em {delay}s", file=sys.stderr)
                time.sleep(delay)
    raise last_error


def text(value):
    return re.sub(r"\s+", " ", html.unescape(str(value or ""))).strip()


class TextExtractor(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []
        self.skip = 0

    def handle_starttag(self, tag, attrs):
        if tag in {"script", "style", "noscript", "svg"}:
            self.skip += 1
        elif tag in {"p", "br", "li", "h1", "h2", "h3", "blockquote"}:
            self.parts.append("\n")

    def handle_endtag(self, tag):
        if tag in {"script", "style", "noscript", "svg"} and self.skip:
            self.skip -= 1
        elif tag in {"p", "li", "h1", "h2", "h3", "blockquote"}:
            self.parts.append("\n")

    def handle_data(self, data):
        if not self.skip:
            self.parts.append(data)

    def result(self):
        lines = [text(line) for line in "".join(self.parts).splitlines()]
        return "\n\n".join(line for line in lines if line)


def html_to_text(value):
    parser = TextExtractor()
    parser.feed(value or "")
    return parser.result()


class MarkdownExtractor(HTMLParser):
    def __init__(self):
        super().__init__()
        self.parts = []
        self.skip = 0
        self.links = []
        self.list_stack = []

    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag in {"script", "style", "noscript", "svg"}:
            self.skip += 1
        elif tag in {"h1", "h2", "h3"}:
            self.parts.append("\n\n" + "#" * int(tag[1]) + " ")
        elif tag == "p":
            self.parts.append("\n\n")
        elif tag in {"strong", "b"}:
            self.parts.append("**")
        elif tag in {"em", "i"}:
            self.parts.append("*")
        elif tag == "a":
            self.links.append(attrs.get("href", ""))
            self.parts.append("[")
        elif tag in {"ul", "ol"}:
            self.list_stack.append(tag)
            self.parts.append("\n\n")
        elif tag == "li":
            marker = "1." if self.list_stack and self.list_stack[-1] == "ol" else "-"
            self.parts.append(f"\n{marker} ")
        elif tag == "blockquote":
            self.parts.append("\n\n> ")
        elif tag == "br":
            self.parts.append("\n")

    def handle_endtag(self, tag):
        if tag in {"script", "style", "noscript", "svg"} and self.skip:
            self.skip -= 1
        elif tag in {"strong", "b"}:
            self.parts.append("**")
        elif tag in {"em", "i"}:
            self.parts.append("*")
        elif tag == "a":
            url = self.links.pop() if self.links else ""
            self.parts.append(f"]({url})" if url else "]")
        elif tag in {"ul", "ol"} and self.list_stack:
            self.list_stack.pop()
        elif tag in {"h1", "h2", "h3", "p", "li", "blockquote"}:
            self.parts.append("\n")

    def handle_data(self, data):
        if not self.skip:
            self.parts.append(html.unescape(data))

    def result(self):
        value = "".join(self.parts)
        value = re.sub(r"[ \t]+", " ", value)
        value = re.sub(r"[ \t]+\n", "\n", value)
        value = re.sub(r"\n[ \t]+", "\n", value)
        value = re.sub(r"\n{3,}", "\n\n", value)
        return value.strip()


def html_to_markdown(value):
    parser = MarkdownExtractor()
    parser.feed(value or "")
    return parser.result()


def field(item, path):
    if not path:
        return item
    value = item
    for part in path.split("."):
        if isinstance(value, dict):
            value = value.get(part)
        elif isinstance(value, list) and part.isdigit():
            value = value[int(part)] if int(part) < len(value) else ""
        else:
            return ""
    return value or ""


def first(*values):
    return next((text(value) for value in values if value), "")


def slug(value):
    value = text(value).lower()
    value = re.sub(r"[^a-z0-9]+", "-", value).strip("-")
    return value[:70] or "artigo"


def xml_value(item, names):
    for child in item.iter():
        name = child.tag.rsplit("}", 1)[-1]
        if name in names and child.text:
            return child.text
    return ""


def xml_link(item):
    for child in item.iter():
        if child.tag.rsplit("}", 1)[-1] != "link":
            continue
        if child.attrib.get("href"):
            return child.attrib["href"]
        if child.text:
            return child.text
    return ""


def xml_image(item):
    for child in item.iter():
        name = child.tag.rsplit("}", 1)[-1]
        if name in {"content", "thumbnail", "enclosure"} and child.attrib.get("url"):
            return child.attrib["url"]
    return ""


def rss_items(source):
    body, _ = request(source["url"])
    root = ET.fromstring(body)
    items = []
    for item in root.iter():
        if item.tag.rsplit("}", 1)[-1] not in {"item", "entry"}:
            continue
        summary = xml_value(item, {"description", "summary", "subtitle"})
        items.append({
            "title": xml_value(item, {"title"}),
            "url": xml_link(item),
            "summary": summary,
            "content": xml_value(item, {"encoded", "content"}) or summary,
            "author": xml_value(item, {"creator", "author"}),
            "image": xml_image(item),
            "date": xml_value(item, {"pubDate", "published", "updated"}),
            "section": source.get("secao", "Importados"),
        })
    return items


def api_items(source):
    body, _ = request(source["url"])
    data = json.loads(body)
    items = field(data, source.get("items_path", "items"))
    if not isinstance(items, list):
        raise ValueError(f"items_path não aponta para uma lista: {source['url']}")
    fields = source.get("fields", {})
    return [{
        "title": field(item, fields.get("title", "title")),
        "url": field(item, fields.get("url", "url")),
        "summary": field(item, fields.get("summary", "summary")),
        "content": field(item, fields.get("content", "content")),
        "author": field(item, fields.get("author", "author")),
        "image": field(item, fields.get("image", "image")),
        "date": field(item, fields.get("date", "date")),
        "section": source.get("secao", "Importados"),
    } for item in items]


def page_data(item):
    content = item["content"]
    image = item["image"]
    if content:
        return html_to_markdown(content), image
    if not item["url"]:
        return "", image
    try:
        body, content_type = request(item["url"])
    except (urllib.error.URLError, TimeoutError) as error:
        print(f"aviso: não foi possível buscar a página {item['url']}: {error}", file=sys.stderr)
        return "", image
    if "html" not in content_type:
        return "", image
    decoded = body.decode("utf-8", errors="replace")
    if not image:
        match = re.search(
            r'<meta[^>]+(?:property|name)=["\'](?:og:image|twitter:image)["\'][^>]+content=["\']([^"\']+)',
            decoded,
            re.I,
        )
        image = match.group(1) if match else ""
    if image:
        image = urllib.parse.urljoin(item["url"], image)
    return html_to_markdown(decoded), image


def download_image(url, name):
    if not url or urllib.parse.urlparse(url).scheme not in {"http", "https"}:
        return ""
    path = urllib.parse.urlparse(url).path
    suffix = Path(path).suffix.lower()
    if suffix not in {".jpg", ".jpeg", ".png", ".webp"}:
        suffix = ".jpg"
    destination = CACHE / f"{name}{suffix}"
    if not destination.exists():
        try:
            body, _ = request(url)
            destination.write_bytes(body)
        except (urllib.error.URLError, TimeoutError) as error:
            print(f"aviso: imagem indisponível {url}: {error}", file=sys.stderr)
            return ""
    return str(destination.relative_to(ROOT))


def write_article(item, index):
    title = first(item["title"], "Artigo importado")
    name = f"auto-{index:02d}-{slug(title)}"
    body, image_url = page_data(item)
    image = download_image(image_url, name)
    link = first(item["url"])
    publication_date = first(item.get("date"))
    if "T" in publication_date:
        publication_date = publication_date.split("T", 1)[0]
    if link:
        body = f"Fonte: [{link}]({link})\n\n{body}"
    metadata = [
        "---",
        f"titulo: {title}",
        f"autor: {first(item['author'], 'Fonte externa')}",
        f"secao: {first(item['section'], 'Importados')}",
        f"ordem: {index + 100}",
        f"resumo: {html_to_text(item['summary'])}",
        f"data_publicacao: {publication_date}",
        "fonte: urbanna",
        f"url_publicacao: {link}",
    ]
    if image:
        metadata.append(f"imagem_arquivo: {image}")
    metadata += ["---", body or "Conteúdo não informado.", ""]
    (ARTICLES / f"{name}.md").write_text("\n".join(metadata), encoding="utf-8")


def limpar_cache():
    CACHE.mkdir(parents=True, exist_ok=True)
    for item in CACHE.iterdir():
        if item.name != ".gitkeep" and item.is_file():
            item.unlink()


def main():
    config = json.loads(CONFIG.read_text(encoding="utf-8"))
    imported = []
    source_errors = []
    for source in config.get("apis", []):
        try:
            imported.extend(api_items(source))
        except (OSError, ET.ParseError, ValueError, urllib.error.URLError, TimeoutError) as error:
            source_errors.append((source.get("url", "API"), error))
    for source in config.get("feeds", []):
        try:
            imported.extend(rss_items(source))
        except (OSError, ET.ParseError, ValueError, urllib.error.URLError, TimeoutError) as error:
            source_errors.append((source.get("url", "feed"), error))
    for url, error in source_errors:
        print(f"aviso: fonte indisponível {url}: {error}", file=sys.stderr)
    if source_errors and not imported:
        print("aviso: mantendo artigos importados já disponíveis", file=sys.stderr)
        return
    unique = {}
    for item in imported:
        key = item["url"] or item["title"]
        if key and key not in unique:
            unique[key] = item
    imported = list(unique.values())
    limit = int(config.get("max_artigos", len(imported)))
    limpar_cache()
    for old in ARTICLES.glob("auto-*.md"):
        old.unlink()
    ARTICLES.mkdir(parents=True, exist_ok=True)
    for index, item in enumerate(imported[:limit], 1):
        write_article(item, index)
    print(f"ok: {min(len(imported), limit)} artigo(s) importado(s)")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ET.ParseError, ValueError, urllib.error.URLError) as error:
        print(f"erro ao importar conteúdo: {error}", file=sys.stderr)
        sys.exit(1)