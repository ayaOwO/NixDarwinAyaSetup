{
  description = "Aya's MacBook Pro nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-25.11-darwin";
    nix-darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nix-darwin,
      nixpkgs,
    }:
    let
      configuration =
        { pkgs, config, ... }:
        # let
        #   # Import nixpkgs for x86_64 to get x64 .NET SDK
        #   pkgs-x64 = import nixpkgs {
        #     system = "x86_64-darwin";
        #     config.allowUnfree = true;
        #   };
        # in
        {
          # List packages installed in system profile. To search by name, run:
          # $ nix-env -qaP | grep wget
          environment.systemPackages = [
            pkgs.nixfmt-rfc-style
            pkgs.python3
          ];

          system.primaryUser = "ayak";

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
              wvous-tl-corner = 1; # Top-left: Mission Control
              wvous-tr-corner = 12; # Top-right: Notification Center
              wvous-br-corner = 1; # Bottom-right: disabled
              wvous-bl-corner = 1; # Bottom-left: disabled

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
              _HIHideMenuBar = true;
              InitialKeyRepeat = 15;
              KeyRepeat = 2;
              ApplePressAndHoldEnabled = false;
            };
            screencapture.location = "~/Pictures/Screenshots";
            spaces.spans-displays = false; # Must be false for tiling window managers to work properly

          };

          nix.enable = false;
          nix.settings.experimental-features = "nix-command flakes";
          nixpkgs.config.allowUnfree = true;
          security.pam.services.sudo_local.touchIdAuth = true;

          system.configurationRevision = self.rev or self.dirtyRev or null;
          system.stateVersion = 6;
          nixpkgs.hostPlatform = "aarch64-darwin";
        };
    in
    {
      darwinConfigurations."Ayas-MacBook-Pro" = nix-darwin.lib.darwinSystem {
        modules = [ configuration ];
      };
    };
}
