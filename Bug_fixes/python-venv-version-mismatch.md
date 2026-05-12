# Python venv version mismatch

## Problem

Isaac Lab commands failed because the virtual environment was created with **Python 3.11**, but `env_isaaclab/bin/python` could point to the wrong interpreter, e.g. `/usr/bin/python3` (**Python 3.10**), or to a missing interpreter such as `/usr/bin/python3.11`.

The venv metadata confirms the expected version:

- `env_isaaclab/pyvenv.cfg`
- `version_info = 3.11.15`

## Why it broke

Python packages for this venv are installed under the Python 3.11 site-packages directory:

```text
env_isaaclab/lib/python3.11/site-packages
```

If `env_isaaclab/bin/python` runs Python 3.10, or points to a Python 3.11 path that does not exist on the current machine, Isaac Lab cannot use the matching environment correctly. Isaac Lab / Isaac Sim imports can fail before training or play starts.

## What it caused

- Isaac Lab scripts did not start reliably from the repo wrappers.
- Training / resume / play commands could fail before the environment initialized.
- Resume training could fail before the custom Gym environment was registered, making it look like Isaac Lab could not find the environment.
- No useful run output, checkpoint progress, or video output was produced for that failed launch.

The concrete failure seen on this machine was:

```text
[ERROR] Unable to find any Python executable at path: '/workspace/env_isaaclab/bin/python'
```

This happened because `run_g1_flat_train_env.sh` repointed `env_isaaclab/bin/python` to `/usr/bin/python3.11`, but `/usr/bin/python3.11` did not exist on this machine.

## Fix

The fix is in:

```text
Isaac-Lab-tennis/g1_run/run_g1_flat_train_env.sh
```

Before activating the venv, the script now resolves a valid Python 3.11 interpreter from:

- the existing `env_isaaclab/bin/python` if it is valid and really Python 3.11
- the `home = ...` path in `env_isaaclab/pyvenv.cfg`
- `python3.11` on `PATH`
- `uv python find 3.11`

Then it repoints `env_isaaclab/bin/python` to that valid executable:

```bash
ln -sfn "${PYTHON_BIN}" "${ISAACLAB_ENV}/bin/python"
source "${ISAACLAB_ENV}/bin/activate"
hash -r
```

If no Python 3.11 executable is found, the script exits with a clear error and suggests recreating the venv:

```bash
uv venv --python 3.11 --seed "${ISAACLAB_ENV}"
```

If `uv` is also missing, install `uv` / Python 3.11 first, then recreate the venv.

## Related resume fix

`g1_flat_train_launch()` now runs Isaac Lab from `Isaac-Lab-tennis/g1_run`.

This matters because Isaac Lab resolves RSL-RL logs/checkpoints relative to the current working directory:

```text
logs/rsl_rl/<experiment_name>/<load_run>/<checkpoint>
```

The working directory is now stable, so resume runs look under:

```text
Isaac-Lab-tennis/g1_run/logs/rsl_rl/g1_flat_train/
```

That is where the known working run lives:

```text
Isaac-Lab-tennis/g1_run/logs/rsl_rl/g1_flat_train/2026-05-10_16-55-14_baseline/model_2200.pt
```

## Verification

After sourcing the environment, verify:

```bash
python --version
```

Expected:

```text
Python 3.11.x
```

On this machine the fixed venv resolves to:

```text
Python 3.11.15
```

Verify that the custom Gym environment is registered:

```bash
cd /workspace/Isaac-Lab-tennis/g1_run
source ./run_g1_flat_train_env.sh
python - <<'PY'
import gymnasium as gym
import g1_run

spec = gym.spec("Isaac-Velocity-Flat-G1-Tennis-v0")
print(spec.id)
print(spec.entry_point)
print(spec.kwargs["env_cfg_entry_point"])
print(spec.kwargs["rsl_rl_cfg_entry_point"])
PY
```

Expected output:

```text
Isaac-Velocity-Flat-G1-Tennis-v0
isaaclab.envs:ManagerBasedRLEnv
g1_run.flat_env_cfg:G1FlatEnvCfg
g1_run.agents.rsl_rl_ppo_cfg:G1FlatPPORunnerCfg
```

Resume command used after the fix:

```bash
cd /workspace/Isaac-Lab-tennis/g1_run
LOAD_RUN=2026-05-10_16-55-14_baseline CHECKPOINT=model_2200.pt RUN_NAME=0_3_m_s ./run_g1_flat_train_resume.sh
```
