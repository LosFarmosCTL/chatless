#!/bin/sh

set -eu

REPOSITORY_ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "Error: this script must be run from inside the Chatless repository." >&2
  exit 1
}

if [ ! -x "$REPOSITORY_ROOT/.githooks/pre-commit" ]; then
  echo "Error: the repository's pre-commit hook is missing or not executable." >&2
  exit 1
fi

CURRENT_HOOKS_PATH=$(git -C "$REPOSITORY_ROOT" config --local --get core.hooksPath || true)

if [ -n "$CURRENT_HOOKS_PATH" ] && [ "$CURRENT_HOOKS_PATH" != ".githooks" ]; then
  echo "Error: this clone already uses a custom Git hooks path: $CURRENT_HOOKS_PATH" >&2
  echo "The existing configuration was left unchanged." >&2
  exit 1
fi

git -C "$REPOSITORY_ROOT" config --local core.hooksPath .githooks

echo "Installed Chatless Git hooks for this clone."
