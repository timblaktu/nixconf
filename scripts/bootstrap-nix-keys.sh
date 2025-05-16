#!/usr/bin/env bash
set -euo pipefail

export KEYS_DIR="${KEYS_DIR:-$HOME/.config/sops/age}"
export BW_ENTRY_NAME="${BW_ENTRY_NAME:-NixOS Bootstrap Key}"
export BW_EMAIL="${BW_EMAIL:-}"
export BW_PINENTRY="${BW_PINENTRY:-pinentry-curses}"
export RBW_LOCK_TIMEOUT="${RBW_LOCK_TIMEOUT:-86400}"  # Default to 24 hours (86400 seconds)
export NIX_CONFIG="experimental-features = nix-command flakes"

# Function to display instructions for adding RBW to Nix configuration
show_nix_instructions() {
  echo "================================================================="
  echo "RBW (Bitwarden CLI) is not available or properly configured."
  echo "To add RBW to your Nix configuration, do one of the following:"
  echo ""
  echo "1. For NixOS, add to your configuration.nix:"
  echo "----------------------------------------------------------------"
  echo "  environment.systemPackages = with pkgs; ["
  echo "    rbw"
  echo "    # Other packages..."
  echo "  ];"
  echo ""
  echo "  # Optional: Set up as a systemd user service"
  echo "  systemd.user.services.rbw-agent = {"
  echo "    description = \"Bitwarden CLI agent (rbw)\";"
  echo "    wantedBy = [ \"default.target\" ];"
  echo "    serviceConfig = {"
  echo "      ExecStart = \"\${pkgs.rbw}/bin/rbw agent\";"
  echo "      Restart = \"on-failure\";"
  echo "      RestartSec = \"5s\";"
  echo "      Environment = ["
  echo "        \"RBW_LOCK_TIMEOUT=86400\""
  echo "      ];"
  echo "    };"
  echo "  };"
  echo "----------------------------------------------------------------"
  echo ""
  echo "2. For Home Manager, add to your home.nix:"
  echo "----------------------------------------------------------------"
  echo "  home.packages = with pkgs; ["
  echo "    rbw"
  echo "    # Other packages..."
  echo "  ];"
  echo ""
  echo "  # Optional: Use the dedicated Home Manager module"
  echo "  programs.rbw = {"
  echo "    enable = true;"
  echo "    settings = {"
  echo "      email = \"your-email@example.com\";  # Optional"
  echo "      lock_timeout = 86400;"
  echo "      sync_interval = 86400;"
  echo "      pinentry = \"pinentry-curses\";"
  echo "    };"
  echo "  };"
  echo "----------------------------------------------------------------"
  echo ""
  echo "3. For immediate use, install with:"
  echo "   $ nix-env -iA nixpkgs.rbw"
  echo ""
  echo "After installation, run:"
  echo "   $ rbw config setup"
  echo "   $ rbw config set lock_timeout 86400"
  echo "   $ rbw config set sync_interval 86400"
  echo "   $ rbw login"
  echo "================================================================="
  
  # Ask user if they want to temporarily install RBW
  read -p "Would you like to temporarily install RBW for this session? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Installing RBW using nix-shell..."
    USE_TEMP_RBW=true
    return 0
  else
    echo "Exiting. Please install RBW and run this script again."
    exit 1
  fi
}

# Function to check if RBW is properly configured
check_rbw_config() {
  if [[ ! -f "$HOME/.config/rbw/config.json" ]]; then
    return 1
  fi
  
  # Check if we can access the agent
  if ! rbw unlocked &>/dev/null && ! rbw ping &>/dev/null; then
    return 1
  fi
  
  return 0
}

# Function to ensure RBW agent is running
ensure_rbw_agent() {
  # First check if rbw-agent is running
  if ! pgrep -f rbw-agent &>/dev/null; then
    echo "Starting RBW agent..."
    rbw unlock &>/dev/null || rbw login
  fi
  
  # Verify agent is responsive
  if ! rbw ping &>/dev/null; then
    echo "RBW agent is not responding. Attempting to restart..."
    rbw stop-agent &>/dev/null || true
    sleep 1
    rbw unlock || rbw login
  fi
}

