import os
from bs4 import BeautifulSoup


def extract_nav_urls(nav, docs_dir='docs', base_path=''):
    """Extrahiert alle URLs aus der nav-Struktur."""
    urls = set()
    for item in nav:
        if isinstance(item, dict):
            for _, value in item.items():
                if isinstance(value, str):
                    url = os.path.splitext(value)[0].replace("index", "")
                    urls.add("/" + base_path + url.strip("/"))
                elif isinstance(value, list):
                    sub_urls = extract_nav_urls(value, docs_dir, base_path)
                    urls.update(sub_urls)
        elif isinstance(item, str):
            url = os.path.splitext(item)[0].replace("index", "")
            urls.add("/" + base_path + url.strip("/"))
    return urls


def remove_unlisted_archive_links(html, nav_urls):
    soup = BeautifulSoup(html, 'html.parser')

    # Seitenleisten-Navigation
    for li in soup.select('li.md-nav__item'):
        a = li.find('a', class_='md-nav__link')
        if not a:
            continue
        text = a.get_text(strip=True).lower()
        href = a.get('href', '').strip().rstrip('/')
        if 'archiv' in text and not any(
            href.endswith(url) for url in nav_urls
        ):
            li.decompose()

    # Tabs-Navigation (oben)
    for li in soup.select('nav.md-tabs li'):
        a = li.find('a', class_='md-tabs__link')
        if not a:
            continue
        text = a.get_text(strip=True).lower()
        href = a.get('href', '').strip().rstrip('/')
        if 'archiv' in text and not any(
            href.endswith(url) for url in nav_urls
        ):
            li.decompose()

    return str(soup)


def clean_copyright(output, config):
    copyright_text = config.get("copyright", "").strip()
    if not copyright_text:
        return output

    soup = BeautifulSoup(output, "html.parser")
    copyright_div = soup.find("div", class_="md-copyright")

    if copyright_div:
        for child in list(copyright_div.children):
            if (
                child.name == "div"
                and "md-copyright__highlight" in child.get("class", [])
                and child.text.strip() == copyright_text
            ):
                continue
            child.decompose()

        if not copyright_div.text.strip():
            copyright_div.decompose()

    return str(soup)


def on_post_page(output, page, config, **kwargs):
    nav = config.get('nav', [])
    nav_urls = extract_nav_urls(nav)
    output = remove_unlisted_archive_links(output, nav_urls)
    output = clean_copyright(output, config)
    return output
