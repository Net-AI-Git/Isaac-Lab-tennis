#!/usr/bin/env bash
set -euo pipefail

RUN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ISAACLAB_ROOT="${ISAACLAB_ROOT:-/workspace/IsaacLab}"
ISAACLAB_ENV="${ISAACLAB_ENV:-/workspace/env_isaaclab}"

# Defaults (can be overridden from CLI):
#   NUM_ENVS=4096 MAX_ITERATIONS=5000 RUN_NAME=my_run ./run_g1_flat_train.sh
#   VIDEO_INTERVAL=1000 VIDEO_LENGTH=300 ./run_g1_flat_train.sh
TASK="${TASK:-Isaac-Velocity-Flat-G1-v0}"
EXPERIMENT_NAME="${EXPERIMENT_NAME:-g1_flat_train}"
RUN_NAME="${RUN_NAME:-baseline}"
NUM_ENVS="${NUM_ENVS:-2048}"
MAX_ITERATIONS="${MAX_ITERATIONS:-3000}"
SEED="${SEED:-42}"
VIDEO_LENGTH="${VIDEO_LENGTH:-200}"
VIDEO_INTERVAL="${VIDEO_INTERVAL:-2000}"

mkdir -p "${RUN_DIR}/logs"
mkdir -p "${RUN_DIR}/checkpoints"

# Ensure terminal and Omniverse runtime are configured for non-interactive runs.
if [[ -z "${TERM:-}" || "${TERM}" == "dumb" ]]; then
  export TERM="xterm"
fi
export ACCEPT_EULA="${ACCEPT_EULA:-Y}"
export OMNI_KIT_ACCEPT_EULA="${OMNI_KIT_ACCEPT_EULA:-yes}"

# Activate Isaac Lab Python environment if available.
if [[ -f "${ISAACLAB_ENV}/bin/activate" ]]; then
  # shellcheck source=/dev/null
  source "${ISAACLAB_ENV}/bin/activate"
fi

"${ISAACLAB_ROOT}/isaaclab.sh" -p "${ISAACLAB_ROOT}/scripts/reinforcement_learning/rsl_rl/train.py" \
  --task "${TASK}" \
  --num_envs "${NUM_ENVS}" \
  --max_iterations "${MAX_ITERATIONS}" \
  --experiment_name "${EXPERIMENT_NAME}" \
  --run_name "${RUN_NAME}" \
  --seed "${SEED}" \
  --video \
  --video_length "${VIDEO_LENGTH}" \
  --video_interval "${VIDEO_INTERVAL}" \
  --headless

echo "Training finished."
echo "Outputs: ${ISAACLAB_ROOT}/logs/rsl_rl/${EXPERIMENT_NAME}/${RUN_NAME}"
