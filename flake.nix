{
  description = ''
    NvChad is Blazing fast Neovim config
    providing solid defaults and a beautiful UI https://nvchad.com/
    This home manager module will add NvChad configuration to your Nix setup
    You can specify in the configuration your own extended configuration
    built on the starter repository
    You can also add runtime dependencies that will be isolated from the main
    system but available to NvChad. This is useful for adding lsp servers.
    If you are using your own Neovim build and not from nixpkgs
    you can also specify your package.
    In addition, you can continue to configure NvChad in the usual way
    manually by disabling the hm-activation option
  '';

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";
  };

  outputs = { self, nixpkgs }: 
  let
    lib = nixpkgs.lib;
    genSystems = lib.genAttrs [
      "aarch64-linux"
      "x86_64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    pkgsFor = genSystems (system:
      import nixpkgs {
        inherit system;
        overlays = [ self.overlays.nvchad ];
      }
    );
  in {
    packages = genSystems (system:
      (self.overlays.default pkgsFor.${system} pkgsFor.${system})
      // { default = self.packages.${system}.nvchad; }
    );
    overlays = (import ./nix/overlays.nix { })
    // { default = self.overlays.nvchad ; };
    homeManagerModules.nvchad = import ./nix/module.nix;
    homeManagerModule = self.homeManagerModules.nvchad;
  };
}
