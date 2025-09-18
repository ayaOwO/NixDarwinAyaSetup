{
  description = "Example nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.05-darwin";
    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.05";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli/nix-homebrew";
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };

  };
  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
      nix-homebrew,
      homebrew-cask,
      homebrew-core,
    }:
    let
      configuration =
        { pkgs, config, ... }:
        let
          # Import nixpkgs for x86_64 to get x64 .NET SDK
          pkgs-x64 = import nixpkgs {
            system = "x86_64-darwin";
            config.allowUnfree = true;
          };
        in
        {
          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = [
            pkgs.neovim
            pkgs.yabai
            pkgs.nixfmt-rfc-style
            pkgs.ngrok
            pkgs.nodejs
            pkgs.python3
            pkgs.skhd
            pkgs.jetbrains-toolbox
            pkgs.betterdisplay
            pkgs.vscode
            pkgs.windsurf
            pkgs.notion-app
            pkgs.code-cursor
            pkgs.mkalias
            pkgs.alacritty
            pkgs.dbeaver-bin
          ];

          fonts.packages = [
            pkgs.maple-mono.NF-unhinted

          ];

          homebrew = {
            enable = true;
            brews = [
              "angular-cli"
            ];
            
            casks = [
              "postman"
              "cursor-cli"
              "notion-calendar"
              "google-chrome"
              "dotnet-sdk@8"
              "zoom"
              "spotify"
            ];

            masApps = {
              "Word" = 462054704;
              "Excel" = 462058435;
              "Whatsapp-messanger" = 310633997;
              "Slack-desktop" = 803453959;
            };
            onActivation.cleanup = "zap";
            onActivation.autoUpdate = true;
            onActivation.upgrade = true;
          };
          system.primaryUser = "ayak";
          system.activationScripts.applications.text =
            let
              env = pkgs.buildEnv {
                name = "system-applications";
                paths = config.environment.systemPackages;
                pathsToLink = "/Applications";
              };
            in
            pkgs.lib.mkForce ''
              # Set up applications.
              echo "setting up /Applications..." >&2
              rm -rf /Applications/Nix\ Apps
              mkdir -p /Applications/Nix\ Apps
              find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
              while read -r src; do
                app_name=$(basename "$src")
                echo "copying $src" >&2
                ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
              done
            '';
          system.defaults = {
            finder = {
              ShowPathbar = true;
              ShowStatusBar = true;
              FXPreferredViewStyle = "clmv"; # List view
            };

            menuExtraClock = {
              ShowDate = 0; # 0 = When space allows 1 = Always 2 = Never.
              Show24Hour = true;
              ShowSeconds = false;
              ShowDayOfWeek = true;
            };
            dock = {
              wvous-tl-corner = 2; # Top-left: Mission Control
              wvous-tr-corner = 12; # Top-right: Notification Center
              wvous-bl-corner = 11; # Bottom-left: Launchpad
              wvous-br-corner = 14; # Bottom-right: Quick Note

              autohide = true;
              persistent-apps = [
                "/System/Applications/Launchpad.app"
                "/System/Cryptexes/App/System/Applications/Safari.app"
                "/System/Applications/Mail.app"
                "/Applications/Notion Calendar.app"
                "${pkgs.notion-app}/Applications/Notion.app"
                "/Applications/Slack.app"
                "${pkgs.alacritty}/Applications/Alacritty.app"
                "/Users/ayak/Applications/Rider.app"
                "${pkgs.code-cursor}/Applications/Cursor.app"
                "/Users/ayak/Applications/PyCharm.app"
                "${pkgs.vscode}/Applications/Visual Studio Code.app"
              ];
            };
            NSGlobalDomain = {
              AppleShowAllExtensions = true;
              AppleShowAllFiles = true;
              AppleICUForce24HourTime = true;
              # _HIHideMenuBar = true;
              InitialKeyRepeat = 15; # Need to verify
              KeyRepeat = 2;
              ApplePressAndHoldEnabled = false;
            };
            screencapture.location = "~/Pictures/Screenshots";
            spaces.spans-displays = false; # Must be false for yabai to work properly

          };

          nix.enable = false;
          nixpkgs.config = {
            allowUnfree = true;
          };
          services = {
            yabai.enable = true;
            yabai.config = {
              focus_follows_mouse = "autoraise";
              mouse_follows_focus = "on";
              top_padding = 20;
              bottom_padding = 20;
              right_padding = 20;
              left_padding = 20;
              window_gap = 20;
              # external_bar = "all:20:0";
              layout = "bsp";
              window_placement = "second_child";
              mouse_modifier = "alt";
              mouse_action1 = "move";
              mouse_action2 = "resize";
            };

            skhd = {
              enable = true;
              skhdConfig = builtins.readFile ./skhdrc;
            };

            # sketchybar = {
            #         enable = true;
            #         config = builtins.readFile ./sketchybarrc;
            #     };
          };

          security.pam.services.sudo_local.touchIdAuth = true;

          # Install Rosetta 2 for x64 compatibility
          system.activationScripts.rosetta.text = ''
            echo "Checking for Rosetta 2..." >&2
            if ! /usr/bin/pgrep -q oahd; then
              echo "Installing Rosetta 2..." >&2
              /usr/sbin/softwareupdate --install-rosetta --agree-to-license
            else
              echo "Rosetta 2 is already installed." >&2
            fi
          '';

          # Necessary for using flakes on this system.
          nix.settings.experimental-features = "nix-command flakes";

          # Enable alternative shell support in nix-darwin.
          # programs.fish.enable = true;

          # Set Git commit hash for darwin-version.
          system.configurationRevision = self.rev or self.dirtyRev or null;

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 6;

          # The platform the configuration will be used on.
          nixpkgs.hostPlatform = "aarch64-darwin";
        };
    in
    {
      # Build darwin flake using:
      # $ darwin-rebuild build --flake .#Ayas-MacBook-Pro
      darwinConfigurations."Ayas-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        modules = [
          configuration
          nix-homebrew.darwinModules.nix-homebrew
          {
            nix-homebrew = {
              # Install Homebrew under the default prefix
              enable = true;

              # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
              enableRosetta = true;

              # User owning the Homebrew prefix
              user = "ayak";

              # Optional: Declarative tap management
              taps = {
                "homebrew/homebrew-core" = homebrew-core;
                "homebrew/homebrew-cask" = homebrew-cask;
              };

              # Optional: Enable fully-declarative tap management
              #
              # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
              mutableTaps = false;
            };
          }
        ];
      };
    };
}
