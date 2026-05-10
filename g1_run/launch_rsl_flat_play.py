# Copyright (c) 2022-2026, The Isaac Lab Project Developers (https://github.com/isaac-sim/IsaacLab/blob/main/CONTRIBUTORS.md).
# SPDX-License-Identifier: BSD-3-Clause
"""Run Isaac Lab ``play.py`` after registering ``g1_run`` (do not pre-import isaaclab_tasks)."""

from __future__ import annotations

import argparse
import os
import runpy
import signal
import sys
from pathlib import Path

if hasattr(signal, "SIGPIPE"):
    signal.signal(signal.SIGPIPE, signal.SIG_IGN)

ISAACLAB_ROOT = Path(os.environ.get("ISAACLAB_ROOT", "/workspace/IsaacLab")).resolve()
_PLAY = ISAACLAB_ROOT / "scripts" / "reinforcement_learning" / "rsl_rl" / "play.py"


def main() -> None:
    if not _PLAY.is_file():
        print(f"[ERROR] Missing play.py: {_PLAY}", file=sys.stderr)
        sys.exit(2)
    ap = argparse.ArgumentParser(add_help=False)
    ap.add_argument("--play-lin-vel-x", type=float, default=None)
    ap.add_argument("--play-lin-vel-y", type=float, default=None)
    ap.add_argument("--play-ang-vel-z", type=float, default=None)
    ns, rest = ap.parse_known_args(sys.argv[1:])
    if ns.play_lin_vel_x is not None:
        os.environ["G1_PLAY_LIN_VEL_X"] = str(ns.play_lin_vel_x)
    if ns.play_lin_vel_y is not None:
        os.environ["G1_PLAY_LIN_VEL_Y"] = str(ns.play_lin_vel_y)
    if ns.play_ang_vel_z is not None:
        os.environ["G1_PLAY_ANG_VEL_Z"] = str(ns.play_ang_vel_z)
    import g1_run  # noqa: F401
    play_dir = str(_PLAY.parent.resolve())
    if play_dir not in sys.path:
        sys.path.insert(0, play_dir)
    sys.argv = [str(_PLAY)] + rest
    runpy.run_path(str(_PLAY), run_name="__main__")


if __name__ == "__main__":
    main()
