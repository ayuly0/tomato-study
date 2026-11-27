# Serving the Tomato Study Static Website

This document explains how to locally run, preview, and deploy the Tomato Study static overview website located in the `docs/` directory.

---

## 1. Quick Start (Python 3 Built-in)

No extra packages or dependencies required. Use Python's built-in HTTP server:

### Linux & macOS
```bash
# From the repository root:
python3 -m http.server -d docs 8000
```

### Windows (PowerShell / CMD)
```cmd
:: From the repository root:
python -m http.server -d docs 8000
```

Open your browser to:
[http://localhost:8000](http://localhost:8000)

---

## 2. Using Astral `uv`

If you are using `uv`:

```bash
uv run python -m http.server -d docs 8000
```

---

## 3. Customizing the Port

If port `8000` is already in use by another service, specify an alternative port:

```bash
python3 -m http.server -d docs 8080
# Open http://localhost:8080
```

To bind strictly to `localhost` (preventing local network exposure):

```bash
python3 -m http.server -b 127.0.0.1 -d docs 8000
```

---

## 4. Alternative Web Servers

### Using Node.js / `npx`
```bash
npx serve docs
```

### Using Python Simple Script
```python
# Save as serve.py and run: python serve.py
import http.server
import socketserver
import webbrowser

PORT = 8000
DIRECTORY = "docs"

class Handler(http.server.SimpleHTTPRequestHandler):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, directory=DIRECTORY, **kwargs)

with socketserver.TCPServer(("", PORT), Handler) as httpd:
    print(f"Serving Tomato Study at http://localhost:{PORT}")
    webbrowser.open(f"http://localhost:{PORT}")
    httpd.serve_forever()
```

---

## 5. Free, Shareable GitHub Pages Link

The `docs/` overview is deployed by [`.github/workflows/pages.yml`](../.github/workflows/pages.yml) whenever changes are pushed to `main` (or manually through **Actions** > **Deploy static overview to GitHub Pages** > **Run workflow**).

### One-time setup

1. Push this repository to GitHub. For free public access, make the repository public (private-repository Pages availability depends on your GitHub plan).
2. In the repository, open **Settings** > **Pages**.
3. Under **Build and deployment**, set **Source** to **GitHub Actions**.
4. Open **Actions** and allow workflows if GitHub prompts you; run the deployment workflow or push a change to `main`.
5. Wait for the workflow to finish successfully. The generated URL appears under **Settings** > **Pages** and in the workflow's `github-pages` environment. For this repository it is expected to be:
   `https://ayuly0.github.io/tomato-study/`
6. Share that URL; anyone can open it without installing the desktop app or signing in. It remains available while the repository and Pages deployment remain published.

To preview locally before sharing, use the commands in **Quick Start** above.
