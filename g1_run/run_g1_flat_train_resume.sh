#!/usr/bin/env bash
# Continue training from a checkpoint.
#
# Option A — checkpoint already under logs/rsl_rl/<EXPERIMENT_NAME>/<LOAD_RUN>/:
#   LOAD_RUN=2026-01-01_12-00-00_baseline CHECKPOINT=model_0500.pt ./run_g1_flat_train_resume.sh
#
# Option B — arbitrary .pt path (copied into log tree for RSL-RL):
#   CHECKPOINT_SRC=/path/to/model.pt EXPERIMENT_NAME=g1_flat_train RUN_NAME=resume1 ./run_g1_flat_train_resume.sh

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=run_g1_flat_train_env.sh
source "${SCRIPT_DIR}/run_g1_flat_train_env.sh"

LOAD_RUN="${LOAD_RUN:-}"
CHECKPOINT="${CHECKPOINT:-}"
CHECKPOINT_SRC="${CHECKPOINT_SRC:-}"
CHECKPOINT_STAGE_NAME="${CHECKPOINT_STAGE_NAME:-}"

resume_args=(--resume)

if [[ -n "${CHECKPOINT_SRC}" ]]; then
  [[ -f "${CHECKPOINT_SRC}" ]] || { echo "CHECKPOINT_SRC is not a file: ${CHECKPOINT_SRC}" >&2; exit 1; }
  stage_name="${CHECKPOINT_STAGE_NAME:-resume_ckpt_${RUN_NAME}}"
  stage_dir="${RUN_DIR}/logs/rsl_rl/${EXPERIMENT_NAME}/${stage_name}"
  mkdir -p "${stage_dir}"
  cp -f "${CHECKPOINT_SRC}" "${stage_dir}/"
  resume_args+=(--load_run "${stage_name}" --checkpoint "$(basename "${CHECKPOINT_SRC}")")
else
  [[ -n "${LOAD_RUN}" ]] && resume_args+=(--load_run "${LOAD_RUN}")
  [[ -n "${CHECKPOINT}" ]] && resume_args+=(--checkpoint "${CHECKPOINT}")
fi

g1_flat_train_launch "${resume_args[@]}"

echo "Done. Outputs: ${RUN_DIR}/logs/rsl_rl/${EXPERIMENT_NAME}/"
