#!/usr/bin/env python3
"""
Read TensorBoard scalar logs and save each metric as a PNG.

Dependencies: pip install tensorboard matplotlib

  python3 plot_tfevents_scalars.py --logdir path/to/run_folder

  python3 plot_tfevents_scalars.py --events path/to/events.out.tfevents.XXX

Default output is a *sibling* of the run folder: <parent>/<run_name>_tfevents_plots
Never put --out inside the logdir: TensorBoard scans that directory, and extra
subfolders (e.g. an old tfevents_plots/) can break loading.
If you intentionally need this behavior, pass --allow-out-inside-logdir.

For --events with a file path, a single-file copy is read from a small temp
directory (prefix "plot_"; do not use "tfevents" in the temp dir name — TensorBoard
fails in that case on some setups).
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import sys
import tempfile
from pathlib import Path

import matplotlib

matplotlib.use("Agg")
import matplotlib.pyplot as plt

from tensorboard.backend.event_processing.event_accumulator import EventAccumulator

# Isolated read uses a short prefix ("plot_"). Names like "plot_tfevents_*" break
# EventAccumulator.Reload() on some TensorBoard builds (IsADirectoryError on the temp dir).
_ISOLATED_TMP_PARENT = Path(
    os.environ.get("PLOT_TFEvents_TMP", str(Path(__file__).resolve().parent / ".cache" / "tfevents_isolated"))
)


def _default_outdir(logdir: Path) -> Path:
    return (logdir.parent / f"{logdir.name}_tfevents_plots").resolve()


def _outdir_inside_logdir(logdir: Path, outdir: Path) -> bool:
    logdir, outdir = logdir.resolve(), outdir.resolve()
    try:
        outdir.relative_to(logdir)
        return True
    except ValueError:
        return False


def _isolated_events_logdir(events_file: Path) -> tuple[str, str]:
    _ISOLATED_TMP_PARENT.mkdir(parents=True, exist_ok=True)
    td = tempfile.mkdtemp(prefix="plot_", dir=str(_ISOLATED_TMP_PARENT))
    dst = Path(td) / events_file.name
    shutil.copy2(events_file, dst)
    return str(Path(td).resolve()), td


def _resolve_logdir(events: str | None, logdir: str | None) -> Path:
    if logdir:
        return Path(logdir).resolve()
    if events:
        p = Path(events).resolve()
        if p.is_file():
            return p.parent
        if p.is_dir():
            return p
        raise SystemExit(f"Path does not exist: {p}")
    raise SystemExit("Provide --logdir or --events")


def _sanitize_filename(tag: str) -> str:
    s = re.sub(r"[^a-zA-Z0-9._-]+", "_", tag)
    return s[:200] if len(s) > 200 else s


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Export TensorBoard scalar curves from tfevents to PNG files."
    )
    g = parser.add_mutually_exclusive_group(required=True)
    g.add_argument(
        "--logdir",
        type=str,
        help="Directory that contains events.out.tfevents.*",
    )
    g.add_argument(
        "--events",
        type=str,
        help="Path to a tfevents file or a directory (see --logdir)",
    )
    parser.add_argument(
        "--out",
        type=str,
        default=None,
        help="Output directory (default: sibling <run_name>_tfevents_plots; not inside --logdir)",
    )
    parser.add_argument(
        "--list-tags",
        action="store_true",
        help="Only print scalar tag names",
    )
    parser.add_argument(
        "--allow-out-inside-logdir",
        action="store_true",
        help="Allow --out to be inside --logdir (can interfere with TensorBoard scanning).",
    )
    args = parser.parse_args()

    logdir = _resolve_logdir(args.events, args.logdir)
    if not logdir.is_dir():
        print(f"Not a directory: {logdir}", file=sys.stderr)
        sys.exit(1)

    outdir = (
        Path(args.out).resolve() if args.out else _default_outdir(logdir)
    )
    if not args.list_tags and _outdir_inside_logdir(logdir, outdir) and not args.allow_out_inside_logdir:
        print(
            "Error: --out cannot be inside the log directory (breaks TensorBoard). "
            "Omit --out for the default sibling folder, use a path outside the logdir, "
            "or pass --allow-out-inside-logdir if you understand the risk.",
            file=sys.stderr,
        )
        sys.exit(3)

    events_file: Path | None = None
    if args.events:
        ep = Path(args.events).resolve()
        if ep.is_file():
            events_file = ep

    if events_file is not None:
        acc_logdir, cleanup_tmp = _isolated_events_logdir(events_file)
    else:
        acc_logdir, cleanup_tmp = str(logdir), None

    acc: EventAccumulator | None = None
    try:
        acc = EventAccumulator(
            acc_logdir,
            size_guidance={"scalars": 0},
        )
        try:
            acc.Reload()
        except IsADirectoryError:
            print(
                f"Error: could not read event files under:\n  {logdir}\n"
                "Remove extra folders in that directory (e.g. tfevents_plots) or use "
                "--events pointing to the tfevents file.",
                file=sys.stderr,
            )
            sys.exit(4)

        if not args.list_tags:
            outdir.mkdir(parents=True, exist_ok=True)

        if "scalars" not in acc.Tags() or not acc.Tags()["scalars"]:
            print(f"No scalar data in: {logdir}", file=sys.stderr)
            sys.exit(2)

        tags = sorted(acc.Tags()["scalars"])
        if args.list_tags:
            for t in tags:
                print(t)
            return

        print(f"Log directory: {logdir}")
        print(f"Output directory: {outdir}")
        print(f"Scalars: {len(tags)}")

        for tag in tags:
            rows = acc.Scalars(tag)
            steps = [r.step for r in rows]
            values = [r.value for r in rows]
            if not steps:
                continue

            fig, ax = plt.subplots(figsize=(10, 4), dpi=120)
            ax.plot(steps, values, linewidth=0.8)
            ax.set_xlabel("step")
            ax.set_ylabel("value")
            ax.set_title(tag, fontsize=9)
            ax.grid(True, alpha=0.3)
            fig.tight_layout()

            fname = _sanitize_filename(tag) + ".png"
            fpath = outdir / fname
            if fpath.exists():
                stem, i = fpath.stem, 1
                while fpath.exists():
                    fpath = outdir / f"{stem}_{i}.png"
                    i += 1
            fig.savefig(fpath)
            plt.close(fig)
            print(f"  wrote {fpath.name}  ({len(steps)} points)")

        print("Done.")
    finally:
        if cleanup_tmp:
            shutil.rmtree(cleanup_tmp, ignore_errors=True)


if __name__ == "__main__":
    main()
