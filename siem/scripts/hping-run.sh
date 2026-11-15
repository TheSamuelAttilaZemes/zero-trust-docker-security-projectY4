#!/bin/sh
set -eu

LOG_DIR="/logs/hping"
mkdir -p "${LOG_DIR}"

TARGET=""
for ARG in "$@"; do
  TARGET="${ARG}"
done

ARGS_ESCAPED=$(printf '%s ' "$@" | sed 's/\\/\\\\/g; s/"/\\"/g; s/[[:space:]]*$//')

printf '{"ts":"%s","tool":"hping","mode":"manual","target":"%s","args":"%s"}\n' \
  "$(date -Iseconds)" \
  "${TARGET}" \
  "${ARGS_ESCAPED}" >> "${LOG_DIR}/hping.jsonl"

exec hping3 "$@"
