# Copyright (c) 2022-2026, The Isaac Lab Project Developers (https://github.com/isaac-sim/IsaacLab/blob/main/CONTRIBUTORS.md).
# SPDX-License-Identifier: BSD-3-Clause
"""Run Isaac Lab ``play.py`` after registering ``g1_run`` (do not pre-import isaaclab_tasks)."""

from __future__ import annotations

import os
import runpy
import sys
from pathlib import Path

ISAACLAB_ROOT = Path(os.environ.get("ISAACLAB_ROOT", "/workspace/IsaacLab")).resolve()
_PLAY = ISAACLAB_ROOT / "scripts" / "reinforcement_learning" / "rsl_rl" / "play.py"


def main() -> None:
    if not _PLAY.is_file():
        print(f"[ERROR] Missing play.py: {_PLAY}", file=sys.stderr)
        sys.exit(2)
    import g1_run  # noqa: F401
    play_dir = str(_PLAY.parent.resolve())
    if play_dir not in sys.path:
        sys.path.insert(0, play_dir)
    sys.argv = [str(_PLAY)] + sys.argv[1:]
    runpy.run_path(str(_PLAY), run_name="__main__")


if __name__ == "__main__":
    main()
