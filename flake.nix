{
  description = "Dan’s Nix system configs, and some other useful stuff.";

  inputs = {
    # Package sets
    nixpkgs-master.url = "github:NixOS/nixpkgs/master";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixpkgs-22.05-darwin";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixos-stable.url = "github:NixOS/nixpkgs/nixos-22.05";

    # Environment/system management
    darwin.url = "github:LnL7/nix-darwin";
    darwin.inputs.nixpkgs.follows = "nixpkgs-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.utils.follows = "flake-utils";

    # Other sources
    flake-compat = { url = "github:edolstra/flake-compat"; flake = false; };
    flake-utils.url = "github:numtide/flake-utils";
    prefmanager.url = "github:malob/prefmanager";
    prefmanager.inputs.nixpkgs.follows = "nixpkgs-unstable";
    prefmanager.inputs.flake-compat.follows = "flake-compat";
    prefmanager.inputs.flake-utils.follows = "flake-utils";
  };

  outputs = { self, darwin, home-manager, flake-utils, ... }@inputs:
    let
      # Some building blocks ------------------------------------------------------------------- {{{

      inherit (darwin.lib) darwinSystem;
      inherit (inputs.nixpkgs-unstable.lib) attrValues makeOverridable optionalAttrs singleton;

      # Configuration for `nixpkgs`
      nixpkgsConfig = {
        config = {
          allowUnfree = true;
        };
        overlays = attrValues self.overlays ++ [
          # Sub in x86 version of packages that don't build on Apple Silicon yet
          (final: prev: (optionalAttrs (prev.stdenv.system == "aarch64-darwin") {
            inherit (final.pkgs-x86)
              idris2;
          }))
        ];
      };

      homeManagerStateVersion = "22.11";

      primaryUserInfo = {
        username = "unthought";
        fullName = "Dan Mueller";
        email = "dan@unthought.org";
        nixConfigDirectory = "/Users/unthought/.config/nixpkgs";
      };

      # Modules shared by most `nix-darwin` personal configurations.
      nixDarwinCommonModules = attrValues self.darwinModules ++ [
        # `home-manager` module
        home-manager.darwinModules.home-manager
        (
          { config, ... }:
          let
            inherit (config.users) primaryUser;
          in
          {
            nixpkgs = nixpkgsConfig;
            # Hack to support legacy worklows that use `<nixpkgs>` etc.
            # nix.nixPath = { nixpkgs = "${primaryUser.nixConfigDirectory}/nixpkgs.nix"; };
            nix.nixPath = { nixpkgs = "${inputs.nixpkgs-unstable}"; };
            # `home-manager` config
            users.users.${primaryUser.username}.home = "/Users/${primaryUser.username}";
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.${primaryUser.username} = {
              imports = attrValues self.homeManagerModules;
              home.stateVersion = homeManagerStateVersion;
              home.user-info = config.users.primaryUser;
            };
            # Add a registry entry for this flake
            nix.registry.my.flake = self;
          }
        )
      ];
      # }}}
    in
    {

      # System outputs ------------------------------------------------------------------------- {{{

      # My `nix-darwin` configs
      darwinConfigurations = rec {
        # Mininal configurations to bootstrap systems
        bootstrap-x86 = makeOverridable darwinSystem {
          system = "x86_64-darwin";
          modules = [ ./darwin/bootstrap.nix { nixpkgs = nixpkgsConfig; } ];
        };
        bootstrap-arm = bootstrap-x86.override { system = "aarch64-darwin"; };

        # My Apple Silicon macOS laptop config
        sunray = darwinSystem {
          system = "aarch64-darwin";
          modules = nixDarwinCommonModules ++ [
            {
              users.primaryUser = primaryUserInfo;
              networking.computerName = "Sunray";
              networking.hostName = "sunray";
              networking.knownNetworkServices = [
                "Wi-Fi"
                "iPhone USB"
                "Thunderbolt Bridge"
                "Tailscale Tunnel"
                "Barracuda VPN"
                #"USB 10/100/1000 LAN"
              ];
            }
          ];
        };

        # Config with small modifications needed/desired for CI with GitHub workflow
        githubCI = darwinSystem {
          system = "x86_64-darwin";
          modules = nixDarwinCommonModules ++ [
            ({ lib, ... }: {
              users.primaryUser = primaryUserInfo // {
                username = "runner";
                nixConfigDirectory = "/Users/runner/work/nixpkgs/nixpkgs";
              };
              homebrew.enable = lib.mkForce false;
            })
          ];
        };
      };

      # Config I use with Linux cloud VMs
      # Build and activate on new system with:
      # `nix build .#homeConfigurations.unthought.activationPackage; ./result/activate`
      homeConfigurations.unthought = home-manager.lib.homeManagerConfiguration {
        pkgs = import inputs.nixpkgs-unstable {
          system = "x86_64-linux";
          inherit (nixpkgsConfig) config overlays;
        };
        modules = attrValues self.homeManagerModules ++ singleton ({ config, ...}: {
          home.username = config.home.user-info.username;
          home.homeDirectory = "/home/${config.home.username}";
          home.stateVersion = homeManagerStateVersion;
          home.user-info = primaryUserInfo // {
            nixConfigDirectory = "${config.home.homeDirectory}/.config/nixpkgs";
          };
        });
      };
      # }}}

      # Non-system outputs --------------------------------------------------------------------- {{{

      overlays = {
        # Overlays to add different versions `nixpkgs` into package set
        pkgs-master = _: prev: {
          pkgs-master = import inputs.nixpkgs-master {
            inherit (prev.stdenv) system;
            inherit (nixpkgsConfig) config;
          };
        };
        pkgs-stable = _: prev: {
          pkgs-stable = import inputs.nixpkgs-stable {
            inherit (prev.stdenv) system;
            inherit (nixpkgsConfig) config;
          };
        };
        pkgs-unstable = _: prev: {
          pkgs-unstable = import inputs.nixpkgs-unstable {
            inherit (prev.stdenv) system;
            inherit (nixpkgsConfig) config;
          };
        };

        prefmanager = _: prev: {
          prefmanager = inputs.prefmanager.packages.${prev.stdenv.system}.default;
        };

        # Overlay that adds various additional utility functions to `vimUtils`
        vimUtils = import ./overlays/vimUtils.nix;

        # Overlay that adds some additional Neovim plugins
        vimPlugins = final: prev:
          let
            inherit (self.overlays.vimUtils final prev) vimUtils;
          in
          {
            vimPlugins = prev.vimPlugins.extend (_: _:
              vimUtils.buildVimPluginsFromFlakeInputs inputs [
                # Add flake input name here
              ]
            );
          };

        # Overlay useful on Macs with Apple Silicon
        apple-silicon = _: prev: optionalAttrs (prev.stdenv.system == "aarch64-darwin") {
          # Add access to x86 packages system is running Apple Silicon
          pkgs-x86 = import inputs.nixpkgs-unstable {
            system = "x86_64-darwin";
            inherit (nixpkgsConfig) config;
          };
        };

        # Overlay to include node packages listed in `./pkgs/node-packages/package.json`
        # Run `nix run my#nodePackages.node2nix -- -14` to update packages.
        nodePackages = _: prev: {
          nodePackages = prev.nodePackages // import ./pkgs/node-packages { pkgs = prev; };
        };
      };

      darwinModules = {
        # My configurations
        unthought-bootstrap = import ./darwin/bootstrap.nix;
        unthought-defaults = import ./darwin/defaults.nix;
        unthought-general = import ./darwin/general.nix;
        unthought-homebrew = import ./darwin/homebrew.nix;
        unthought-yabai = import ./darwin/yabai.nix;

        # Modules I've created
        programs-nix-index = import ./modules/darwin/programs/nix-index.nix;
        users-primaryUser = import ./modules/darwin/users.nix;
      };

      homeManagerModules = {
        # My configurations
        unthought-colors = import ./home/colors.nix;
        unthought-config-files = import ./home/config-files.nix;
        unthought-fish = import ./home/fish.nix;
        unthought-zsh = import ./home/zsh.nix;
        unthought-git = import ./home/git.nix;
        unthought-git-aliases = import ./home/git-aliases.nix;
        unthought-gh-aliases = import ./home/gh-aliases.nix;
        unthought-kitty = import ./home/kitty.nix;
        unthought-neovim = import ./home/neovim.nix;
        unthought-packages = import ./home/packages.nix;
        unthought-starship = import ./home/starship.nix;
        unthought-starship-symbols = import ./home/starship-symbols.nix;
        unthought-tmux = import ./home/tmux.nix;

        # Modules I've created
        colors = import ./modules/home/colors;
        programs-neovim-extras = import ./modules/home/programs/neovim/extras.nix;
        programs-kitty-extras = import ./modules/home/programs/kitty/extras.nix;
        home-user-info = { lib, ... }: {
          options.home.user-info =
            (self.darwinModules.users-primaryUser { inherit lib; }).options.users.primaryUser;
        };
      };
      # }}}

      # Add re-export `nixpkgs` packages with overlays.
      # This is handy in combination with `nix registry add my /Users/unthought/.config/nixpkgs`
    } // flake-utils.lib.eachDefaultSystem (system: {
      legacyPackages = import inputs.nixpkgs-unstable {
        inherit system;
        inherit (nixpkgsConfig) config;
        overlays = with self.overlays; [
          pkgs-master
          pkgs-stable
          apple-silicon
          nodePackages
        ];
      };
    });
}
# vim: foldmethod=marker
