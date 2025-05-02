{ inputs, lib, config, pkgs, ... }: {
  imports = [
    inputs.nvf.homeManagerModules.default
    # inputs.nix-colors.homeManagerModule
  ];

  nixpkgs = {
    config = {
      allowUnfree = true;
      allowUnfreePredicate = _: true;
    };
  };

  home = {
    username = "tim";
    homeDirectory = "/home/tim";
  };

  programs = {
    home-manager.enable = true;
    git = {
      enable = true;
      userName = "Tim Black";
      userEmail = "timblaktu@gmail.com";
    };
  
    nvf = {
      enable = true;
      settings = {
        vim.viAlias = false;
        vim.vimAlias = true;
        vim.lsp = {
          enable = true;
        };
      };
    };
    
    tmux.enable = true;
    tmux.baseIndex = 0;
    tmux.clock24 = true;
    tmux.historyLimit = 99999;
    tmux.newSession = true;
    tmux.keyMode = "vi";
    tmux.customPaneNavigationAndResize = true;
    tmux.extraConfig = ''
      set-option -g prefix C-a
      unbind C-b
      bind C-a send-prefix
      set-option -sg escape-time 1
      set-option -g renumber-windows on
      set-option -g history-limit 100000
      set-option -g bell-action any
      set-option -g visual-bell off
      set-option -g mouse on      # sometimes more convenient for resizing panes
      set-option -g base-index 1  # start window numbering at 1
      set-option -gw pane-base-index 1
      set-option -gw allow-rename on
      set-option -gw automatic-rename on
      set-option -g set-titles on
      bind S set-option -w synchronize-panes
      bind r source ~/.tmux.conf
      bind | split-window -h
      bind - split-window -v
      bind l last-window
      bind m set-option -w monitor-activity

      bind-key -r j resize-pane -D #  5
      bind-key -r k resize-pane -U #  5
      bind-key -r h resize-pane -L #  5
      bind-key -r l resize-pane -R #  5

      setw -g aggressive-resize on
      #bind-key -n M-Left previous-window
      bind-key -n M-h previous-window # alt+h ==> previous window
      #bind-key -n M-Right next-window
      bind-key -n M-l next-window # alt+l ==> next window

      bind-key -T copy-mode-vi 'C-h' select-pane -L
      bind-key -T copy-mode-vi 'C-j' select-pane -D
      bind-key -T copy-mode-vi 'C-k' select-pane -U
      bind-key -T copy-mode-vi 'C-l' select-pane -R
      bind-key -T copy-mode-vi 'C-\' select-pane -l

      # PLUGINS
      set -g @plugin 'tmux-plugins/tpm'
      set -g @plugin 'tmux-plugins/tmux-resurrect'
      set -g @resurrect-strategy-vim 'session'

      # Initialize TMUX plugin manager (keep this line at the very bottom of tmux.conf)
      run '~/.tmux/plugins/tpm/tpm'
  '';
  };

  home.packages = with pkgs; [ 
    buildah
    curl
    dive
    gettext
    git
    htop
    pinentry-tty
    podman-compose
    podman-tui
    rbw
    step-ca
    step-cli
    tree
    wget
  ];

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  home.stateVersion = "24.11";
}
