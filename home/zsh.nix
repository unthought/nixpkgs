
{ config, lib, pkgs, ... }:

let
  inherit (lib) elem optionalString;
  inherit (config.home.user-info) nixConfigDirectory;
in

{
  # Zsh Shell
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.zsh.enable
  programs.zsh.enable = true;

  programs.zsh = {
    history = {
      size = 10000;
      path = "${config.xdg.dataHome}/zsh/history";
    };

    oh-my-zsh = {
      enable = true;
      #plugins = [ "git" "thefuck" ];
      plugins = [ "gitfast" "git" "git-extras" "direnv" "macos" ];
      #theme = "robbyrussell";
      #theme = "powerlevel10k";
    };
  };

  # Aliases
  programs.fish.shellAliases = with pkgs; {
    # Other
    ".." = "cd ..";
    ":q" = "exit";
    cat = "${bat}/bin/bat";
    du = "${du-dust}/bin/dust";
    e = "$EDITOR";
    g = "${gitAndTools.git}/bin/git";
    la = "ll -a";
    ll = "ls -l --time-style long-iso --icons";
    ls = "${exa}/bin/exa";
    l = "${exa}/bin/exa";
    tb = "toggle-background";
  };
}
