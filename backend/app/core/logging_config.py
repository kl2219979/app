"""
app/core/logging_config.py — Logging estructurado (sin secretos)
"""

from __future__ import annotations

import logging
import sys

_CONFIGURED = False


def setup_logging(*, debug: bool = False) -> None:
    global _CONFIGURED
    if _CONFIGURED:
        return
    level = logging.DEBUG if debug else logging.INFO
    logging.basicConfig(
        level=level,
        format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
        stream=sys.stdout,
        force=True,
    )
    _CONFIGURED = True


def get_logger(name: str) -> logging.Logger:
    setup_logging()
    return logging.getLogger(name)
