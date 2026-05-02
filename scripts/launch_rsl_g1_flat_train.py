# Copyright (c) 2022-2026, The Isaac Lab Project Developers (https://github.com/isaac-sim/IsaacLab/blob/main/CONTRIBUTORS.md).
# SPDX-License-Identifier: BSD-3-Clause
"""Run Isaac Lab ``train.py`` after registering this repo's ``g1_run`` Gym specs.

Typical use: **train from scratch** (no ``--resume``). For curriculum / checkpoint
continuation, see ``launch_rsl_g1_flat_train_curriculum.py`` (same mechanics, different name
for clarity in scripts).

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


def main() -> None:
    if not _TRAIN.is_file():
        print(f"[ERROR] Missing train.py: {_TRAIN}", file=sys.stderr)
        sys.exit(2)
    import g1_run  # noqa: F401
    train_dir = str(_TRAIN.parent.resolve())
    if train_dir not in sys.path:
        sys.path.insert(0, train_dir)
    sys.argv = [str(_TRAIN)] + sys.argv[1:]
    runpy.run_path(str(_TRAIN), run_name="__main__")


if __name__ == "__main__":
    main()
