{ config, pkgs, lib, ... }:

let
  user = builtins.getEnv "USER";
in
{
  imports = [
     <home-manager/nix-darwin>

    ./modules/homebrew.nix # pending upstream, PR #262

    # Personal modules
    ./shells.nix # shell configuration
    ./homebrew.nix
  ];

  environment.systemPackages = with pkgs; [
    nixFlakes
    home-manager
  ];
  programs.nix-index.enable = true;

  #####################
  # Nix configuration #
  #####################

  ## Enable experimental version of nix with flakes support
  nix.package = pkgs.nixFlakes;
  nix.extraOptions = "experimental-features = nix-command flakes";

  ## $(sysctl -n hw.cpu)
  nix.maxJobs = 16;
  nix.buildCores = 1;

  ## Garbage collect
  nix.gc.automatic = true;
  nix.gc.interval = { Hour = 1; };

  # To change location use the following command after updating the option below
  # $ darwin-rebuild switch -I darwin-config=...
  environment.darwinConfig = "$HOME/.config/nixpkgs/darwin.nix";

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  ################
  # home-manager #
  ################

  users.users."${user}".home = builtins.getEnv "HOME";
  home-manager.users."${user}" = import ../home-manager/home.nix;   

  #################
  # Global Config #
  #################

  programs = {
    bash = {
      enable = true;
    };
    zsh = {
      enable = true;
    };
    fish = {
      enable = true;
    };
  };

  ########################
  # System configuration #
  ########################

  # Networking
  networking.dns = [
    "1.1.1.1"
  ];
  networking.knownNetworkServices = [
    "Wi-Fi"
    "USB 10/100/1000 LAN"
  ];

  # Keyboard
  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToControl = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;

  system.build.applications = pkgs.lib.mkForce (pkgs.buildEnv {
    name = "applications";
    paths = config.environment.systemPackages ++ config.home-manager.users."${user}".home.packages;
    pathsToLink = "/Applications";
  });

  system.activationScripts.applications.text = pkgs.lib.mkForce (''
    echo "setting up ~/Applications/Nix..."
    rm -rf ~/Applications/Nix
    mkdir -p ~/Applications/Nix
    chown ${user} ~/Applications/Nix
    find ${config.system.build.applications}/Applications -maxdepth 1 -type l | while read f; do
      src="$(/usr/bin/stat -f%Y $f)"
      appname="$(basename $src)"
      osascript -e "tell app \"Finder\" to make alias file at POSIX file \"/Users/${user}/Applications/Nix/\" to POSIX file \"$src\" with properties {name: \"$appname\"}";
    done
  '');
}
