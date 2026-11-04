#!/usr/bin/env bash
# Runs once when the codespace is made: SASPy for the connection to SAS OnDemand.
# The version range is the one DataStep Studio supports (the DATA step debugger needs it).
set -euo pipefail

/usr/local/bin/python3 -m pip install --user --quiet "saspy>=5.102,<5.110"

echo "Java:  $(java -version 2>&1 | head -1)"
echo "SASPy: $(/usr/local/bin/python3 -c 'import saspy; print(saspy.__version__)')"
echo "Ready. Open START-HERE.md."
