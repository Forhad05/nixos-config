# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:
let
  secrets = import ./secrets.nix;
in
{
  # Your main imports at the top
  imports = [ 
    ./hardware-configuration.nix
    ./apps.nix 
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Configure network connections interactively with nmcli or nmtui.
  networking.hostName = "apon-nix"; # Define your hostname.
  networking.hostId = secrets.hostId;
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Asia/Dhaka";

  # Configure network proxy if necessary
  # networking.proxy.default = "socks5h://127.0.0.1:4000";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the KDE Plasma Desktop Environment.
  services.displayManager.sddm.enable = true;
  services.desktopManager.plasma6.enable = true;  

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # Enable CUPS to print documents.
  # services.printing.enable = true;

  # Enable sound.
  # services.pulseaudio.enable = true;
  # OR
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.apon = {
    isNormalUser = true;
    description = "Apon";
    extraGroups = [ "networkmanager" "wheel" "video" "audio" "input" "uinput" ];

    openssh.authorizedKeys.keys = [ secrets.sshKey ];
  };

  environment.shellAliases = {
    check-shield = "curl https://ifconfig.me && systemctl status shopify-bypass privoxy";
    rebuild = "sudo nixos-rebuild switch";
  };

  # 1. Enable the Zsh Program
  programs.zsh = {
    enable = true;
    autosuggestions.enable = true;
    syntaxHighlighting.enable = true;

    ohMyZsh = {
      enable = true;
      plugins = [ "git" "sudo" ]; # "sudo" plugin: press ESC twice to add sudo
      theme = "robbyrussell";     # Shows branch name and status icons
    };
  };

  programs.steam.enable = true;
  programs.firefox.enable = true;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.config.permittedInsecurePackages = [
    "ventoy-1.1.07"
  ];

  # Performance: zRam (Compressed RAM swap)
  zramSwap.enable = true;

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
    htop
    parted
    e2fsprogs
    btop                        # Adding this too, you'll love the UI!
    nvtopPackages.nvidia        # Your GPU monitor
    plasma-panel-colorizer
    openssh
    proxychains-ng
    mtr
    nmap
    wineWow64Packages.full
    winetricks
    vulkan-loader
  ];

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  # services.openssh.enable = true;
  services.openssh = {
    enable = true;
    ports = [ 22 443 ];
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 443 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Enable NVIDIA drivers
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    modesetting.enable = true;
    powerManagement.enable = false; # Set to true if you have a laptop
    open = false; # Use the proprietary drivers for best performance
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  fonts.packages = with pkgs; [
    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-color-emoji
    liberation_ttf
    fira-code
  ];

  nix.settings.auto-optimise-store = true;
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  # 1. Define the "Shield" Port for Shopify
  environment.variables = {
    # This fixes the Shopify CLI specifically
    SHOPIFY_HTTP_PROXY = "http://127.0.0.1:8118";
    SHOPIFY_HTTPS_PROXY = "http://127.0.0.1:8118";

    # This fixes curl, git, and everything else
    all_proxy = "socks5h://127.0.0.1:4000";
    ALL_PROXY = "socks5h://127.0.0.1:4000";
  };

  # 2. Create the Automatic Tunnel Service
  systemd.services.shopify-bypass = {
    description = "Bypass ISP filtering for Shopify CLI";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      # 1. This tells NixOS to run this as YOU (the person who owns the key)
      User = "apon"; 
      
      # 2. This points directly to your "ID Card" file
      # Replace the IP with your actual external IP
      ExecStart = "${pkgs.openssh}/bin/ssh -p 443 -NT -D 4000 -o StrictHostKeyChecking=accept-new -i ${secrets.sshKeyPath} ${secrets.sshUser}@${secrets.vmIp}";
      
      Restart = "always";
      RestartSec = 5;
    };
  };

  services.privoxy = {
    enable = true;
    settings = {
      forward-socks5 = "/ 127.0.0.1:4000 .";
      listen-address = "127.0.0.1:8118";
    };
  };

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.05"; # Did you read the comment?

}

