{ config, lib, pkgs, inputs, ... }:
let
  secrets = import ./secrets.nix;
in
{
  imports = [ 
    ./hardware-configuration.nix
    ./apps.nix
  ];
  
  # SYSTEM CORE (Boot, Time, Locale)
  boot.loader = {
    systemd-boot.enable = true;
    efi.canTouchEfiVariables = true;
  };

  time.timeZone = "Asia/Dhaka";
  i18n.defaultLocale = "en_US.UTF-8";

  nix.settings = {
    auto-optimise-store = true;
    experimental-features = [ "nix-command" "flakes" ];
    trusted-users = [ "root" "apon" ];
  };
  
  # NETWORKING & FIREWALL
  networking = {
    hostName = "apon-nix";
    hostId = secrets.hostId;
    networkmanager = {
      enable = true;
      unmanaged = [ "enp3s0" ];
    };
    useDHCP = false; 

    interfaces.enp3s0.ipv4.addresses = [{
      address = "192.168.110.147";
      prefixLength = 24;
    }];

    defaultGateway = "192.168.110.1";
    nameservers = [ "1.1.1.1" "8.8.8.8" ];

    firewall = {
      enable = true;
      allowedTCPPorts = [ 22 443 8080 ];
    };
  };
  
  # HARDWARE (Nvidia, Audio, Graphics)
  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia = {
      modesetting.enable = true;
      powerManagement.enable = false;
      open = false; 
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
    };
  };

  services = {
    xserver.videoDrivers = ["nvidia"];
    pipewire = {
      enable = true;
      alsa.enable = true;
      alsa.support32Bit = true;
      pulse.enable = true;
    };
    libinput.enable = true;
    openssh = {
      enable = true;
      ports = [ 22 443 ];
      settings = {
        PasswordAuthentication = false;
        PermitRootLogin = "no";
      };
    };
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
    };
    # privoxy = {
    #   enable = true;
    #   settings = {
    #     forward-socks5 = "/ 127.0.0.1:4000 .";
    #     listen-address = "127.0.0.1:8118";
    #   };
    # };
  };
  
  # USER & PROGRAMS (Shell, Hyprland, Steam)
  users.users.apon = {
    isNormalUser = true;
    description = "Apon";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" "uinput" ];
    openssh.authorizedKeys.keys = [ secrets.sshKey ];
  };

  programs = {
    hyprland.enable = true;
    waybar.enable = true;
    steam.enable = true;
    firefox.enable = true;
    zsh = {
      enable = true;
      autosuggestions.enable = true;
      syntaxHighlighting.enable = true;
      ohMyZsh = {
        enable = true;
        plugins = [ "git" "sudo" ];
        theme = "robbyrussell";
      };
    };
  };
  
  # SYSTEM PACKAGES
  nixpkgs.config = {
    allowUnfree = true;
    permittedInsecurePackages = [ "ventoy-1.1.07" ];
  };

  environment.systemPackages = with pkgs; [
    # Tools
    vim wget htop parted e2fsprogs btop mtr nmap fzf fd ripgrep
    nvtopPackages.nvidia openssh proxychains-ng
    
    # Gaming/Wine
    wineWow64Packages.full winetricks vulkan-tools vulkan-loader
    lutris heroic dxvk mangohud p7zip
    
    # Hyprland Ecosystem
    kitty swww wofi libnotify dunst hyprlock hypridle bibata-cursors
    hyprlandPlugins.hyprexpo hyprpolkitagent
    grim slurp wl-clipboard networkmanagerapplet pavucontrol
    
    # Desktop Apps
    mpv kdePackages.dolphin discord qbittorrent google-chrome python315 plasma-panel-colorizer
  ];
  
  # CUSTOM SERVICES & TUNNELS
  # systemd.services.shopify-bypass = {
  #   description = "Bypass ISP filtering for Shopify CLI";
  #   after = [ "network-online.target" ];
  #   wants = [ "network-online.target" ];
  #   wantedBy = [ "multi-user.target" ];
  #   serviceConfig = {
  #     User = "apon"; 
  #     ExecStart = "${pkgs.openssh}/bin/ssh -p 443 -NT -D 4000 -o StrictHostKeyChecking=accept-new -i ${secrets.sshKeyPath} ${secrets.sshUser}@${secrets.vmIp}";
  #     Restart = "always";
  #     RestartSec = 5;
  #   };
  # };
  
  # MISC (Fonts, Aliases, Variables)
  fonts.packages = with pkgs; [
    noto-fonts noto-fonts-cjk-sans noto-fonts-color-emoji
    nerd-fonts.jetbrains-mono nerd-fonts.symbols-only
    liberation_ttf fira-code
  ];

  environment = {
    variables = {
      # SHOPIFY_HTTP_PROXY = "http://127.0.0.1:8118";
      # SHOPIFY_HTTPS_PROXY = "http://127.0.0.1:8118";
    };
    shellAliases = {
      check-shield = "curl https://ifconfig.me && systemctl status shopify-bypass privoxy";
      rebuild = "sudo nixos-rebuild switch";
      rebuild-refresh = "sudo nixos-rebuild switch && hyprctl reload && notify-send 'Rebuild complete!'";
    };
  };

  zramSwap.enable = true;
  security.polkit.enable = true;
  xdg.portal = {
    enable = true;
    extraPortals = [ pkgs.xdg-desktop-portal-hyprland ];
  };

  system.stateVersion = "25.05";
}