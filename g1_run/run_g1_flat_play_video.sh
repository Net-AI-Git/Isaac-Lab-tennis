#!/usr/bin/env bash
set -euo pipefail
[[ "${TERM:-}" == dumb || -z "${TERM:-}" ]] && export TERM=xterm
S="$(cd "$(dirname "$0")" && pwd)"
export PYTHONPATH="$(cd "$S/.." && pwd)${PYTHONPATH:+:$PYTHONPATH}"
export ACCEPT_EULA=Y OMNI_KIT_ACCEPT_EULA=yes
[[ -f "${ISAACLAB_ENV:-/workspace/env_isaaclab}/bin/activate" ]] && . "${ISAACLAB_ENV:-/workspace/env_isaaclab}/bin/activate"
[[ "${HEADLESS:-1}" == 1 ]] && H=(--headless) || H=()
"${ISAACLAB_ROOT:-/workspace/IsaacLab}/isaaclab.sh" -p "$S/launch_rsl_flat_play.py" \
  --play-lin-vel-x "${G1_PLAY_LIN_VEL_X:-1.0}" \
  --task "${TASK:-Isaac-Velocity-Flat-G1-Tennis-PlayVel-v0}" \
  --checkpoint "${CHECKPOINT:-$S/checkpoints/g1_flat/checkpoints/vel_0_1/model_2200.pt}" \
  --num_envs "${NUM_ENVS:-1}" --seed "${SEED:-42}" --video --video_length "${PLAY_VIDEO_LENGTH:-600}" "${H[@]}"
