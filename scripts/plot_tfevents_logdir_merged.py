#!/usr/bin/env python3
"""
Merge TensorBoard scalar logs from *all* events files in a log directory, then save PNGs.

Use when a run folder has multiple ``events.out.tfevents.*`` files (e.g. resume with
iteration counter continuing). Each file is read in isolation, scalars are merged per
tag, sorted by step, and duplicate steps keep the last value (later file wins).

Dependencies: pip install tensorboard matplotlib

  python3 plot_tfevents_logdir_merged.py --logdir path/to/run_folder

Output (default): <logdir>/tfevents_scalar_plots/  (overwrites existing PNGs)

Isolated reads use a temp dir under scripts/.cache/tfevents_isolated (or PLOT_TFEvents_TMP).
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import sys
import tempfile
from collections import defaultdict
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

from tensorboard.backend.event_processing.event_accumulator import EventAccumulator

_ISOLATED_TMP_PARENT = Path(
    os.environ.get("PLOT_TFEvents_TMP", str(Path(__file__).resolve().parent / ".cache" / "tfevents_isolated"))
)

SCALAR_PLOTS_SUBDIR = "tfevents_scalar_plots"


def _default_outdir(logdir: Path) -> Path:
    return (logdir / SCALAR_PLOTS_SUBDIR).resolve()


def _sanitize_filename(tag: str) -> str:
    s = re.sub(r"[^a-zA-Z0-9._-]+", "_", tag)
    return s[:200] if len(s) > 200 else s


def _isolated_events_logdir(events_file: Path) -> tuple[str, str]:
    _ISOLATED_TMP_PARENT.mkdir(parents=True, exist_ok=True)
    td = tempfile.mkdtemp(prefix="plot_", dir=str(_ISOLATED_TMP_PARENT))
    dst = Path(td) / events_file.name
    shutil.copy2(events_file, dst)
    return str(Path(td).resolve()), td


def _list_event_files(logdir: Path, recursive: bool) -> list[Path]:
    if recursive:
        files = sorted(logdir.rglob("events.out.tfevents.*"))
    else:
        files = sorted(logdir.glob("events.out.tfevents.*"))
    return [p for p in files if p.is_file()]


def _load_scalars_from_file(events_file: Path) -> dict[str, list[tuple[int, float]]]:
    acc_logdir, cleanup_tmp = _isolated_events_logdir(events_file)
    out: dict[str, list[tuple[int, float]]] = {}
    try:
        acc = EventAccumulator(acc_logdir, size_guidance={"scalars": 0})
        acc.Reload()
        if "scalars" not in acc.Tags() or not acc.Tags()["scalars"]:
            return out
        for tag in acc.Tags()["scalars"]:
            rows = acc.Scalars(tag)
            out[tag] = [(r.step, r.value) for r in rows]
    finally:
        if cleanup_tmp:
            shutil.rmtree(cleanup_tmp, ignore_errors=True)
    return out


def _merge_points(pairs: list[tuple[int, float]]) -> tuple[list[int], list[float]]:
    pairs = sorted(pairs, key=lambda x: x[0])
    steps: list[int] = []
    values: list[float] = []
    for step, val in pairs:
        if steps and steps[-1] == step:
            values[-1] = val
        else:
            steps.append(step)
            values.append(val)
    return steps, values


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Merge all tfevents scalar curves in a logdir and export PNGs."
    )
    parser.add_argument(
        "--logdir",
        type=str,
        required=True,
        help="Directory containing events.out.tfevents.*",
    )
    parser.add_argument(
        "--out",
        type=str,
        default=None,
        help=f"Output directory (default: <logdir>/{SCALAR_PLOTS_SUBDIR})",
    )
    parser.add_argument(
        "--recursive",
        action="store_true",
        help="Also search subdirectories for events.out.tfevents.*",
    )
    parser.add_argument(
        "--list-tags",
        action="store_true",
        help="Only print merged scalar tag names",
    )
    args = parser.parse_args()

    logdir = Path(args.logdir).resolve()
    if not logdir.is_dir():
        print(f"Not a directory: {logdir}", file=sys.stderr)
        sys.exit(1)

    event_files = _list_event_files(logdir, args.recursive)
    if not event_files:
        print(f"No events.out.tfevents.* under: {logdir}", file=sys.stderr)
        sys.exit(1)

    # Chronological merge: older files first, then newer (resume writes later mtimes).
    event_files.sort(key=lambda p: (p.stat().st_mtime, str(p)))

    merged: dict[str, list[tuple[int, float]]] = defaultdict(list)
    for ef in event_files:
        per_file = _load_scalars_from_file(ef)
        for tag, pairs in per_file.items():
            merged[tag].extend(pairs)

    if not merged:
        print(f"No scalar data in events under: {logdir}", file=sys.stderr)
        sys.exit(2)

    tags = sorted(merged.keys())
    if args.list_tags:
        for t in tags:
            print(t)
        return

    outdir = Path(args.out).resolve() if args.out else _default_outdir(logdir)
    outdir.mkdir(parents=True, exist_ok=True)

    print(f"Log directory: {logdir}")
    print(f"Event files: {len(event_files)}")
    for ef in event_files:
        try:
            rel = ef.relative_to(logdir)
        except ValueError:
            rel = ef
        print(f"  - {rel}")
    print(f"Output directory: {outdir}")
    print(f"Scalars (merged tags): {len(tags)}")

    for tag in tags:
        steps, values = _merge_points(merged[tag])
        if not steps:
            continue

        fig, ax = plt.subplots(figsize=(10, 4), dpi=120)
        ax.plot(steps, values, linewidth=0.8)
        ax.set_xlabel("step")
        ax.set_ylabel("value")
        ax.set_title(tag, fontsize=9)
        ax.grid(True, alpha=0.3)
        fig.tight_layout()

        fpath = outdir / (_sanitize_filename(tag) + ".png")
        fig.savefig(fpath)
        plt.close(fig)
        print(f"  wrote {fpath.name}  ({len(steps)} points)")

    print("Done.")


if __name__ == "__main__":
    main()
