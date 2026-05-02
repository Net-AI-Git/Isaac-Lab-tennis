#!/usr/bin/env bash
set -euo pipefail

# Run IsaacLab play sequentially on selected top checkpoints.
# Usage:
#   /workspace/Isaac-Lab-tennis/scripts/run_g1_flat_play_top5.sh
#   PLAY_VIDEO_LENGTH=600 HEADLESS=1 /workspace/Isaac-Lab-tennis/scripts/run_g1_flat_play_top5.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

ISAACLAB_ROOT="${ISAACLAB_ROOT:-/workspace/IsaacLab}"
ISAACLAB_ENV="${ISAACLAB_ENV:-/workspace/env_isaaclab}"

TASK="${TASK:-Isaac-Velocity-Flat-G1-Play-v0}"
NUM_ENVS="${NUM_ENVS:-1}"
SEED="${SEED:-42}"
PLAY_VIDEO_LENGTH="${PLAY_VIDEO_LENGTH:-600}"
HEADLESS="${HEADLESS:-1}"

RUN_DIR="${RUN_DIR:-${REPO_ROOT}/g1_run/logs/rsl_rl/g1_flat_train/2026-05-02_15-57-10_baseline}"
PLAY_VIDEO_DIR="${RUN_DIR}/videos/play"
ARCHIVE_DIR="${RUN_DIR}/videos/play_top5"

CHECKPOINTS=(
  "model_2050.pt"
  "model_1950.pt"
  "model_1800.pt"
  "model_1600.pt"
  "model_1450.pt"
)

if [[ ! -d "${RUN_DIR}" ]]; then
  echo "Run directory does not exist: ${RUN_DIR}"
  exit 1
fi

if [[ -z "${TERM:-}" || "${TERM}" == "dumb" ]]; then
  export TERM="xterm"
fi
export ACCEPT_EULA="${ACCEPT_EULA:-Y}"
export OMNI_KIT_ACCEPT_EULA="${OMNI_KIT_ACCEPT_EULA:-yes}"

if [[ -f "${ISAACLAB_ENV}/bin/activate" ]]; then
  # shellcheck source=/dev/null
  source "${ISAACLAB_ENV}/bin/activate"
fi

mkdir -p "${PLAY_VIDEO_DIR}" "${ARCHIVE_DIR}"

for ckpt in "${CHECKPOINTS[@]}"; do
  ckpt_path="${RUN_DIR}/${ckpt}"
  if [[ ! -f "${ckpt_path}" ]]; then
    echo "Skipping missing checkpoint: ${ckpt_path}"
    continue
  fi

  echo "============================================================"
  echo "Playing checkpoint: ${ckpt}"
  echo "Checkpoint path: ${ckpt_path}"

  headless_flag=""
  if [[ "${HEADLESS}" == "1" ]]; then
    headless_flag="--headless"
  fi

  "${ISAACLAB_ROOT}/isaaclab.sh" -p "${ISAACLAB_ROOT}/scripts/reinforcement_learning/rsl_rl/play.py" \
    --task "${TASK}" \
    --checkpoint "${ckpt_path}" \
    --num_envs "${NUM_ENVS}" \
    --seed "${SEED}" \
    --video \
    --video_length "${PLAY_VIDEO_LENGTH}" \
    ${headless_flag}

  latest_video="$(ls -t "${PLAY_VIDEO_DIR}"/rl-video-step-*.mp4 2>/dev/null | head -n 1 || true)"
  if [[ -n "${latest_video}" ]]; then
    target_video="${ARCHIVE_DIR}/${ckpt%.pt}_play.mp4"
    cp -f "${latest_video}" "${target_video}"
    echo "Saved: ${target_video}"
  else
    echo "Warning: no play video found for ${ckpt}"
  fi
done

echo "Done."
echo "Checkpoint videos: ${ARCHIVE_DIR}"
