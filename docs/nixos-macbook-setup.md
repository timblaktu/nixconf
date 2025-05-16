# NixOS MacBook Pro Setup with SOPS-NIX and RBW

This guide provides a comprehensive approach for setting up a MacBook Pro with NixOS, incorporating WiFi configuration, SOPS-NIX for secret management, and RBW for Bitwarden integration.

## Overview

1. **Configuration Management**: Flake-based NixOS setup for your MacBook Pro
2. **Secret Management**: SOPS-NIX for encrypted secrets in your configuration
3. **Bootstrap Mechanism**: RBW for fetching initial secrets from Bitwarden
4. **SSH Keys**: Declarative management of host and user SSH keys
5. **WiFi Setup**: Proper configuration with encrypted passwords

## Step 1: Set Up Bootstrap Mechanism

Create a bootstrap script to fetch initial secrets from Bitwarden using RBW:

```bash
#!/usr/bin/env bash
set -euo pipefail

export KEYS_DIR="${KEYS_DIR:-$HOME/.config/sops/age}"
export BW_ENTRY_NAME="${BW_ENTRY_NAME:-NixOS Bootstrap Key}"
export BW_EMAIL="${BW_EMAIL:-}"
export BW_PINENTRY="${BW_PINENTRY:-pinentry-curses}"
export BW_CLIENTID="${BW_CLIENTID:-}"
export BW_CLIENT_SECRET="${BW_CLIENT_SECRET:-}"
export BW_IDENTITY_URL="${BW_IDENTITY_URL:-}"
export BW_API_URL="${BW_API_URL:-}"
export RBW_LOCK_TIMEOUT="${RBW_LOCK_TIMEOUT:-86400}"  # Default to 24 hours (86400 seconds)
export NIX_CONFIG="experimental-features = nix-command flakes"

if ! command -v nix >/dev/null 2>&1; then
  echo "Error: Nix package manager not found. Please install Nix first."
  echo "Visit https://nixos.org/download.html for installation instructions."
  exit 1
fi

echo "Fetching bootstrap key from Bitwarden using RBW..."
mkdir -p "$KEYS_DIR"
chmod 700 "$KEYS_DIR"

set +e
read -d "" -r RBW_SCRIPT << 'EORBW'
#!/usr/bin/env bash
set -euo pipefail

# Initialize config if needed
if [ ! -f "$HOME/.config/rbw/config.json" ]; then
  echo "Setting up RBW configuration..."
  
  # Prepare arguments for rbw config setup
  SETUP_ARGS=()
  [ -n "$BW_EMAIL" ] && SETUP_ARGS+=(--email "$BW_EMAIL")
  [ -n "$BW_PINENTRY" ] && SETUP_ARGS+=(--pinentry "$BW_PINENTRY")
  
  if [ -n "${BW_CLIENTID:-}" ]; then
    SETUP_ARGS+=(
      --identity-url "${BW_IDENTITY_URL:-https://identity.bitwarden.com}"
      --api-url "${BW_API_URL:-https://api.bitwarden.com}"
      --client-id "$BW_CLIENTID"
    )
    [ -n "${BW_CLIENT_SECRET:-}" ] && SETUP_ARGS+=(--client-secret "$BW_CLIENT_SECRET")
  fi

  rbw config setup "${SETUP_ARGS[@]}"
  
  # Set a longer lock timeout to prevent frequent password prompts
  rbw config set lock_timeout "$RBW_LOCK_TIMEOUT"
else
  # Update key configs if environment variables are provided
  [ -n "$BW_EMAIL" ] && rbw config set email "$BW_EMAIL"
  [ -n "$BW_PINENTRY" ] && rbw config set pinentry "$BW_PINENTRY"
  
  # Check and update lock_timeout if needed
  CURRENT_TIMEOUT=$(rbw config get lock_timeout 2>/dev/null || echo "3600")
  if [ "$CURRENT_TIMEOUT" != "$RBW_LOCK_TIMEOUT" ]; then
    echo "Updating lock timeout to $RBW_LOCK_TIMEOUT seconds"
    rbw config set lock_timeout "$RBW_LOCK_TIMEOUT"
  fi
  
  if [ -n "${BW_CLIENTID:-}" ]; then
    rbw config set identity_url "${BW_IDENTITY_URL:-https://identity.bitwarden.com}"
    rbw config set api_url "${BW_API_URL:-https://api.bitwarden.com}"
    rbw config set client_id "$BW_CLIENTID"
    [ -n "${BW_CLIENT_SECRET:-}" ] && rbw config set client_secret "$BW_CLIENT_SECRET"
  fi
fi

# Restart the agent to apply new settings and clear any locked state
echo "Ensuring rbw-agent is running with updated settings..."
rbw stop-agent >/dev/null 2>&1 || true
sleep 1

# Check if the sync_interval is set - if not, set it to a high value
# This keeps the agent running persistently
SYNC_INTERVAL=$(rbw config get sync_interval 2>/dev/null || echo "3600")
if [ "$SYNC_INTERVAL" != "86400" ]; then
  echo "Setting sync interval to 86400 seconds to keep agent persistent"
  rbw config set sync_interval 86400
fi

echo "Logging into Bitwarden and syncing vault..."
# Check if already unlocked to avoid password prompt
if ! rbw unlocked >/dev/null 2>&1; then
  rbw unlock || rbw login
fi

rbw sync

echo "Retrieving secret from Bitwarden entry: $BW_ENTRY_NAME"
SECRET_CONTENT=$(rbw get -f notes "$BW_ENTRY_NAME" 2>/dev/null || echo "")

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
EORBW
set -e

echo "calling nix shell.."
nix shell nixpkgs#rbw --command bash -c "$RBW_SCRIPT" | sed 's/^/    /'
echo "nix shell returned $?"

chmod 600 "$KEYS_DIR/keys.txt"
echo "Bootstrap complete. SOPS key is now available at $KEYS_DIR/keys.txt"

nix shell nixpkgs#age --command bash -c "
if command -v age-keygen >/dev/null 2>&1; then
  echo 'Public key for .sops.yaml:'
  age-keygen -y '$KEYS_DIR/keys.txt'
fi
"

echo "You can now run: nixos-rebuild switch --flake .#mbp"
```

