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
      extraConfig.credential = {
        helper = "manager";
        credentialStore = "cache";
        "https://github.com".username = "timblaktu";
      };
    };
  
    ssh = {
      matchBlocks = {
        "github.com" = {
          hostname = "github.com";
          user = "timblaktu";
          identityFile = "~/.ssh/id_ed25519";
          identitiesOnly = true;
        };
      };
    };

    nvf = {
      enable = true;
      
      # Basic Vim settings
      settings = {
        # Add aliases
        vim.viAlias = false;
        vim.vimAlias = true;
        
        # General editor configuration
        vim.lineNumbers = "relative";
        vim.tabWidth = 2;
        vim.wrap = false;
        vim.clipboard = "unnamedplus";
        vim.splitBelow = true;
        vim.splitRight = true;
        vim.scrollOffset = 8;
        vim.cmdHeight = 1;
        vim.showSignColumn = true;
        vim.terminalInsertBehavior = "auto";
        vim.mouseSupport = "a";
        vim.foldMethod = "expr";
        vim.foldExpr = "nvim_treesitter#foldexpr()";
        vim.smartIndent = true;
        vim.smartCase = true;
        vim.hlsearch = true;
        vim.incsearch = true;
        vim.grepprg = "rg --vimgrep";
        vim.undodir = "~/.local/share/nvim/undo";
        vim.undofile = true;
        vim.backup = false;
        vim.swapfile = false;
        vim.completeopt = "menu,menuone,noselect";
        vim.pumheight = 10;
        
        # Leader key
        vim.leaderKey = " ";
        
        # Theme configuration
        vim.colorscheme = "tokyonight";
        vim.transparentBackground = false;

        # Additional UI features
        vim.showMode = false;
        vim.ruler = true;
        vim.confirm = true;
        vim.signcolumn = "yes";
        vim.cursorline = true;
        vim.smoothScroll = true;
        
        # Language server protocol
        vim.lsp = {
          enable = true;
          formatOnSave = true;
          lightbulb.enable = true;
          trouble.enable = true;
          lspsaga.enable = true;
          # Enable native Neovim LSP servers
          servers = {
            rust-analyzer.enable = true;
            nil.enable = true;
            lua-ls.enable = true;
            pyright.enable = true;
            tsserver.enable = true;
            gopls.enable = true;
            bashls.enable = true;
          };
        };
        
        # Completions
        vim.cmp = {
          enable = true;
          cmdline.enable = true;
          luasnip.enable = true;
          git.enable = true;
        };
        
        # Tree-sitter for better syntax highlighting
        vim.treesitter = {
          enable = true;
          fold = true;
          incrementalSelection = {
            enable = true;
            keymaps = {
              initSelection = "gnn";
              nodeIncremental = "grn";
              scopeIncremental = "grc";
              nodeDecremental = "grm";
            };
          };
        };
        
        # File explorer - nvim-tree
        vim.nvimTree = {
          enable = true;
          openOnSetup = true;
          hideFiles = [ "node_modules" ".git" ];
        };
        
        # Telescope for fuzzy finding
        vim.telescope = {
          enable = true;
          extensions = {
            frecency.enable = true;
            fzf.enable = true;
          };
        };
        
        # Git integration
        vim.gitsigns.enable = true;
        
        # Status line - lualine
        vim.statusLine = {
          enable = true;
          theme = "tokyonight";
        };
        
        # Tab line - bufferline
        vim.tabLine.enable = true;
        
        # Terminal integration
        vim.toggleterm = {
          enable = true;
          direction = "float";
        };
        
        # Auto-pairs for brackets, quotes, etc.
        vim.autopairs.enable = true;
        
        # Comments
        vim.comment = {
          enable = true;
          useTreesitter = true;
        };
        
        # Indentation guides
        vim.indentBlankline = {
          enable = true;
          showCurrContext = true;
        };
        
        # Which-key for key binding help
        vim.whichKey.enable = true;
        
        # Autoformatting
        vim.conform = {
          enable = true;
          formatOnSave = true;
        };
        
        # # Dashboard/start screen
        # vim.alpha = {
        #   enable = true;
        #   theme = "dashboard";
        # };
        
        # Custom keymaps (telescope, lsp, navigation)
        vim.extraKeymaps = [
          # File navigation with Telescope
          {
            key = "<leader>ff";
            action = "require('telescope.builtin').find_files";
            options.desc = "Find files";
            mode = "n";
          }
          {
            key = "<leader>fg";
            action = "require('telescope.builtin').live_grep";
            options.desc = "Live grep";
            mode = "n";
          }
          {
            key = "<leader>fb";
            action = "require('telescope.builtin').buffers";
            options.desc = "Find buffers";
            mode = "n";
          }
          {
            key = "<leader>fh";
            action = "require('telescope.builtin').help_tags";
            options.desc = "Help tags";
            mode = "n";
          }
          
          # LSP keymaps
          {
            key = "gd";
            action = "vim.lsp.buf.definition";
            options.desc = "Go to definition";
            mode = "n";
          }
          {
            key = "gr";
            action = "vim.lsp.buf.references";
            options.desc = "Find references";
            mode = "n";
          }
          {
            key = "K";
            action = "vim.lsp.buf.hover";
            options.desc = "Show hover info";
            mode = "n";
          }
          {
            key = "<leader>rn";
            action = "vim.lsp.buf.rename";
            options.desc = "Rename symbol";
            mode = "n";
          }
          {
            key = "<leader>ca";
            action = "vim.lsp.buf.code_action";
            options.desc = "Code actions";
            mode = "n";
          }
          
          # Buffer navigation
          {
            key = "<leader>bn";
            action = ":bnext<CR>";
            options.desc = "Next buffer";
            mode = "n";
          }
          {
            key = "<leader>bp";
            action = ":bprevious<CR>";
            options.desc = "Previous buffer";
            mode = "n";
          }
          {
            key = "<leader>bd";
            action = ":bdelete<CR>";
            options.desc = "Delete buffer";
            mode = "n";
          }
          
          # File explorer
          {
            key = "<leader>e";
            action = ":NvimTreeToggle<CR>";
            options.desc = "Toggle file explorer";
            mode = "n";
          }
          
          # Terminal
          {
            key = "<leader>t";
            action = ":ToggleTerm<CR>";
            options.desc = "Toggle terminal";
            mode = "n";
          }
        ];
        
        # Extra Lua configuration for advanced customization
        vim.extraLuaConfig = ''
          -- Custom telescope configuration
          require('telescope').setup {
            defaults = {
              file_ignore_patterns = { "node_modules", ".git" },
              layout_strategy = "horizontal",
              layout_config = {
                width = 0.95,
                height = 0.85,
              }
            }
          }
          -- vim-surround
          -- vim-repeat
          -- nvim-web-devicons
          require('todo-comments').setup {
          }
        '';
      
        # Additional plugins not included in the standard nvf configuration
        vim.extraPlugins = [
            "vim-surround"
            "vim-repeat"
            "nvim-web-devicons"
            "todo-comments-nvim"
            "markdown-preview-nvim"
        ];
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
    git-credential-manager
    htop
    pinentry-tty
    podman-compose
    podman-tui
    rbw
    step-ca
    step-cli
    tree
    wget

    ripgrep             # Fast grep replacement, used by telescope
    fd                  # Fast find replacement
    tree-sitter         # For better syntax highlighting
    nodejs              # Required by many language servers
    lua-language-server # For lua configuration
    nil                 # Nix Language Server
    rust-analyzer       # For Rust development
    pyright             # For Python
    gopls               # For Go
    nodePackages.typescript-language-server # For TypeScript/JavaScript
    nodePackages.bash-language-server       # For shell scripts
    fzf                 # Fuzzy finder used by telescope
  ];

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  home.stateVersion = "24.11";
}
