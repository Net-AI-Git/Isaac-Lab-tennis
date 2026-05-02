#!/usr/bin/env bash
# Connect to the local Isaac-Lab-tennis repository: load .env, git identity, and origin URL (no clone/fetch/pull).
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
  if [[ -n "${GIT_USER_NAME:-}" ]]; then
    git config user.name "${GIT_USER_NAME}"
  fi
  if [[ -n "${GIT_USER_EMAIL:-}" ]]; then
    git config user.email "${GIT_USER_EMAIL}"
  fi
}

if ! load_env_file "${SCRIPT_DIR}/.env" 2>/dev/null; then
  load_env_file "${SCRIPT_DIR}/../.env" || true
fi

if [[ ! -d "${REPO_DIR}/.git" ]]; then
  echo "Error: repository not found at ${REPO_DIR}. Clone it first, then run this script." >&2
  exit 1
fi

cd "${REPO_DIR}"
configure_git_identity

if git remote get-url origin &>/dev/null; then
  git remote set-url origin "${REPO_URL_HTTPS}"
else
  git remote add origin "${REPO_URL_HTTPS}"
fi

echo "Connected to ${REPO_NAME}."
echo "Active branch: $(git branch --show-current)"
echo "Path: ${REPO_DIR}"
