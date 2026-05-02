#!/usr/bin/env bash
set -euo pipefail

export TERM="${TERM:-xterm-256color}"

uv venv --python 3.11 --seed env_isaaclab
source env_isaaclab/bin/activate

pip install --upgrade pip

pip install "isaacsim[all,extscache]==5.1.0" --extra-index-url https://pypi.nvidia.com

pip install -U torch==2.7.0 torchvision==0.22.0 --index-url https://download.pytorch.org/whl/cu128

git clone https://github.com/isaac-sim/IsaacLab.git
cd IsaacLab

sudo apt install -y cmake build-essential

./isaaclab.sh --install
