{ config, lib, pkgs, ... }:

{
  editorconfig = {
    enable = true;
    settings = {
      "*" = {
        charset = "utf-8";
        end_of_line = "lf";
        trim_trailing_whitespace = true;
        insert_final_newline = true;
        #max_line_width = 78;
        indent_style = "space";
        #indent_size = 2;
      };
    };
  };

  # Bat, a substitute for cat.
  # https://github.com/sharkdp/bat
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.bat.enable
  programs.bat.enable = true;
  programs.bat.config = {
    style = "plain";
  };

  # Direnv, load and unload environment variables depending on the current directory.
  # https://direnv.net
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.direnv.enable
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

  # Htop
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.htop.enable
  programs.htop.enable = true;
  programs.htop.settings.show_program_path = true;

  # Zoxide, a faster way to navigate the filesystem
  # https://github.com/ajeetdsouza/zoxide
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.zoxide.enable
  programs.zoxide.enable = true;

  programs.neomutt.enable = true;
  programs.fzf.enable = true;

  programs.tmux.enable = true;

  programs.taskwarrior.enable = true;

  programs.nushell.enable = true;

  home.packages = with pkgs; [
    # uncategorized
    abduco # lightweight session management
    browsh # in terminal browser
    # python3Packages.shell-functools # a collection of functional programming tools for the shell
    tealdeer # rust implementation of `tldr`
    thefuck
    gnuplot
    qrencode
    cloc
    imagemagick
    grc

    helix

    # core binaries
    coreutils
    binutils # expect from system
    moreutils

    # processes
    #parallel # runs commands in parallel (clash with moreutils)
    #psutils # broken
    pstree
    bottom # fancy version of `top` with ASCII graphs
    hyperfine # benchmarking tool

    # filesystem
    tree
    du-dust # fancy version of `du`
    exa # fancy version of `ls`

    # search
    fd # fancy version of `find`
    findutils
    gnugrep
    ripgrep

    # text manipulation
    gnused
    gawk
    jq
    xmlstarlet

    # compression
    gnutar
    unrar # unfree
    unzip
    xz
    bzip2
    #p7zip # known insecure

    # downloads
    curl
    wget
    aria2

    # secure comms
    mosh # wrapper for `ssh` that better and not dropping connections
    #autossh
    #wireguard-go # expect from system
    #wireguard-tools # expect from system

    # general networking
    nmap
    #dnsmasq # autolaunch?
    prettyping
    socat
    rsync
    bandwhich # display current network utilization by process
    nodePackages.speed-test # nice speed-test tool

    # task related
    timewarrior
    taskwarrior-tui
    tasksh
    #taskjuggler
    #smos

    asdf-vm # maybe belongs into project config
    packer

    awscli2
    #aws-iam-authenticator
    amazon-ecr-credential-helper
    aws-vault
    s3cmd
    chamber
    google-cloud-sdk
    #azure-cli # 2022-09-17 disable because broken

    haskellPackages.cabal-install
    haskellPackages.hoogle
    haskellPackages.hpack
    haskellPackages.implicit-hie
    # idris2
    nodePackages.typescript
    nodejs-16_x
    stack

    # Useful nix related tools
    cachix # adding/managing alternative binary caches hosted by Cachix
    comma # run software from without installing it
    niv # easy dependency management for nix projects
    nix-tree # interactively browse dependency graphs of Nix derivations
    nix-update # swiss-knife for updating nix packages
    nixpkgs-review # review pull-requests on nixpkgs
    nodePackages.node2nix
    statix # lints and suggestions for the Nix programming language

  ] ++ lib.optionals stdenv.isDarwin [
    cocoapods
    m-cli # useful macOS CLI commands
    prefmanager # tool for working with macOS defaults
  ];
}
