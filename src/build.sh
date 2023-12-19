#!/usr/bin/env bash

CURRENT_DIR="$(dirname "${BASH_SOURCE[0]}")"

"${CURRENT_DIR}/../vendor/bin/embed.sh" --once=y "${CURRENT_DIR}/attach_keys.sh" >"${CURRENT_DIR}/../attach_keys.sh"
chmod +x "${CURRENT_DIR}/../attach_keys.sh"
