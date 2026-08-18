#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

pick_python() {
  for candidate in python3.13 python3.12 python3.11 python3; do
    if command -v "$candidate" >/dev/null 2>&1; then
      version="$("$candidate" -c 'import sys; print(".".join(map(str, sys.version_info[:2])))')"
      major="${version%%.*}"
      minor="${version#*.}"
      if (( major > 3 || (major == 3 && minor >= 11) )); then
        echo "$candidate"
        return 0
      fi
    fi
  done
  return 1
}

PY="$(pick_python)" || {
  echo "ERROR: Python 3.11+ is required (FastAPI 0.116 needs a current interpreter)." >&2
  echo "Install python3.12 or python3.13, then re-run this script." >&2
  exit 1
}

echo "Using $PY ($("$PY" --version))"
"$PY" -m venv .venv
# shellcheck disable=SC1091
source .venv/bin/activate
python -m pip install -U pip
pip install -r requirements.txt
echo "Done. Run: source .venv/bin/activate"
