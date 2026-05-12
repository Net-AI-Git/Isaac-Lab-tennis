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

_python_is_311() {
  local python_bin="$1"
  [[ -x "${python_bin}" ]] || return 1
  "${python_bin}" - <<'PY' >/dev/null 2>&1
import sys
raise SystemExit(0 if sys.version_info[:2] == (3, 11) else 1)
PY
}

_resolve_python_311() {
  local candidate=""
  local resolved=""

  candidate="${ISAACLAB_ENV}/bin/python"
  resolved="$(readlink -f "${candidate}" 2>/dev/null || true)"
  if [[ -n "${resolved}" ]] && _python_is_311 "${resolved}"; then
    printf '%s\n' "${resolved}"
    return 0
  fi

  if [[ -f "${ISAACLAB_ENV}/pyvenv.cfg" ]]; then
    candidate="$(awk -F' = ' '$1 == "home" { print $2; exit }' "${ISAACLAB_ENV}/pyvenv.cfg")"
    candidate="${candidate%/}/python3.11"
    if _python_is_311 "${candidate}"; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  fi

  candidate="$(command -v python3.11 2>/dev/null || true)"
  if [[ -n "${candidate}" ]] && _python_is_311 "${candidate}"; then
    printf '%s\n' "${candidate}"
    return 0
  fi

  if command -v uv >/dev/null 2>&1; then
    candidate="$(uv python find 3.11 2>/dev/null || true)"
    if [[ -n "${candidate}" ]] && _python_is_311 "${candidate}"; then
      printf '%s\n' "${candidate}"
      return 0
    fi
  fi

  return 1
}

PYTHON_BIN="$(_resolve_python_311)" || {
  echo "[ERROR] Could not find a valid Python 3.11 executable for ${ISAACLAB_ENV}." >&2
  echo "        Recreate the venv with: uv venv --python 3.11 --seed \"${ISAACLAB_ENV}\"" >&2
  return 1
}

# Venv packages live under lib/python3.11, so bin/python must resolve to Python 3.11.
ln -sfn "${PYTHON_BIN}" "${ISAACLAB_ENV}/bin/python"

# shellcheck source=/dev/null
source "${ISAACLAB_ENV}/bin/activate"
hash -r

# Optional extra args, e.g. --resume --load_run ... --checkpoint ...
g1_flat_train_launch() {
  (
    cd "${RUN_DIR}"
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
  )
}
