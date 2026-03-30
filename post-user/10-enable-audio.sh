#!/usr/bin/env bash

set -euo pipefail

sysetemctl --user enable --now pipewire.service
sysetemctl --user enable --now wireplumber.service
sysetemctl --user enable --now pipewire-pulse.service
