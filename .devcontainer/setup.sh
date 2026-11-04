#!/usr/bin/env bash
# Runs once when the codespace is made, so the reader finds everything ready:
#   1. SASPy, in the version range DataStep Studio supports (the DATA step debugger needs it)
#   2. DataStep Studio installed early, when the editor's server is already there (then the SAS programs are in
#      color from the start, without a reload)
#   3. the connection to SAS OnDemand prepared, when the reader gave a user ID and a home region on the
#      "Create codespace" page (codespace secrets SAS_ODA_USER and SAS_ODA_REGION): they only type the password
#   4. a short check of Java and SASPy
# What it did is written to ~/.datastep-studio/setup.log. No step stops the codespace from starting.
set -uo pipefail

studio="$HOME/.datastep-studio"
mkdir -p "$studio/setup"
log="$studio/setup.log"
say() { echo "$(date -u +%H:%M:%S) $*" | tee -a "$log"; }
py=/usr/local/bin/python3

# 1. SASPy
if $py -m pip install --user --quiet "saspy>=5.102,<5.110"; then
  say "SASPy $($py -c 'import saspy; print(saspy.__version__)')"
else
  say "SASPy could not be installed; DataStep Studio: Check Setup offers to install it"
fi

# 2. DataStep Studio before the editor opens
server=$(ls -d /vscode/bin/*/*/bin/code-server "$HOME"/.vscode-remote/bin/*/bin/code-server 2>/dev/null | head -1)
if [ -n "$server" ]; then
  if "$server" --install-extension datastep-labs.datastep-studio >>"$log" 2>&1; then
    say "DataStep Studio installed early ($server)"
  else
    say "DataStep Studio not installed early; the editor installs it when it opens"
  fi
else
  say "no editor server yet; the editor installs DataStep Studio when it opens"
fi

# 3. The connection profile from the codespace secrets (never a password)
user="${SAS_ODA_USER:-}"
region="${SAS_ODA_REGION:-}"
if [ -n "$user" ] && [ -n "$region" ]; then
  if $py - "$user" "$region" "$studio/setup/profile.json" <<'EOF'
import json, re, sys
user, text, out = sys.argv[1].strip(), sys.argv[2].strip().lower(), sys.argv[3]
codes = ['usw2-2', 'apse1-2', 'usw2', 'euw1', 'apse1']
names = {'united states 1': 'usw2', 'united states 2': 'usw2-2', 'europe 1': 'euw1',
         'asia pacific 1': 'apse1', 'asia pacific 2': 'apse1-2'}
m = re.search(r'-([a-z0-9]+(?:-\d+)?)\.oda\.sas\.com', text)
region = text if text in codes else (m.group(1) if m and m.group(1) in codes else names.get(re.sub(r'\s+', ' ', text)))
if not region:
    sys.exit(f'unknown home region "{sys.argv[2]}": use usw2, usw2-2, euw1, apse1 or apse1-2')
with open(out, 'w') as f:
    json.dump({'name': 'SAS OnDemand', 'profile': {'connectionType': 'oda', 'region': region, 'username': user}}, f)
print(region)
EOF
  then
    say "connection profile SAS OnDemand prepared (region $(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["profile"]["region"])' "$studio/setup/profile.json"))"
  else
    say "connection profile not prepared: SAS_ODA_REGION is not a known home region"
  fi
else
  say "no SAS_ODA_USER and SAS_ODA_REGION: the reader adds the connection in Stop 0"
fi

# 4. Check
say "Java: $(java -version 2>&1 | head -1)"
say "Ready. Open START-HERE.md."
exit 0
