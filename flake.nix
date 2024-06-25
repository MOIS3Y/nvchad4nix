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

  outputs = { self, nixpkgs }: {
    homeManagerModules.nvchad = import ./nix/module.nix;
    homeManagerModule = self.homeManagerModules.nvchad;
  };
}
