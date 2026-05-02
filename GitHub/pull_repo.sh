#!/usr/bin/env bash
# Connect to the Isaac-Lab-tennis repository using a token from .env and a selectable branch.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
REPO_URL_HTTPS="https://github.com/Net-AI-Git/Isaac-Lab-tennis.git"
REPO_NAME="Isaac-Lab-tennis"
REPO_DIR="${BASE_DIR}/${REPO_NAME}"

load_env_file() {
  local f="$1"
  [[ -f "$f" ]] || return 1
  set +u
  set -a
  # shellcheck source=/dev/null
  source "$f"
  set +a
  set -u
}

configure_git_identity() {
  # Optionally set local git identity from .env values.
  if [[ -n "${GIT_USER_NAME:-}" ]]; then
    git config user.name "${GIT_USER_NAME}"
  fi
  if [[ -n "${GIT_USER_EMAIL:-}" ]]; then
    git config user.email "${GIT_USER_EMAIL}"
  fi
}

# Token loading order: GitHub/.env first, then project-root .env (one level up).
if ! load_env_file "${SCRIPT_DIR}/.env" 2>/dev/null; then
  load_env_file "${SCRIPT_DIR}/../.env" || true
fi

TOKEN="${GITHUB_TOKEN:-${GH_TOKEN:-}}"
if [[ -z "${TOKEN}" ]]; then
  echo "Error: GITHUB_TOKEN (or GH_TOKEN) was not found in .env." >&2
  exit 1
fi

# Branch priority: first CLI argument, then GIT_BRANCH from .env/environment.
if [[ -n "${1:-}" ]]; then
  export GIT_BRANCH="$1"
fi

if [[ -z "${GIT_BRANCH:-}" ]]; then
  echo "Error: GIT_BRANCH is not set. Define it in .env or pass it as an argument." >&2
  exit 1
fi

# Avoid storing the token in the persistent remote URL; use a temporary authenticated URL.
AUTH_BASE="https://oauth2:${TOKEN}@github.com/Net-AI-Git/${REPO_NAME}.git"
export GIT_TERMINAL_PROMPT=0

if [[ ! -d "${REPO_DIR}/.git" ]]; then
  echo "Cloning ${REPO_NAME} (branch: ${GIT_BRANCH})..."
  if git clone --branch "${GIT_BRANCH}" --single-branch "${AUTH_BASE}" "${REPO_DIR}" 2>/dev/null; then
    :
  else
    echo "Branch-specific clone failed; cloning default branch and trying checkout..."
    git clone "${AUTH_BASE}" "${REPO_DIR}"
    cd "${REPO_DIR}"
    git fetch origin "${GIT_BRANCH}" 2>/dev/null && git checkout "${GIT_BRANCH}" || {
      echo "Warning: could not checkout '${GIT_BRANCH}'. Staying on current branch." >&2
    }
  fi
  cd "${REPO_DIR}"
  configure_git_identity
  git remote set-url origin "${REPO_URL_HTTPS}"
else
  echo "Updating existing repository at ${REPO_DIR}..."
  cd "${REPO_DIR}"
  configure_git_identity
  git remote get-url origin &>/dev/null || git remote add origin "${REPO_URL_HTTPS}"
  # Temporary authenticated URL for fetch/pull only; restore plain HTTPS afterwards.
  git remote set-url origin "${AUTH_BASE}"
  git fetch origin
  git checkout "${GIT_BRANCH}" 2>/dev/null || git checkout -b "${GIT_BRANCH}" "origin/${GIT_BRANCH}" 2>/dev/null || {
    echo "Error: branch '${GIT_BRANCH}' was not found after fetch." >&2
    git remote set-url origin "${REPO_URL_HTTPS}"
    exit 1
  }
  git pull origin "${GIT_BRANCH}" || true
  git remote set-url origin "${REPO_URL_HTTPS}"
fi

cd "${REPO_DIR}"
echo "Ready. Active branch: $(git branch --show-current)"
echo "Path: ${REPO_DIR}"
