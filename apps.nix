{ pkgs, ... }: {
  users.users.apon.packages = with pkgs; [
    # General Tools
    fastfetch
    btop
    firefox

    # Development tools
    git
    git-lfs         # Often required for Shopify GitHub integrations
    watchman        # Improves file-watching speed for Remix dev servers
    vscode

    # Web & Shopify Development
    nodejs_24
    shopify-cli
    shopify-themekit
    ruby
  ];
}