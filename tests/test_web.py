import os
import re
import pytest

DOCS_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "docs")
HTML_PATH = os.path.join(DOCS_DIR, "index.html")
CSS_PATH = os.path.join(DOCS_DIR, "style.css")
JS_PATH = os.path.join(DOCS_DIR, "script.js")
SERVE_MD_PATH = os.path.join(DOCS_DIR, "SERVE.md")


def test_docs_files_exist():
    assert os.path.exists(HTML_PATH), "docs/index.html must exist"
    assert os.path.exists(CSS_PATH), "docs/style.css must exist"
    assert os.path.exists(JS_PATH), "docs/script.js must exist"
    assert os.path.exists(SERVE_MD_PATH), "docs/SERVE.md must exist"


def test_zero_emojis_in_web_overview():
    """Enforces antislop-ui rule: zero decorative emojis in text, buttons, or headings."""
    with open(HTML_PATH, "r", encoding="utf-8") as f:
        html_content = f.read()

    with open(CSS_PATH, "r", encoding="utf-8") as f:
        css_content = f.read()

    with open(JS_PATH, "r", encoding="utf-8") as f:
        js_content = f.read()

    # Regex matching emoji character ranges
    emoji_pattern = re.compile(
        r"[\U00010000-\U0010ffff]|[\u2600-\u27bf]|[\u2300-\u23ff]"
    )

    assert not emoji_pattern.search(html_content), "docs/index.html must not contain decorative emojis"
    assert not emoji_pattern.search(css_content), "docs/style.css must not contain decorative emojis"
    assert not emoji_pattern.search(js_content), "docs/script.js must not contain decorative emojis"


def test_html_semantic_structure():
    with open(HTML_PATH, "r", encoding="utf-8") as f:
        html = f.read()

    assert "<!DOCTYPE html>" in html
    assert "<html" in html and "</html>" in html
    assert "<header" in html and "</header>" in html
    assert "<nav" in html and "</nav>" in html
    assert "<footer" in html and "</footer>" in html
    assert "style.css" in html


def test_required_content_sections():
    with open(HTML_PATH, "r", encoding="utf-8") as f:
        html = f.read()

    required_section_ids = ["hero", "features", "security", "shortcuts", "install"]
    for sid in required_section_ids:
        assert f'id="{sid}"' in html, f"Section #{sid} must be present in docs/index.html"


def test_keyboard_shortcuts_and_install_tabs():
    with open(HTML_PATH, "r", encoding="utf-8") as f:
        html = f.read()

    # Verify shortcuts
    for key in ["Space", "R", "S", "Z", "P", "M"]:
        assert f">{key}<" in html

    # Verify install tabs
    assert 'id="tab-linux"' in html
    assert 'id="tab-windows"' in html
    assert 'id="tab-uv"' in html


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