# Function to configure RBW
configure_rbw() {
  # Set up basic configuration if needed
  if [[ ! -f "$HOME/.config/rbw/config.json" ]]; then
    echo "Setting up RBW configuration..."
    
    # Prepare arguments for rbw config setup
    SETUP_ARGS=()
    [ -n "$BW_EMAIL" ] && SETUP_ARGS+=(--email "$BW_EMAIL")
    [ -n "$BW_PINENTRY" ] && SETUP_ARGS+=(--pinentry "$BW_PINENTRY")
    
    rbw config setup ${SETUP_ARGS[@]+"${SETUP_ARGS[@]}"}
  fi
  
  # Update configuration as needed
  [ -n "$BW_EMAIL" ] && rbw config set email "$BW_EMAIL"
  [ -n "$BW_PINENTRY" ] && rbw config set pinentry "$BW_PINENTRY"
  
  # Set longer timeouts for better session persistence
  echo "Setting RBW session timeouts..."
  rbw config set lock_timeout "$RBW_LOCK_TIMEOUT"
  rbw config set sync_interval 86400
}

# Main script logic
USE_TEMP_RBW=false

# Check if RBW is available on the host system
if ! command -v rbw &>/dev/null; then
  echo "RBW is not installed on your system."
  show_nix_instructions
else
  # RBW is installed, check if properly configured
  if ! check_rbw_config; then
    echo "RBW is installed but not properly configured."
    configure_rbw
  fi
  
  # Ensure RBW agent is running
  ensure_rbw_agent
fi

# Fetch the Age key from Bitwarden
echo "Preparing to fetch bootstrap key from Bitwarden..."
mkdir -p "$KEYS_DIR"
chmod 700 "$KEYS_DIR"

# Function to fetch the key, using either host RBW or temporary nix-shell RBW
fetch_key() {
  local rbw_cmd="rbw"
  
  if [[ "$USE_TEMP_RBW" == true ]]; then
    rbw_cmd="nix shell nixpkgs#rbw --command rbw"
    # If using temporary RBW, we need to ensure it's configured
    nix shell nixpkgs#rbw --command bash -c "
      rbw config set lock_timeout $RBW_LOCK_TIMEOUT
      rbw config set sync_interval 86400
      rbw unlock || rbw login
      rbw sync
    "
  else
    # Using host RBW, make sure we're synced
    rbw sync
  fi
  
  echo "Retrieving secret from Bitwarden entry: $BW_ENTRY_NAME"
  
  if [[ "$USE_TEMP_RBW" == true ]]; then
    SECRET_CONTENT=$(nix shell nixpkgs#rbw --command rbw get -f notes "$BW_ENTRY_NAME" 2>/dev/null || echo "")
  else
    SECRET_CONTENT=$(rbw get -f notes "$BW_ENTRY_NAME" 2>/dev/null || echo "")
  fi
  
  if [ -z "$SECRET_CONTENT" ]; then
    echo "Error: Secret '$BW_ENTRY_NAME' not found in your Bitwarden vault."
    echo ""
    echo "Please create a secure note in Bitwarden with the following:"
    echo "1. Name it exactly: $BW_ENTRY_NAME"
    echo "2. Generate an Age key pair:"
    echo "   $ nix shell nixpkgs#age --command age-keygen -o age-key.txt"
    echo "3. Copy the ENTIRE contents of age-key.txt into the note field"
    echo "4. Run this script again after creating the secret"
    exit 1
  fi
  
  if ! echo "$SECRET_CONTENT" | grep -q "AGE-SECRET-KEY-"; then
    echo "Error: The retrieved content does not appear to be a valid Age key."
    echo "Please check that your Bitwarden entry contains a proper Age key."
    exit 1
  fi
  
  echo "$SECRET_CONTENT" > "$KEYS_DIR/keys.txt"
}

# Execute the key fetching function
fetch_key

# Set appropriate permissions
chmod 600 "$KEYS_DIR/keys.txt"
echo "Bootstrap complete. SOPS key is now available at $KEYS_DIR/keys.txt"

# Extract and show the public key for .sops.yaml
nix shell nixpkgs#age --command bash -c "
if command -v age-keygen >/dev/null 2>&1; then
  echo 'Public key for .sops.yaml:'
  age-keygen -y '$KEYS_DIR/keys.txt'
fi
"

echo ""
echo "You can now run: nixos-rebuild switch --flake .#mbp"

# If we used a temporary RBW, provide a hint
if [[ "$USE_TEMP_RBW" == true ]]; then
  echo ""
  echo "Note: You used a temporary RBW installation for this session."
  echo "For persistent RBW usage, please follow the installation instructions above."
fi
