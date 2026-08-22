#!/usr/bin/env bash
set -euo pipefail

repo_url="${SIMPLEOPENVPN_REPO_URL:-https://github.com/diogogc/simple-openvpn.git}"

omarchy pkg add openvpn jq zenity
omarchy plugin add "$repo_url" --enable --yes

echo "SimpleOpenVPN installed."
