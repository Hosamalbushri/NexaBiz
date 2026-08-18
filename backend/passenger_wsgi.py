"""cPanel / Passenger WSGI entry (shared hosting).

FastAPI is ASGI; Passenger expects WSGI. [a2wsgi] bridges the two.

Setup (Namecheap / cPanel → Setup Python App):
  - Python: 3.11+ (NOT 3.6 — FastAPI 0.116 will not install)
  - Application root: folder containing this file + ``app/`` package
  - Startup file: passenger_wsgi.py
  - Entry point: application
  - Run Pip Install on requirements.txt (includes a2wsgi)

Requires external PostgreSQL (DATABASE_URL). Shared cPanel MySQL is not supported.
Run migrations once: ``alembic upgrade head`` (Execute python script in cPanel).
"""

from __future__ import annotations

import os
import sys

# Passenger cwd is the domain document root, not this folder. Stay in app root
# so relative paths and dotenv cannot pick up another project's .env.
_ROOT = os.path.dirname(os.path.abspath(__file__))
os.chdir(_ROOT)
if _ROOT not in sys.path:
    sys.path.insert(0, _ROOT)

from dotenv import load_dotenv

load_dotenv(os.path.join(_ROOT, ".env"), override=False)

# Seed synchronously here. a2wsgi waiting on FastAPI lifespan times out on LiteSpeed.
os.environ["SKIP_ASGI_LIFESPAN"] = "1"

from a2wsgi import ASGIMiddleware

from app.main import _seed_on_startup, app

_seed_on_startup()
application = ASGIMiddleware(app, wait_time=30.0)
