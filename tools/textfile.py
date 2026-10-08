# -*- coding: utf-8 -*-
"""Writing a text file that another program may be reading at that moment.

The owner runs Codex (working the art queue) and VS Code beside the backlog
loop, and both re-read `implementation/BACKLOG.md` and
`implementation/backlog/INDEX.md` whenever they change. On Windows a file
another process is reading refuses to be opened for writing - `OSError` 22,
"Invalid argument". Measured on 2026-10-07 while Codex worked: 16 of 20
back-to-back writes of BACKLOG.md failed, and two verify runs in a row went
red on it. The reader lets go within moments, so the whole fix is to wait a
little and try again.
"""
import time

ATTEMPTS = 50
PAUSE_S = 0.1


def write_text(path, text):
    """Write `text` to `path` as UTF-8 with LF line ends, retrying for up to
    five seconds while another program holds the file."""
    for attempt in range(ATTEMPTS):
        try:
            with open(path, "w", encoding="utf-8", newline="\n") as f:
                f.write(text)
            return
        except OSError:
            if attempt == ATTEMPTS - 1:
                raise
            time.sleep(PAUSE_S)
