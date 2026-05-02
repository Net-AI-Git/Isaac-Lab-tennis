# Copyright (c) 2022-2026, The Isaac Lab Project Developers (https://github.com/isaac-sim/IsaacLab/blob/main/CONTRIBUTORS.md).
# SPDX-License-Identifier: BSD-3-Clause
"""Run Isaac Lab ``train.py`` for **curriculum / continued training** (same binary as scratch).

Use this entry point when you resume from a checkpoint or advance a staged curriculum
(e.g. new command ranges in ``flat_env_cfg.py``). Pass RSL-RL flags such as ``--resume``,
``--load_run``, ``--checkpoint``, or your shell wrapper variables (e.g. ``CHECKPOINT_SRC``),
from a companion script.

Mechanically identical to ``launch_rsl_flat_train.py``: register ``g1_run`` (so
``Isaac-Velocity-Flat-G1-Tennis-v0`` resolves to this repo) **before** ``train.py`` runs.
Do **not** import ``isaaclab_tasks`` here (needs Kit / ``pxr`` first — that happens inside
``train.py``).
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
