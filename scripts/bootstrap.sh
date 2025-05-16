#!/usr/bin/env bash
set -euo pipefail

KEYS_DIR="${KEYS_DIR:-$HOME/.config/sops/age}"
BW_ENTRY_NAME="${BW_ENTRY_NAME:-NixOS Bootstrap Key}" # Name of your Bitwarden entry

if ! command -v rbw >/dev/null 2>&1; then
        echo "Error: RBW not found. Please install it with 'nix-env -iA nixpkgs.rbw'"
        exit 1
fi

# Create directories
mkdir -p "$KEYS_DIR"
chmod 700 "$KEYS_DIR"

# Ensure vault is synced
rbw sync

# Fetch key from Bitwarden
echo "Fetching bootstrap key from Bitwarden..."
rbw get -f notes "$BW_ENTRY_NAME" >"$KEYS_DIR/keys.txt"
chmod 600 "$KEYS_DIR/keys.txt"

echo "Bootstrap complete. SOPS key is now available at $KEYS_DIR/keys.txt"

# Optionally extract and display the public key for easy reference
if command -v age-keygen >/dev/null 2>&1; then
        echo "Public key for .sops.yaml:"
        age-keygen -y "$KEYS_DIR/keys.txt"
fi

echo "You can now run: nixos-rebuild switch --flake .#mbp"
