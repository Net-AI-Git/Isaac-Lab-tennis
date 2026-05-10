#!/usr/bin/env bash
# Shared setup for G1 flat training. Source this file; do not execute directly.
# Video defaults match Isaac-Lab-tennis/scripts/video_cfg.txt (maintain manually).

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  echo "Source this file from run_g1_flat_train_fresh.sh or run_g1_flat_train_resume.sh" >&2
  exit 1
fi

set -euo pipefail

RUN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${RUN_DIR}/.." && pwd)"
export PYTHONPATH="${REPO_ROOT}${PYTHONPATH:+:${PYTHONPATH}}"
ISAACLAB_ROOT="${ISAACLAB_ROOT:-/workspace/IsaacLab}"
ISAACLAB_ENV="${ISAACLAB_ENV:-/workspace/env_isaaclab}"

TASK="${TASK:-Isaac-Velocity-Flat-G1-Tennis-v0}"
EXPERIMENT_NAME="${EXPERIMENT_NAME:-g1_flat_train}"
RUN_NAME="${RUN_NAME:-baseline}"
NUM_ENVS="${NUM_ENVS:-4096}"
MAX_ITERATIONS="${MAX_ITERATIONS:-3000}"
SEED="${SEED:-42}"
VIDEO_LENGTH="${VIDEO_LENGTH:-300}"
VIDEO_TIMESTEPS="${VIDEO_TIMESTEPS:-1000}"
VIDEO_INTERVAL="${VIDEO_INTERVAL:-${VIDEO_TIMESTEPS}}"

mkdir -p "${RUN_DIR}/logs" "${RUN_DIR}/checkpoints" "${RUN_DIR}/logs/rsl_rl/${EXPERIMENT_NAME}"
echo "[INFO] Logs: ${RUN_DIR}/logs/rsl_rl/${EXPERIMENT_NAME}/  (subfolder: <timestamp>_${RUN_NAME}/)"
echo "[INFO] Video: every ${VIDEO_INTERVAL} steps, length ${VIDEO_LENGTH} steps"

if [[ -z "${TERM:-}" || "${TERM}" == "dumb" ]]; then
  export TERM="xterm"
fi
export ACCEPT_EULA="${ACCEPT_EULA:-Y}"
export OMNI_KIT_ACCEPT_EULA="${OMNI_KIT_ACCEPT_EULA:-yes}"

# shellcheck source=/dev/null
source "${ISAACLAB_ENV}/bin/activate"

# Optional extra args, e.g. --resume --load_run ... --checkpoint ...
g1_flat_train_launch() {
  "${ISAACLAB_ROOT}/isaaclab.sh" -p "${RUN_DIR}/launch_rsl_flat_train.py" \
    --task "${TASK}" \
    --num_envs "${NUM_ENVS}" \
    --max_iterations "${MAX_ITERATIONS}" \
    --experiment_name "${EXPERIMENT_NAME}" \
    --run_name "${RUN_NAME}" \
    --seed "${SEED}" \
    --video \
    --video_length "${VIDEO_LENGTH}" \
    --video_interval "${VIDEO_INTERVAL}" \
    "$@" \
    --headless
}
