{ config, lib, ... }:

let
  inherit (lib) mkIf;
  mkIfCaskPresent = cask: mkIf (lib.any (x: x.name == cask) config.homebrew.casks);
  brewEnabled = config.homebrew.enable;
in

{
  environment.shellInit = mkIf brewEnabled ''
    eval "$(${config.homebrew.brewPrefix}/brew shellenv)"
  '';

  # https://docs.brew.sh/Shell-Completion#configuring-completions-in-fish
  # For some reason if the Fish completions are added at the end of `fish_complete_path` they don't
  # seem to work, but they do work if added at the start.
  programs.fish.interactiveShellInit = mkIf brewEnabled ''
    if test -d (brew --prefix)"/share/fish/completions"
      set -p fish_complete_path (brew --prefix)/share/fish/completions
    end

    if test -d (brew --prefix)"/share/fish/vendor_completions.d"
      set -p fish_complete_path (brew --prefix)/share/fish/vendor_completions.d
    end
  '';

  homebrew.enable = true;
  homebrew.onActivation.cleanup = "zap";
  homebrew.global.brewfile = true;

  homebrew.taps = [
    "homebrew/cask"
    "homebrew/cask-drivers"
    "homebrew/cask-fonts"
    "homebrew/cask-versions"
    "homebrew/core"
    "homebrew/services"
    "nrlquaker/createzap"
  ];

  # Prefer installing application from the Mac App Store
  #
  # Commented apps suffer continual update issue:
  # https://github.com/malob/nixpkgs/issues/9
  homebrew.masApps = {
    # "1Blocker" = 1365531024;
    # "1Password" = 1333542190;
    "1Password for Safari" = 1569813296;
    #unthought "Accelerate for Safari" = 1459809092;
    # "Apple Configurator 2" = 1037126344;
    #unthought DaisyDisk = 411643860;
    #unthought "Dark Mode for Safari" = 1397180934;
    #unthought Deliveries = 290986013;
    #unthought Fantastical = 975937182;
    # "Gemini 2" = 1090488118;
    # "iMazing Profile Editor" = 1487860882;
    Keynote = 409183694;
    # MindNode = 1289197285;
    Numbers = 409203825;
    Pages = 409201541;
    #unthought Patterns = 429449079;
    # "Pixelmator Classic" = 407963104;
    #unthought "Pixelmator Pro" = 1289583905;
    #unthought "Save to Raindrop.io" = 1549370672;
    Slack = 803453959;
    # SiteSucker = 442168834;
    #unthought "Things 3" = 904280696;
    # TripMode = 1513400665;
    # Ulysses = 1225570693;
    #unthought Vimari = 1480933944;
    #unthought "WiFi Explorer" = 494803304;
    # TODO: Re-enable once macOS Ventura officially launches
    # Xcode = 497799835;
    #unthought "Yubico Authenticator" = 1497506650;
  };

  # If an app isn't available in the Mac App Store, or the version in the App Store has
  # limitiations, e.g., Transmit, install the Homebrew Cask.
  homebrew.casks = [
    #"1password"
    "1password-cli"
    "amethyst"
    "anki"
    "arq"
    "balenaetcher"
    "blender"
    #"cleanmymac"
    "element"
    "etrecheckpro"
    "discord"
    "docker"
    #"firefox"
    "github"
    "google-chrome"
    "google-drive"
    "gpg-suite"
    "hammerspoon"
    "keybase"
    "nvidia-geforce-now"
    "obsbot-me-tool"
    "obsbot-tinycam"
    "obsidian"
    "parallels"
    "postman"
    "protonvpn"
    "qutebrowser"
    "raindropio"
    "raycast"
    "secretive"
    "signal"
    "skype"
    #"steam"
    "superhuman"
    "tor-browser"
    "transmission"
    "transmit"
    "visual-studio-code"
    "vlc"
    #"yubico-yubikey-manager"
    #"yubico-yubikey-personalization-gui"
  ];

  # Configuration related to casks
  environment.variables.SSH_AUTH_SOCK = mkIfCaskPresent "1password-cli"
    "/Users/${config.users.primaryUser.username}/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock";

  # For cli packages that aren't currently available for macOS in `nixpkgs`.Packages should be
  # installed in `../home/default.nix` whenever possible.
  homebrew.brews = [
    "swift-format"
    "swiftlint"
  ];
}
