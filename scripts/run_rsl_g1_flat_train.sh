#!/usr/bin/env bash
set -euo pipefail

RUN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${RUN_DIR}/.." && pwd)"
# Ensure local gym task registration (g1_run) is importable when cwd is g1_run.
export PYTHONPATH="${REPO_ROOT}${PYTHONPATH:+:${PYTHONPATH}}"
ISAACLAB_ROOT="${ISAACLAB_ROOT:-/workspace/IsaacLab}"
ISAACLAB_ENV="${ISAACLAB_ENV:-/workspace/env_isaaclab}"

# Defaults (can be overridden from CLI):
#   NUM_ENVS=4096 MAX_ITERATIONS=5000 RUN_NAME=my_run ./run_rsl_g1_flat_train.sh
#   VIDEO_INTERVAL=1000 VIDEO_LENGTH=300 ./run_rsl_g1_flat_train.sh
#   RESUME=1 LOAD_RUN=g1_run_vel_1ms CHECKPOINT=model_1450.pt \
#   EXPERIMENT_NAME=g1_flat_sprint_resume RUN_NAME=from1450_speedup ./run_rsl_g1_flat_train.sh
# Resume from a checkpoint anywhere on disk (copies into IsaacLab log tree for RSL-RL):
#   RESUME=1 CHECKPOINT_SRC="${RUN_DIR}/checkpoints/g1_flat/g1_run_vel_2ms/model_2450.pt" \
#   EXPERIMENT_NAME=g1_flat_vel6_resume RUN_NAME=from2450_vel6 ./run_rsl_g1_flat_train.sh
# Train from scratch (no --resume) with high command speed already set in flat_env_cfg.py:
#   RESUME=0 EXPERIMENT_NAME=g1_flat_vel6_scratch RUN_NAME=baseline ./run_rsl_g1_flat_train.sh
TASK="${TASK:-Isaac-Velocity-Flat-G1-Tennis-v0}"
EXPERIMENT_NAME="${EXPERIMENT_NAME:-g1_flat_train}"
RUN_NAME="${RUN_NAME:-baseline}"
NUM_ENVS="${NUM_ENVS:-4096}"
MAX_ITERATIONS="${MAX_ITERATIONS:-3000}"
SEED="${SEED:-42}"
VIDEO_LENGTH="${VIDEO_LENGTH:-200}"
VIDEO_INTERVAL="${VIDEO_INTERVAL:-2000}"
RESUME="${RESUME:-0}"
LOAD_RUN="${LOAD_RUN:-}"
CHECKPOINT="${CHECKPOINT:-}"
# Absolute path to a .pt file when it is not already under logs/rsl_rl/<experiment>/...
CHECKPOINT_SRC="${CHECKPOINT_SRC:-}"
CHECKPOINT_STAGE_NAME="${CHECKPOINT_STAGE_NAME:-}"

mkdir -p "${RUN_DIR}/logs"
mkdir -p "${RUN_DIR}/checkpoints"
mkdir -p "${RUN_DIR}/logs/rsl_rl/${EXPERIMENT_NAME}"
echo "[INFO] RSL-RL experiment log root: ${RUN_DIR}/logs/rsl_rl/${EXPERIMENT_NAME}/"
echo "[INFO] Each run adds a subfolder: <timestamp>_${RUN_NAME}/ (created once training passes startup)"

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

extra_args=()
if [[ "${RESUME}" == "1" ]]; then
  extra_args+=(--resume)
  if [[ -n "${CHECKPOINT_SRC}" ]]; then
    if [[ ! -f "${CHECKPOINT_SRC}" ]]; then
      echo "CHECKPOINT_SRC is not a file: ${CHECKPOINT_SRC}" >&2
      exit 1
    fi
    stage_name="${CHECKPOINT_STAGE_NAME:-resume_ckpt_${RUN_NAME}}"
    # RSL-RL resolves checkpoints under the current project's logs tree:
    # <current working dir>/logs/rsl_rl/<experiment>/...
    stage_root="${RUN_DIR}/logs/rsl_rl/${EXPERIMENT_NAME}"
    stage_dir="${stage_root}/${stage_name}"
    mkdir -p "${stage_dir}"
    cp -f "${CHECKPOINT_SRC}" "${stage_dir}/"
    extra_args+=(--load_run "${stage_name}")
    extra_args+=(--checkpoint "$(basename "${CHECKPOINT_SRC}")")
  else
    if [[ -n "${LOAD_RUN}" ]]; then
      extra_args+=(--load_run "${LOAD_RUN}")
    fi
    if [[ -n "${CHECKPOINT}" ]]; then
      extra_args+=(--checkpoint "${CHECKPOINT}")
    fi
  fi
fi

# Use launcher so ``g1_run`` is imported and ``...-Tennis-v0`` maps to this repo's flat_env_cfg.
"${ISAACLAB_ROOT}/isaaclab.sh" -p "${RUN_DIR}/launch_rsl_g1_flat_train.py" \
  --task "${TASK}" \
  --num_envs "${NUM_ENVS}" \
  --max_iterations "${MAX_ITERATIONS}" \
  --experiment_name "${EXPERIMENT_NAME}" \
  --run_name "${RUN_NAME}" \
  --seed "${SEED}" \
  --video \
  --video_length "${VIDEO_LENGTH}" \
  --video_interval "${VIDEO_INTERVAL}" \
  "${extra_args[@]}" \
  --headless

echo "Training finished."
echo "Outputs: ${RUN_DIR}/logs/rsl_rl/${EXPERIMENT_NAME}/"
