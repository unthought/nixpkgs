{ config, lib, pkgs, ... }:

let
  inherit (lib) elem optionalString;
  inherit (config.home.user-info) nixConfigDirectory;
in
{
  # Tmux
  # https://rycee.gitlab.io/home-manager/options.html#opt-programs.tmux.enable
  programs.tmux.enable = true;

  #programs.tmux.enableSensible = true;

  #programs.tmux.enableFzf = true;

  #programs.tmux.enableVim = true;

  programs.tmux.extraConfig = ''
  set -g status off
  set -g base-index 1
  set -g pane-base-index 1

  set -g default-terminal "screen-256color"

  setw -g  monitor-activity   on
  set  -g  visual-activity    on

  set -g prefix C-Space
  unbind C-b
  bind     Z       send-prefix

  # I almost never use more than two tmux panes (vim has buffer next to
  # each other itself).
  bind     i       select-layout even-horizontal
  bind     C-i     select-layout even-horizontal
  bind     e       select-layout main-horizontal
  bind     C-e     select-layout main-horizontal
  bind     I       display-message

  bind     C-Space last-window
  #bind     Space   last-pane
  bind     Space   resize-pane -Z
  bind     C-w     last-pane

  bind     R       source-file ~/.tmux.conf
  bind     C       new-session
  bind     C-s     switch-client -l
  bind     s       choose-tree -s
  #bind     S       choose-tree -b "kill-session -t '%%'"
  bind     C-[     copy-mode \; send "?"
  bind     M-[     'capture-pane' \; capture-pane -S - \; save-buffer ~/.tmux-buffer \; delete-buffer
  bind     y       run "tmux saveb - | pbcopy"
  bind     Y       set synchronize-panes

  '';
}
