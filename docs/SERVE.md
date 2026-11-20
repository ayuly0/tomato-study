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

## 5. Deploying to GitHub Pages

The `docs/` folder is pre-configured for GitHub Pages:

1. Navigate to your repository on GitHub.
2. Go to **Settings** > **Pages**.
3. Under **Build and deployment**:
   - **Source:** `Deploy from a branch`
   - **Branch:** `main` (or `master`)
   - **Folder:** `/docs`
4. Click **Save**.
5. Your website will be live at:
   `https://<your-username>.github.io/<repository-name>/`
