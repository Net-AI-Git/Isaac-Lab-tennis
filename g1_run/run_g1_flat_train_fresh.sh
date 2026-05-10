#!/usr/bin/env bash
# First training run (no --resume).
# Override: NUM_ENVS, MAX_ITERATIONS, EXPERIMENT_NAME, RUN_NAME, VIDEO_*, TASK, etc.

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=run_g1_flat_train_env.sh
source "${SCRIPT_DIR}/run_g1_flat_train_env.sh"

g1_flat_train_launch

echo "Done. Outputs: ${RUN_DIR}/logs/rsl_rl/${EXPERIMENT_NAME}/"
