{ pkgs, ... }: {
  # 1. User Packages
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
    nodePackages.npm
    shopify-cli
    shopify-themekit
    ruby
  ];

  # 2. System Network Settings
  networking.firewall = {
    enable = true;
    # 9292 is the standard Shopify CLI port
    # 5173 is the default Vite port
    allowedTCPPorts = [ 9292 5173 3000 ];
  };
}
