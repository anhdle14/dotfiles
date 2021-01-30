{ pkgs, lib, ... }:

{
  # Import config broken out into files
  imports = [
  ];

  ###########################
  # Configure misc packages #
  ###########################

  #######################
  # Additional packages #
  #######################

  home.packages = with pkgs; [
    tree
    bat
    tmux
    gnupg
    rsync
    neofetch
    fzf
    ripgrep
    nnn
    newsboat
    du-dust
    exa
    fd
    htop
    procs
    mosh
    tealdeer
    thefuck
    bottom
    rsync

    zip
    gzip
    xz

    neovim

    gnumake
    gnused
    gnupatch
    diffutils
    gnuplot
    stow
    coreutils-full
    watchman
    man
    findutils
    gettext
    getopt
    less
    more
    most
    libtool

    # bazel
    emscripten
    pandoc
    ocaml

    openssl
    ffmpeg

    curl
    wget

    zsh
    zsh-completions

    jq
    yq-go

    gitAndTools.gh
    gitAndTools.git
    gitAndTools.delta
    gitAndTools.gitflow
    pre-commit
    git-lfs

    kubernetes-helm
    docker
    kubectl
    kubectx
    istioctl
    skaffold
    stern
    kubeval
    tektoncd-cli
    tilt

    deno
    nodejs
    nodePackages.typescript

    python
    python3
    python38Packages.pip
    youtube-dl

    rustup

    go
    hugo

    php

    rbenv
    ruby

    cmake

    R

    awscli2
    google-cloud-sdk
    # terraform_0_14 use tfenv from Homebrew for now
    terragrunt
    terraform-docs
    pulumi-bin
    ansible
    powershell
    vault
    tflint
    tfsec
    minio
    conftest
    eksctl

    protobuf

    reattach-to-user-namespace
    m-cli

    fontconfig
    shellcheck

    libtool
  ];

  # This value determines the Home Manager release that your configuration is compatible with. This
  # helps avoid breakage when a new Home Manager release introduces backwards incompatible changes.
  #
  # You can update Home Manager without changing this value. See the Home Manager release notes for
  # a list of state version changes in each release.
  home.stateVersion = "21.03";
}
