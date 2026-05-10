# Copyright (c) 2022-2026, The Isaac Lab Project Developers (https://github.com/isaac-sim/IsaacLab/blob/main/CONTRIBUTORS.md).
# SPDX-License-Identifier: BSD-3-Clause
"""Run Isaac Lab ``train.py`` after registering this repo's ``g1_run`` Gym specs.

Typical use: **train** (from scratch or with ``--resume`` / checkpoint flags from your
shell wrapper).

Do **not** import ``isaaclab_tasks`` here: that must happen after the Kit app
boots inside ``train.py`` (otherwise ``pxr`` is missing). Importing only
``g1_run`` is lightweight and registers ``Isaac-Velocity-Flat-G1-Tennis-v0``.
"""

from __future__ import annotations

import os
import runpy
import sys
from pathlib import Path

ISAACLAB_ROOT = Path(os.environ.get("ISAACLAB_ROOT", "/workspace/IsaacLab")).resolve()
_TRAIN = ISAACLAB_ROOT / "scripts" / "reinforcement_learning" / "rsl_rl" / "train.py"


def _ensure_video_args(argv: list[str]) -> list[str]:
    """Ensure periodic video capture args exist when launcher is called directly."""
    out = list(argv)
    if "--video" not in out:
        out.append("--video")
    if "--video_length" not in out:
        out += ["--video_length", os.environ.get("VIDEO_LENGTH", "200")]
    if "--video_interval" not in out:
        interval = os.environ.get("VIDEO_INTERVAL", os.environ.get("VIDEO_TIMESTEPS", "2000"))
        out += ["--video_interval", interval]
    return out


def main() -> None:
    if not _TRAIN.is_file():
        print(f"[ERROR] Missing train.py: {_TRAIN}", file=sys.stderr)
        sys.exit(2)
    import g1_run  # noqa: F401
    train_dir = str(_TRAIN.parent.resolve())
    if train_dir not in sys.path:
        sys.path.insert(0, train_dir)
    launch_args = _ensure_video_args(sys.argv[1:])
    sys.argv = [str(_TRAIN)] + launch_args
    runpy.run_path(str(_TRAIN), run_name="__main__")


if __name__ == "__main__":
    main()
