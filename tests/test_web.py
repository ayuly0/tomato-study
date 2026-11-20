import os
import re
import pytest

DOCS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "docs")
HTML_PATH = os.path.join(DOCS_DIR, "index.html")
CSS_PATH = os.path.join(DOCS_DIR, "style.css")
JS_PATH = os.path.join(DOCS_DIR, "script.js")
SERVE_MD_PATH = os.path.join(DOCS_DIR, "SERVE.md")


ALL_PAGES = [
    "index.html",
    "features.html",
    "methods.html",
    "install.html",
    "guide.html",
    "gallery.html",
    "about.html",
    "faq.html",
    "credits.html"
]


def test_all_nine_docs_pages_exist():
    for page in ALL_PAGES:
        page_path = os.path.join(DOCS_DIR, page)
        assert os.path.exists(page_path), f"Page {page} must exist in docs/"
    assert os.path.exists(CSS_PATH), "docs/style.css must exist"
    assert os.path.exists(JS_PATH), "docs/script.js must exist"
    assert os.path.exists(SERVE_MD_PATH), "docs/SERVE.md must exist"


def test_zero_emojis_in_all_web_pages():
    """Enforces antislop-ui rule: zero decorative emojis in text, buttons, or headings across all pages."""
    emoji_pattern = re.compile(
        r"[\U00010000-\U0010ffff]|[\u2600-\u27bf]|[\u2300-\u23ff]"
    )

    for page in ALL_PAGES:
        page_path = os.path.join(DOCS_DIR, page)
        with open(page_path, "r", encoding="utf-8") as f:
            content = f.read()
        assert not emoji_pattern.search(content), f"{page} must not contain decorative emojis"

    with open(CSS_PATH, "r", encoding="utf-8") as f:
        assert not emoji_pattern.search(f.read()), "docs/style.css must not contain decorative emojis"

    with open(JS_PATH, "r", encoding="utf-8") as f:
        assert not emoji_pattern.search(f.read()), "docs/script.js must not contain decorative emojis"


def test_html_semantic_structure_across_pages():
    for page in ALL_PAGES:
        page_path = os.path.join(DOCS_DIR, page)
        with open(page_path, "r", encoding="utf-8") as f:
            html = f.read()
        assert "<!DOCTYPE html>" in html, f"{page} missing doctype"
        assert "<html" in html and "</html>" in html, f"{page} missing html tag"
        assert "<header" in html and "</header>" in html, f"{page} missing header"
        assert "<nav" in html and "</nav>" in html, f"{page} missing nav"
        assert "<footer" in html and "</footer>" in html, f"{page} missing footer"
        assert "style.css" in html, f"{page} must link to style.css"


def test_cross_page_navigation_links():
    """Ensure all navigation links across pages point to existing pages."""
    for page in ALL_PAGES:
        page_path = os.path.join(DOCS_DIR, page)
        with open(page_path, "r", encoding="utf-8") as f:
            html = f.read()
        for target in ALL_PAGES:
            assert f'href="{target}"' in html, f"{page} must link to {target}"


def test_homepage_content_sections():
    with open(HTML_PATH, "r", encoding="utf-8") as f:
        html = f.read()

    assert 'id="hero"' in html
    assert "Key Highlights" in html
    assert "The Problem: Why We Built Tomato Study" in html
    assert "Get Started in 3 Steps" in html
    assert "Peer Feedback & Evaluation" in html


def test_keyboard_shortcuts_and_install_tabs():
    guide_path = os.path.join(DOCS_DIR, "guide.html")
    install_path = os.path.join(DOCS_DIR, "install.html")

    with open(guide_path, "r", encoding="utf-8") as f:
        guide_html = f.read()

    # Verify shortcuts in guide
    for key in ["Space", "R", "S", "Z", "P", "M"]:
        assert f">{key}<" in guide_html

    with open(install_path, "r", encoding="utf-8") as f:
        install_html = f.read()

    # Verify install tabs in install.html
    assert 'id="tab-linux"' in install_html
    assert 'id="tab-windows"' in install_html
    assert 'id="tab-uv"' in install_html


def test_faq_contains_ten_items():
    faq_path = os.path.join(DOCS_DIR, "faq.html")
    with open(faq_path, "r", encoding="utf-8") as f:
        faq_html = f.read()

    assert faq_html.count("<details class=\"faq-item\"") == 10


def test_interactive_mockup_elements():
    with open(HTML_PATH, "r", encoding="utf-8") as f:
        html = f.read()

    assert '<canvas id="mockup-canvas"' in html
    assert 'id="btn-play"' in html
    assert 'id="btn-reset"' in html
    assert 'id="btn-mode"' in html
    assert 'id="clock-min"' in html
    assert 'id="clock-sec"' in html
    assert 'id="mockup-strict-badge"' in html
    assert 'id="mockup-vol-slider"' in html
    assert 'src="script.js"' in html
