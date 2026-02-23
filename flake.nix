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
            pkgs.nixfmt-rfc-style
            pkgs.python3
            pkgs.mkalias
          ];


          homebrew = {
            enable = true;
            taps = [
              "nikitabobko/tap"
            ];
            brews = [
              "angular-cli"
              "just"
              "neovim"
              "node"
              "python@3.12"
              "mas"
            ];
            casks = [
              "aerospace"
              "asana"
              "postman"
              "cursor"
              "cursor-cli"
              "notion-calendar"
              "notion"
              "google-chrome"
              "jordanbaird-ice@beta"
              "dotnet-sdk@8"
              "zoom"
              "spotify"
              "spotmenu"
              "pgadmin4"
              "font-maple-mono-nf"
              "font-opendyslexic"
              "logitech-options"
              "ngrok"
              "obs"
              "powershell"
              "vlc"
              "jetbrains-toolbox"
              "betterdisplay"
            ];
            masApps = {
              "Word" = 462054704;
              "Excel" = 462058435;
              "Whatsapp-messanger" = 310633997;
              "Slack-desktop" = 803453959;
            };
            onActivation.cleanup = "none";
            onActivation.autoUpdate = true;
            onActivation.upgrade = true;
            global.brewfile = true;
            global.lockfiles = false;
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
          system.activationScripts.aerospaceConfig.text = ''
            # Set up Aerospace configuration file
            echo "setting up Aerospace config..." >&2
            USER_HOME=$(dscl . -read /Users/${config.system.primaryUser} NFSHomeDirectory | awk '{print $2}')
            mkdir -p "$USER_HOME/.config/aerospace"
            if [ -f "$USER_HOME/.aerospace.toml" ] && [ ! -L "$USER_HOME/.aerospace.toml" ]; then
              echo "backing up existing ~/.aerospace.toml..." >&2
              mv "$USER_HOME/.aerospace.toml" "$USER_HOME/.aerospace.toml.backup"
            fi
            ln -sfn ${./aerospace.toml} "$USER_HOME/.aerospace.toml"
            ln -sfn ${./aerospace.toml} "$USER_HOME/.config/aerospace/aerospace.toml"
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

              autohide = true;
              persistent-apps = [
                "System/Applications/Apps.app"
                "/System/Cryptexes/App/System/Applications/Safari.app"
                "/Applications/Google Chrome.app"
                "/System/Applications/Mail.app"
                "/Applications/Notion Calendar.app"
                "/Applications/Obsidian.app"
                "/Applications/Asana.app"
                "/Applications/Slack.app"
                "/Users/ayak/Applications/Rider.app"
                "/Applications/Cursor.app"
                "/Applications/Spotify.app"
                "/System/Applications/Utilities/Terminal.app"
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
            spaces.spans-displays = false; # Must be false for tiling window managers to work properly

          };

          nix.enable = false;
          nixpkgs.config = {
            allowUnfree = true;
          };
          services = {

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
              # enableRosetta = true;

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
              # Set to true to allow external taps like koekeishiya/formulae
              mutableTaps = true;
            };
          }
        ];
      };
    };
}
