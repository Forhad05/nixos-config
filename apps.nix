{ pkgs, ... }: {
  # 1. User Packages
  users.users.apon.packages = with pkgs; [
    # General
    fastfetch
    firefox
    vscode

    # sharing
    qbittorrent

    # Development
    git
    git-lfs
    watchman
    nodejs_24
    nodePackages.npm
    shopify-cli
    shopify-themekit
    ruby
  ];
}