Save this as `bootstrap.sh` in your NixOS configuration directory and make it executable with `chmod +x bootstrap.sh`.

## Step 2: Prepare Bitwarden Entry

1. Generate an Age key pair:
   ```bash
   NIX_CONFIG="experimental-features = nix-command flakes" nix shell nixpkgs#age --command age-keygen -o age-key.txt
   ```

2. Create a secure note in Bitwarden named "NixOS Bootstrap Key"
   - Copy the entire contents of `age-key.txt` into the note field
   - Make sure to include both public and private key parts

## Step 3: Update Flake Configuration

Update your `flake.nix` to include SOPS-NIX:

```nix
{
  description = "My Nix flake combining NixOS and HomeManager configs";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Add sops-nix input
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nvf, home-manager, sops-nix, ... } @ inputs: let
    inherit (self) outputs;
  in {
    nixosConfigurations = {
      mbp = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [
          ./nixos/configuration.nix
          # Add sops-nix module
          sops-nix.nixosModules.sops
        ];
      };
    };
    
    homeConfigurations = {
      "tim@mbp" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [
          ./home-manager/home.nix
          # Optional: Add sops-nix for home-manager if needed
          sops-nix.homeManagerModules.sops
        ];
      };
    };
  };
}
```

## Step 4: Set Up SOPS Configuration

Create a `.sops.yaml` file in your configuration root:

```yaml
# .sops.yaml
keys:
  # Bootstrap Age key - replace with your actual public key
  - &bootstrap_age age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
  
  # Eventually add these after first deploy (commented until available)
  # - &mbp_host ssh-ed25519 AAAA...  # Host SSH key
  # - &tim_ssh ssh-ed25519 BBBB...   # User SSH key

creation_rules:
  - path_regex: secrets/.*\.yaml$
    key_groups:
      - age:
        - *bootstrap_age
        # - *mbp_host
        # - *tim_ssh
```

