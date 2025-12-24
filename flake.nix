{
  description = "Apon's Modern NixOS Configuration";

  inputs = {
    # We'll use the unstable branch for the latest VS Code and drivers
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs, ... }@inputs: {
    # REPLACE 'your-hostname' with the output of the 'hostname' command
    nixosConfigurations.apon-nix = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      specialArgs = { inherit inputs; };
      modules = [ ./configuration.nix ];
    };
  };
}