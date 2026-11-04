#!/usr/bin/env bash
# Runs once when the codespace is made: SASPy for the connection to SAS OnDemand, in the version range DataStep
# Studio supports (the DATA step debugger needs it), and a short check. DataStep Studio itself is installed by the
# editor (devcontainer.json). What it did is written to ~/.datastep-studio/setup.log.
set -uo pipefail

mkdir -p "$HOME/.datastep-studio"
log="$HOME/.datastep-studio/setup.log"
say() { echo "$(date -u +%H:%M:%S) $*" | tee -a "$log"; }
py=/usr/local/bin/python3

if $py -m pip install --user --quiet "saspy>=5.102,<5.110"; then
  say "SASPy $($py -c 'import saspy; print(saspy.__version__)')"
else
  say "SASPy could not be installed; DataStep Studio: Check Setup offers to install it"
fi
say "Java: $(java -version 2>&1 | head -1)"
say "Ready. Open START-HERE.md."
exit 0
