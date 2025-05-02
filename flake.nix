{
  description = "My Nix flake combining NixOS and HomeManager configs";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nvf, home-manager, ... } @ inputs: let
    inherit (self) outputs;
  in {
    
    # NixOS configuration entrypoint: 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = {
      mbp = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs outputs;};
        modules = [./nixos/configuration.nix];
      };
    };
    
    # Standalone home-manager configuration entrypoint: 'home-manager --flake .#user@host'
    homeConfigurations = {
      "tim@mbp" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = {inherit inputs outputs;};
        modules = [./home-manager/home.nix];
      };
    };
  };
}
