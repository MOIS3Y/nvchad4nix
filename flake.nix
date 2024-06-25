{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: {
    homeManagerModules.nvchad = import ./nvchad.nix;
    homeManagerModule = self.homeManagerModules.nvchad;
  };
}