## Step 5: Update Configuration for Declarative SSH Keys

Update your `configuration.nix`:

```nix
{ config, lib, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
  ];

  # Existing configuration...

  # Add SOPS configuration
  sops = {
    defaultSopsFile = ../secrets/wifi.yaml;
    age = {
      # Use the bootstrapped Age key
      keyFile = "/home/tim/.config/sops/age/keys.txt";
    };
    secrets = {
      "wifi/SUMMIT-VIS" = {
        owner = config.users.users.tim.name;
      };
      # Add other secrets as needed
    };
  };

  # Declaratively manage host SSH keys
  services.openssh = {
    enable = true;
    hostKeys = [
      {
        path = "/etc/ssh/ssh_host_ed25519_key";
        type = "ed25519";
      }
      {
        path = "/etc/ssh/ssh_host_rsa_key";
        type = "rsa";
        bits = 4096;
      }
    ];
    # Security settings
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # User SSH key generation
  system.activationScripts.generateUserSSHKey = lib.stringAfter [ "users" "groups" ] ''
    if [ ! -f /home/tim/.ssh/id_ed25519 ]; then
      mkdir -p /home/tim/.ssh
      ${pkgs.openssh}/bin/ssh-keygen -t ed25519 -f /home/tim/.ssh/id_ed25519 -N ""
      chown -R tim:tim /home/tim/.ssh
      chmod 700 /home/tim/.ssh
      chmod 600 /home/tim/.ssh/id_ed25519
    fi
  '';

  # Update WiFi configuration to use encrypted passwords
  networking = {
    hostName = "mbp";
    useNetworkd = true;
    firewall.enable = false;
    wireless = {
      enable = true;
      networks = {
        "SUMMIT-VIS" = {
          # Use the path to the decrypted secret
          pskRaw = config.sops.secrets."wifi/SUMMIT-VIS".path;
        };
      };
    };
  };

  # Add RBW to your system packages
  environment.systemPackages = with pkgs; [
    # Existing packages...
    rbw
    age
    ssh-to-age  # Useful for converting SSH keys to Age format
    sops
  ];

  # Rest of your configuration...
}
```

## Step 6: Create Encrypted Secrets

1. Create a plain text secrets file first:
   ```bash
   mkdir -p secrets
   echo 'wifi:
  SUMMIT-VIS: "summ1tv1s1t0r"' > secrets/wifi.yaml
   ```

2. Encrypt it with SOPS:
   ```bash
   NIX_CONFIG="experimental-features = nix-command flakes" nix shell nixpkgs#sops --command sops -e -i secrets/wifi.yaml
   ```

## Step 7: Complete Deployment Workflow

Here's the complete workflow to set up your system:

1. **First-time setup on your Ubuntu WSL or other machine**:
   ```bash
   # Clone your NixOS configuration
   git clone https://your-repo-url.git nixos-config
   cd nixos-config
   
   # Run the bootstrap script to fetch Age key from Bitwarden
   ./bootstrap.sh
   
   # Copy the key to a USB drive or use secure transfer method
   # to get it to your MacBook Pro
   ```

2. **On your MacBook Pro**:
   ```bash
   # Place the key in the right location
   mkdir -p ~/.config/sops/age
   # Copy from USB drive or secure transfer
   cp /path/to/keys.txt ~/.config/sops/age/keys.txt
   chmod 600 ~/.config/sops/age/keys.txt
   
   # Apply configuration
   sudo nixos-rebuild switch --flake .#mbp
   ```

3. **After first successful build**:
   ```bash
   # Extract public keys from generated SSH keys
   ssh-keygen -y -f /etc/ssh/ssh_host_ed25519_key > host_key.pub
   ssh-keygen -y -f /home/tim/.ssh/id_ed25519 > user_key.pub
   
   # Update .sops.yaml with these keys (uncomment the commented lines)
   
   # Re-encrypt secrets with new recipients
   sops updatekeys secrets/wifi.yaml
   ```

