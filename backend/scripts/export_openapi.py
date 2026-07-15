#!/usr/bin/env python3
"""Export OpenAPI JSON to docs/openapi.snapshot.json (app must import cleanly)."""

from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
import sys

sys.path.insert(0, str(ROOT))

from app.main import app  # noqa: E402

out = ROOT / "docs" / "openapi.snapshot.json"
out.write_text(json.dumps(app.openapi(), indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
print(f"[ok] wrote {out}")
