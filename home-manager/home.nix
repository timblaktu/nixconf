{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: {
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
      settings.vim = {
        viAlias = true;
        vimAlias = true;
        debugMode = {
          enable = false;
          level = 16;
          logFile = "/tmp/nvim.log";
        };
        undoFile = {
          enable = true;
          path = "~/.local/share/nvim/undo";
        };
        options = {
          tabstop = 4;
          autoindent = true;
          shiftwidth = 4;
          wrap = false;
          splitbelow = true;
          splitright = true;
          cmdheight = 1;
          signcolumn = "yes";
          mouse = "a";
          searchcase = "smart";
          swapfile = false;
        };
        # keymaps = {
        # };
        spellcheck = {
          enable = true;
        };

        lsp = {
          formatOnSave = true;
          lspkind.enable = false;
          lightbulb.enable = true;
          lspsaga.enable = false;
          trouble.enable = true;
          lspSignature.enable = true;
          otter-nvim.enable = true;
          nvim-docs-view.enable = true;
        };

        debugger = {
          nvim-dap = {
            enable = true;
            ui.enable = true;
          };
        };

        # This section does not include a comprehensive list of available language modules.
        # To list all available language module options, please visit the nvf manual.
        languages = {
          enableLSP = true;
          enableFormat = true;
          enableTreesitter = true;
          enableExtraDiagnostics = true;

          # Languages that will be supported in default and maximal configurations.
          nix.enable = true;
          markdown.enable = true;

          # Languages that are enabled in the maximal configuration.
          bash.enable = true;
          clang.enable = true;
          css.enable = true;
          html.enable = true;
          sql.enable = true;
          java.enable = true;
          kotlin.enable = true;
          ts.enable = true;
          go.enable = true;
          lua.enable = true;
          zig.enable = true;
          python.enable = true;
          typst.enable = true;
          rust = {
            enable = true;
            crates.enable = true;
          };

          # Language modules that are not as common.
          assembly.enable = false;
          astro.enable = false;
          nu.enable = false;
          csharp.enable = false;
          julia.enable = false;
          vala.enable = false;
          scala.enable = false;
          r.enable = false;
          gleam.enable = false;
          dart.enable = false;
          ocaml.enable = false;
          elixir.enable = false;
          haskell.enable = false;
          ruby.enable = false;
          fsharp.enable = false;

          tailwind.enable = false;
          svelte.enable = false;

          # Nim LSP is broken on Darwin and therefore
          # should be disabled by default. Users may still enable
          # `vim.languages.vim` to enable it, this does not restrict
          # that.
          # See: <https://github.com/PMunch/nimlsp/issues/178#issue-2128106096>
          nim.enable = false;
        };

        visuals = {
          nvim-scrollbar.enable = true;
          nvim-web-devicons.enable = true;
          nvim-cursorline.enable = true;
          cinnamon-nvim.enable = true;
          fidget-nvim.enable = true;

          highlight-undo.enable = true;
          indent-blankline.enable = true;

          # Fun
          cellular-automaton.enable = false;
        };

        statusline = {
          lualine = {
            enable = true;
            theme = "catppuccin";
          };
        };

        theme = {
          enable = true;
          name = "catppuccin";
          style = "mocha";
          transparent = false;
        };

        autopairs.nvim-autopairs.enable = true;

        autocomplete.nvim-cmp.enable = true;
        snippets.luasnip.enable = true;

        filetree = {
          neo-tree = {
            enable = true;
          };
        };

        tabline = {
          nvimBufferline.enable = true;
        };

        treesitter.context.enable = true;

        binds = {
          whichKey.enable = true;
          cheatsheet.enable = true;
        };

        telescope.enable = true;

        git = {
          enable = true;
          gitsigns.enable = true;
          gitsigns.codeActions.enable = false; # throws an annoying debug message
        };

        minimap = {
          minimap-vim.enable = false;
          codewindow.enable = true; # lighter, faster, and uses lua for configuration
        };

        dashboard = {
          dashboard-nvim.enable = false;
          alpha.enable = true;
        };

        notify = {
          nvim-notify.enable = true;
        };

        projects = {
          project-nvim.enable = true;
        };

        utility = {
          ccc.enable = false;
          vim-wakatime.enable = false;
          diffview-nvim.enable = true;
          yanky-nvim.enable = false;
          icon-picker.enable = true;
          surround.enable = true;
          leetcode-nvim.enable = true;
          multicursors.enable = true;

          motion = {
            hop.enable = true;
            leap.enable = true;
            precognition.enable = true;
          };
          images = {
            image-nvim.enable = false;
          };
        };

        notes = {
          obsidian.enable = false; # FIXME: neovim fails to build if obsidian is enabled
          neorg.enable = false;
          orgmode.enable = false;
          mind-nvim.enable = true;
          todo-comments.enable = true;
        };

        terminal = {
          toggleterm = {
            enable = true;
            lazygit.enable = true;
          };
        };

        ui = {
          borders.enable = true;
          noice.enable = true;
          colorizer.enable = true;
          modes-nvim.enable = false; # the theme looks terrible with catppuccin
          illuminate.enable = true;
          breadcrumbs = {
            enable = true;
            navbuddy.enable = true;
          };
          smartcolumn = {
            enable = true;
            setupOpts.custom_colorcolumn = {
              # this is a freeform module, it's `buftype = int;` for configuring column position
              nix = "110";
              ruby = "120";
              java = "130";
              go = ["90" "130"];
            };
          };
          fastaction.enable = true;
        };

        assistant = {
          chatgpt.enable = false;
          copilot = {
            enable = false;
            cmp.enable = true;
          };
          codecompanion-nvim.enable = false;
        };

        session = {
          nvim-session-manager.enable = false;
        };

        gestures = {
          gesture-nvim.enable = false;
        };

        comments = {
          comment-nvim.enable = true;
        };

        presence = {
          neocord.enable = false;
        };
      };

      # viAlias = true;
      # vimAlias = true;
      # debugMode = {
      #   enable = false;
      #   level = 16;
      #   logFile = "/tmp/nvim.log";
      # };
      # tabWidth = 2;
      # wrap = false;
      # splitBelow = true;
      # splitRight = true;
      # scrollOffset = 8;
      # cmdHeight = 1;
      # showSignColumn = true;
      # terminalInsertBehavior = "auto";
      # mouseSupport = "a";
      # smartIndent = true;
      # smartCase = true;
      # undodir = "~/.local/share/nvim/undo";
      # undofile = true;
      # swapfile = false;
      #
      # leaderKey = ",";
      #
      # transparentBackground = false;

      # showMode = false;
      # ruler = true;
      # signcolumn = "yes";
      # smoothScroll = true;
      #
      # lsp = {
      #   enable = true;
      #   formatOnSave = true;
      #   lightbulb.enable = true;
      #   trouble.enable = true;
      #   # inlayHints.enable = true;
      #   # virtualText = true;
      #   # diagnosticsPopup = true;
      #
      #   # Enable native Neovim LSP servers
      #   servers = {
      #     rust-analyzer.enable = true;
      #     nil.enable = true;
      #     lua-ls.enable = true;
      #     pyright.enable = true;
      #     tsserver.enable = true;
      #     gopls.enable = true;
      #     bashls.enable = true;
      #   };
      # };
      #
      # # Completions
      # # cmp = {
      # #   enable = true;
      # #   cmdline.enable = true;
      # #   luasnip.enable = true;
      # #   git.enable = true;
      # # };
      #
      # # Tree-sitter for better syntax highlighting
      # treesitter = {
      #   enable = true;
      #   fold = true;
      #   incrementalSelection = {
      #     enable = true;
      #     keymaps = {
      #       initSelection = "gnn";
      #       nodeIncremental = "grn";
      #       scopeIncremental = "grc";
      #       nodeDecremental = "grm";
      #     };
      #   };
      # };
      #
      # telescope = {
      #   enable = true;
      #   extensions = {
      #     frecency.enable = true;
      #     fzf.enable = true;
      #   };
      # };
      #
      # statusLine = {
      #   enable = true;
      #   theme = "tokyonight";
      # };
      #
      # tabLine.enable = true;
      #
      # toggleterm = {
      #   enable = true;
      #   direction = "float";
      # };
      #
      # autopairs.enable = true;
      #
      # whichKey.enable = true;
      #
      # # extraKeymaps = [
      # #   # File navigation with Telescope
      # #   {
      # #     key = "<leader>ff";
      # #     action = "require('telescope.builtin').find_files";
      # #     options.desc = "Find files";
      # #     mode = "n";
      # #   }
      # #   {
      # #     key = "<leader>fg";
      # #     action = "require('telescope.builtin').live_grep";
      # #     options.desc = "Live grep";
      # #     mode = "n";
      # #   }
      # #   {
      # #     key = "<leader>fb";
      # #     action = "require('telescope.builtin').buffers";
      # #     options.desc = "Find buffers";
      # #     mode = "n";
      # #   }
      # #   {
      # #     key = "<leader>fh";
      # #     action = "require('telescope.builtin').help_tags";
      # #     options.desc = "Help tags";
      # #     mode = "n";
      # #   }
      # #
      # #   # LSP keymaps
      # #   {
      # #     key = "gd";
      # #     action = "vim.lsp.buf.definition";
      # #     options.desc = "Go to definition";
      # #     mode = "n";
      # #   }
      # #   {
      # #     key = "gr";
      # #     action = "vim.lsp.buf.references";
      # #     options.desc = "Find references";
      # #     mode = "n";
      # #   }
      # #   {
      # #     key = "K";
      # #     action = "vim.lsp.buf.hover";
      # #     options.desc = "Show hover info";
      # #     mode = "n";
      # #   }
      # #   {
      # #     key = "<leader>rn";
      # #     action = "vim.lsp.buf.rename";
      # #     options.desc = "Rename symbol";
      # #     mode = "n";
      # #   }
      # #   {
      # #     key = "<leader>ca";
      # #     action = "vim.lsp.buf.code_action";
      # #     options.desc = "Code actions";
      # #     mode = "n";
      # #   }
      # #
      # #   # Buffer navigation
      # #   {
      # #     key = "<leader>bn";
      # #     action = ":bnext<CR>";
      # #     options.desc = "Next buffer";
      # #     mode = "n";
      # #   }
      # #   {
      # #     key = "<leader>bp";
      # #     action = ":bprevious<CR>";
      # #     options.desc = "Previous buffer";
      # #     mode = "n";
      # #   }
      # #   {
      # #     key = "<leader>bd";
      # #     action = ":bdelete<CR>";
      # #     options.desc = "Delete buffer";
      # #     mode = "n";
      # #   }
      # #
      # #   # File explorer
      # #   {
      # #     key = "<leader>e";
      # #     action = ":NvimTreeToggle<CR>";
      # #     options.desc = "Toggle file explorer";
      # #     mode = "n";
      # #   }
      # #
      # #   # Terminal
      # #   {
      # #     key = "<leader>t";
      # #     action = ":ToggleTerm<CR>";
      # #     options.desc = "Toggle terminal";
      # #     mode = "n";
      # #   }
      # # ];
      #
      # # extraLuaConfig = ''
      # #   -- Custom telescope configuration
      # #   require('telescope').setup {
      # #     defaults = {
      # #       file_ignore_patterns = { "node_modules", ".git" },
      # #       layout_strategy = "horizontal",
      # #       layout_config = {
      # #         width = 0.95,
      # #         height = 0.85,
      # #       }
      # #     }
      # #   }
      # #   -- vim-surround
      # #   -- vim-repeat
      # #   -- nvim-web-devicons
      # #   require('todo-comments').setup {
      # #   }
      # # '';

      # extraPlugins = with pkgs.vimPlugins; [
      #     vim-surround
      #     vim-repeat
      #     nvim-web-devicons
      #     todo-comments-nvim
      #     markdown-preview-nvim
      #     plenary-nvim
      # ];
      #};
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

    # makemkv

    ripgrep # Fast grep replacement, used by telescope
    fd # Fast find replacement
    tree-sitter # For better syntax highlighting
    nodejs # Required by many language servers
    lua-language-server # For lua configuration
    nil # Nix Language Server
    rust-analyzer # For Rust development
    pyright # For Python
    gopls # For Go
    nodePackages.typescript-language-server # For TypeScript/JavaScript
    nodePackages.bash-language-server # For shell scripts
    fzf # Fuzzy finder used by telescope
  ];

  # Nicely reload system units when changing configs
  systemd.user.startServices = "sd-switch";

  home.stateVersion = "24.11";
}
