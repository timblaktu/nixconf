{ inputs, lib, config, pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
    };
  };

  nix = let
    flakeInputs = lib.filterAttrs (_: lib.isType "flake") inputs;
  in {
    settings = {
      experimental-features = "nix-command flakes";
      flake-registry = "";
      nix-path = config.nix.nixPath;
    };
    # Opinionated: disable channels
    # channel.enable = false;
    # Opinionated: make flake registry and nix path match flake inputs
    # registry = lib.mapAttrs (_: flake: {inherit flake;}) flakeInputs;
    # nixPath = lib.mapAttrsToList (n: _: "${n}=flake:${n}") flakeInputs;
  };

  networking = {
    hostName = "mbp";
    useNetworkd= true;
    firewall.enable = false;
  };

  systemd.network.enable = true;
  
  time.timeZone = "US/Pacific";
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    #earlySetup = true;
    packages = [ pkgs.kbd pkgs.terminus_font pkgs.powerline-fonts ];
    #font = "${pkgs.terminus_font}/share/consolefonts/ter-v32n.psf.gz";
    font = "${pkgs.powerline-fonts}/share/consolefonts/ter-powerline-v20b.psf.gz";
    keyMap = "us";
    colors = [
    "002b36" # base03, background
    "dc322f" # red
    "859900" # green
    "b58900" # yellow
    "268bd2" # blue
    "d33682" # magenta
    "2aa198" # cyan
    "eee8d5" # base2, foreground
    "073642" # base02, bright background
    "cb4b16" # bright red
    "586e75" # base01, bright green
    "657b83" # base00, bright yellow
    "839496" # base0, bright blue
    "6c71c4" # violet, bright magenta
    "93a1a1" # base1, bright cyan
    "fdf6e3" # base3, bright foreground
  ];
    # colors = [
    #   "002635"
    #   "00384d"
    #   "517F8D"
    #   "6C8B91"
    #   "869696"
    #   "a1a19a"
    #   "e6e6dc"
    #   "fafaf8"
    #   "ff5a67"
    #   "f08e48"
    #   "ffcc1b"
    #   "7fc06e"
    #   "14747e"
    #   "5dd7b9"
    #   "9a70a4"
    #   "c43060"
    # ];
  };

  users = {
    mutableUsers = true;
      groups.tim.name = "tim";
      groups.tim.gid = 1000;
      groups.tim.members = [ "tim" ];
      users.tim = {
        isNormalUser = true;
        shell = pkgs.zsh;
        group = "tim";
        initialHashedPassword = "";
        extraGroups = [ "users" "wheel" "podman" ];
        autoSubUidGidRange = true;
        # was playing with uid/gid for rootless podman...
        # subUidRanges = [{ startUid = 100000; count = 65536; }];
        # subGidRanges = [{ startGid = 100000; count = 65536; }];
        openssh.authorizedKeys.keys = [
        ];
        packages = with pkgs; [
          inputs.home-manager.packages.${pkgs.system}.default
        ];
    };
  };
  
  security.sudo.wheelNeedsPassword = false;

  programs.gnupg.agent.enable = true;
  programs.gnupg.agent.enableSSHSupport = true;
  
  programs.zsh.enable = true;
  programs.zsh.syntaxHighlighting.enable = true;
  programs.zsh.enableCompletion = true;
  programs.zsh.enableBashCompletion = true;
  programs.zsh.enableGlobalCompInit = true;
  programs.zsh.enableLsColors = true;
  programs.zsh.setOptions = [
    "EXTENDED_HISTORY"
    "HIST_IGNORE_DUPS"
    "SHARE_HISTORY"
    "HIST_FCNTL_LOCK"
  ];
  programs.zsh.interactiveShellInit = ''
    bindkey -v
    bindkey '^R' history-incremental-search-backward
'';
  programs.zsh.promptInit = ''
    # Note that to manually override this in ~/.zshrc you should run `prompt off`
    # before setting your PS1 and etc. Otherwise this will likely to interact with
    # your ~/.zshrc configuration in unexpected ways as the default prompt sets
    # a lot of different prompt variables.
    autoload -U promptinit
    promptinit
    prompt suse
    setopt prompt_sp
    setopt prompt_subst
    autoload -Uz vcs_info
    precmd () { vcs_info } # always load vcs info before displaying the prompt
    zstyle ':vcs_info:*' formats ' %s(%F{red}%b%f)' # git(main)
    PS1='%n@%m %F{red}%/%f$vcs_info_msg_0_ $ '
  '';
  programs.zsh.histSize = 10000;
  
  environment = {
    systemPackages = with pkgs; [ 
      kbd
      terminus_font
      powerline-fonts
    ];
    variables = {
      EDITOR = "neovim";
    };
    # extraInit = ''
    #     # point docker tools to podman sock on user login
    #     if [ -z "$DOCKER_HOST" -a -n "$XDG_RUNTIME_DIR" ]; then
    #     export DOCKER_HOST="unix://$XDG_RUNTIME_DIR/podman/podman.sock"
    #     fi
    # '';
  };

  # virtualisation = {
  #   libvirtd.enable = true;
  #   containers.enable = true;
  #   containers.storage.settings = {
  #     # Rootless Podman:
  #     #   - https://nixos.wiki/wiki/Podman
  #     #   - https://carjorvaz.com/posts/rootless-podman-and-docker-compose-on-nixos/
  #     #   - https://github.com/containers/storage/blob/main/docs/containers-storage.conf.5.md#storage-table
  #     storage = {
  #       driver = "overlay";
  #       runroot = "/run/containers/storage";
  #       graphroot = "/var/lib/containers/storage";
  #       rootless_storage_path = "/tmp/containers-$USER";
  #       options.overlay.mountopt = "nodev,metacopy=on";
  #       # options.overlay.mountopt = "nodev,index=off";
  #       options.overlay.ignore_chown_errors = "true";
  #     };
  #   };
  #   oci-containers.backend = "podman";
  #   podman = {
  #     enable = true;
  #     # enableNvidia = true;  # deprecated, moved to ..
  #     dockerCompat = true;
  #     # extraPackages = [ pkgs.zfs ]; # Required if the host is running ZFS
  #     # Mine:
  #     autoPrune.enable = true;
  #     defaultNetwork.settings.dns_enabled = true;
  #     # dockerSocket.enable = true;
  #   };
  #   # Containerized Services
  #   # oci-containers.containers."gitea" = {
  #   #   autoStart = true;
  #   #   image = "gitea/gitea:latest";
  #   #   environment = {
  #   #     USER_UID = "1000";
  #   #     USER_GID = "1000";
  #   #   };
  #   #   volumes = [
  #   #     "/media/Containers/Gitea:/data"
  #   #     "/etc/timezone:/etc/timezone:ro"
  #   #     "/etc/localtime:/etc/localtime:ro"
  #   #   ];
  #   #   ports = [
  #   #     "3000:3000"
  #   #     "222:22"
  #   #   ];
  #   # };
  # };
  
  services = {
    openssh = {
        enable = true;
        settings = {
        PermitRootLogin = "no";
        PasswordAuthentication = true;
        };
    };
    xserver.enable = false;
    printing.enable = false;
    pipewire = {
        enable = false;
        pulse.enable = false;
    };
    # Enable touchpad support (enabled default in most desktopManager).
    libinput.enable = true;
  };

  system = {
    stateVersion = "24.11";
  };
}