4. **Updating secrets workflow**:
   ```bash
   # Edit encrypted secrets directly
   sops secrets/wifi.yaml
   
   # Apply changes
   sudo nixos-rebuild switch --flake .#mbp
   ```

## Step 8: Additional Enhancements

1. **Add more WiFi networks**:
   ```bash
   # Edit encrypted secrets
   sops secrets/wifi.yaml
   
   # Add new network under the wifi section
   # wifi:
   #   SUMMIT-VIS: "summ1tv1s1t0r"
   #   HomeNetwork: "your-password-here"
   
   # Update configuration.nix
   # sops.secrets."wifi/HomeNetwork" = {};
   # networking.wireless.networks."HomeNetwork".pskRaw = config.sops.secrets."wifi/HomeNetwork".path;
   ```

2. **User-specific configurations**:
   - Consider moving user-specific SSH configuration to home-manager
   - Add additional secrets for user applications

3. **Persistence setup**:
   ```nix
   { config, lib, pkgs, ... }: {
     environment.persistence."/persist" = {
       hideMounts = true;
       directories = [
         "/etc/ssh"                # Persist host keys
         "/home/tim/.ssh"          # Persist user SSH keys
         "/home/tim/.config/sops/age"  # Persist Age keys
       ];
     };
   }
   ```

4. **Multi-host management**:
   ```yaml
   # .sops.yaml
   keys:
     # Bootstrap key
     - &bootstrap_age age1xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
     
     # Host-specific keys
     - &mbp_host ssh-ed25519 AAAA...
     - &desktop_host ssh-ed25519 BBBB...
     
     # User keys
     - &tim_ssh ssh-ed25519 CCCC...

   creation_rules:
     # Shared secrets (all machines)
     - path_regex: secrets/shared/.*\.yaml$
       key_groups:
         - age:
           - *bootstrap_age
           - *mbp_host
           - *desktop_host
           - *tim_ssh
     
     # MacBook Pro specific secrets
     - path_regex: secrets/mbp/.*\.yaml$
       key_groups:
         - age:
           - *bootstrap_age
           - *mbp_host
           - *tim_ssh
   ```

## Troubleshooting

1. **Nix command not found or flakes not enabled**:
   - Make sure you have enabled experimental features in your Nix configuration
   - You can add this to your `~/.config/nix/nix.conf`:
     ```
     experimental-features = nix-command flakes
     ```
   - Or use the `NIX_CONFIG` environment variable as shown in the scripts

2. **Issues with RBW authentication**:
   - RBW might ask for your master password on first use
   - You may need to set up a pinentry program:
     ```bash
     NIX_CONFIG="experimental-features = nix-command flakes" nix shell nixpkgs#rbw --command rbw config set pinentry pinentry-curses
     ```

3. **SSH key permissions**:
   - Ensure proper permissions on SSH keys: directories should be 700, private keys 600
   - If using host keys, ensure they're owned by root
   - If using user keys, ensure they're owned by the appropriate user

4. **SOPS decryption failures**:
   - Verify the Age key path is correct in your configuration
   - Check that the key in the path matches the one used to encrypt the secrets
   - Ensure the key is accessible to the user running the nixos-rebuild command

## References and Resources

- [SOPS-NIX Documentation](https://github.com/Mic92/sops-nix)
- [Age Encryption Tool](https://github.com/FiloSottile/age)
- [RBW Documentation](https://github.com/doy/rbw)
- [NixOS Wiki: Flakes](https://nixos.wiki/wiki/Flakes)
- [NixOS Hardware: Apple](https://github.com/NixOS/nixos-hardware/tree/master/apple)

This setup gives you a secure, reproducible NixOS configuration with properly encrypted secrets, declaratively managed SSH keys, and a robust bootstrap mechanism using RBW for Bitwarden integration.
