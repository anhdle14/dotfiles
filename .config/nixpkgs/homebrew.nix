{ config, ... }:

{
  system.activationScripts.extraUserActivation.text =
    config.system.activationScripts.homebrew.text;

  homebrew.enable = true;
  homebrew.autoUpdate = true;
  homebrew.cleanup = "zap";

  homebrew.taps = [
    "homebrew/bundle"
    "homebrew/cask-drivers"
    "homebrew/cask-fonts"
    "homebrew/cask-versions"
    "homebrew/core"
    "homebrew/services"
    "homebrew/cask"
    "adoptopenjdk/openjdk"
    "railwaycat/emacsmacport"
  ];

  homebrew.brews = [
    "checkov"
    "pinentry-mac"
    "coreutils" # Doom Emacs could not find GNU LS
    "tfenv" # This could not be used in Nix because tfenv stored the Terraform locally
    "n" # This should be a PR to nixpkgs
  ];

  homebrew.casks = [
    "alacritty"
    "vscodium"
    "chromium"
    "firefox"
    "mos"
    "barrier"
    "railwaycat/emacsmacport/emacs-mac"
    "font-awesome-terminal-fonts"
    "font-fontawesome"
    "font-iosevka"
    "font-powerline-symbols"
    "font-source-code-pro"
    "adobe-creative-cloud"
    "aegisub"
    "anki"
    "bitwarden"
    "cheatsheet"
    "discord"
    "docker"
    "drawio"
    "figma"
    "intel-power-gadget"
    "iterm2"
    "jetbrains-toolbox"
    "karabiner-elements"
    "keycastr"
    "macs-fan-control"
    "netnewswire"
    "obs"
    "obsidian"
    "postman"
    "remote-desktop-manager-free"
    "slack"
    "suspicious-package"
    "transmission"
    "twitch"
    "unity"
    "unity-hub"
    "vlc"
    "adoptopenjdk8-openj9-jre"
    "adoptopenjdk11-openj9-jre"
    "adoptopenjdk15-openj9-jre"
    "logitech-g-hub"
  ];

  homebrew.masApps = {
  };
}
