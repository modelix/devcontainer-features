#!/bin/sh

# Indexes all MPS projects to speedup the startup

set -x
set -e

find /mps-projects -type d -name ".mps" | while read -r dir; do
  /mps/bin/mps.sh warmup --project-dir="$(dirname "$dir")"
done
