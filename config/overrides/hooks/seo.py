import os
import json
from bs4 import BeautifulSoup


def on_post_build(config):
    site_name = config.get('site_name', '')
    author = config.get('site_author', '')
    description = config.get('site_description', '')
    site_url = config.get('site_url', '').rstrip('/')
    site_dir = config.get('site_dir', 'site')

    # Create robots.txt
    robots_content = f"""User-agent: *
Disallow:
Sitemap: {site_url}/sitemap.xml
"""

    robots_path = os.path.join(site_dir, 'robots.txt')
    with open(robots_path, 'w', encoding='utf-8') as f:
        f.write(robots_content)
    print(f"robots.txt created at {robots_path}")

    # Create manifest.webmanifest
    manifest_data = {
        "name": site_name,
        "short_name": site_name[:12],
        "start_url": site_url,
        "display": "standalone",
        "background_color": "#ffffff",
        "theme_color": "#1565c0",
        "icons": [
            {
                "src": "images/icons/icon-192.png",
                "sizes": "192x192",
                "type": "image/png"
            },
            {
                "src": "images/icons/icon-512.png",
                "sizes": "512x512",
                "type": "image/png"
            }
        ]
    }

    manifest_path = os.path.join(site_dir, 'manifest.webmanifest')
    with open(manifest_path, 'w', encoding='utf-8') as f:
        json.dump(manifest_data, f, indent=2, ensure_ascii=False)
    print(f"manifest.webmanifest created at {manifest_path}")

    # SEO Meta-Tags
    full_title = f"{author} – {site_name}"
    meta_tags = f"""
<title>{full_title}</title>
<meta name="author" content="{author}">
<meta name="description" content="{description}">
<meta name="robots" content="index, follow">
<meta name="google-site-verification" content="IfcJKhuApWLiVw--QdT9Uac50oDnfLSjvqkV97uVYA0" />
<meta property="og:title" content="{full_title}" />
<meta property="og:type" content="website" />
<meta property="og:url" content="{site_url}" />
<meta property="og:site_name" content="{site_name}" />
<meta property="og:description" content="{description}" />
"""

    for root, _, files in os.walk(site_dir):
        for filename in files:
            if filename.endswith('.html'):
                path = os.path.join(root, filename)
                with open(path, 'r', encoding='utf-8') as f:
                    soup = BeautifulSoup(f, 'html.parser')
                if soup.head:
                    soup.head.append(BeautifulSoup(meta_tags, 'html.parser'))
                    with open(path, 'w', encoding='utf-8') as f:
                        f.write(str(soup))

    print("SEO-Meta-Tags in alle HTML-Dateien eingefügt.")
