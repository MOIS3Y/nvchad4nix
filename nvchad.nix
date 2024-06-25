# █▄░█ █░█ █▀▀ █░█ ▄▀█ █▀▄ ▀
# █░▀█ ▀▄▀ █▄▄ █▀█ █▀█ █▄▀ ▄
# -- -- -- -- -- -- -- -- --

{ config, pkgs, lib, ... }: 
  let
    cfg = config.programs.nvchad;

    default = {
      neovim = pkgs.neovim;
      nvchad = pkgs.fetchFromGitHub {
        owner = "NvChad";
        repo = "starter";
        rev = "41c5b467339d34460c921a1764c4da5a07cdddf7";
        sha256 = "sha256-yxZTxFnw5oV/76g+qkKs7UIwgkpD+LkN/6IJxiV9iRY=";
        name = "nvchad-2.5";
      };
      # ? I'm not sure whether to add dependencies by default
      # ? or leave it entirely up to the user
      dependencies = with pkgs; [
        gcc
        nodejs_20
        lua-language-server
        (lua.withPackages(ps: with ps; [ luarocks ]))
        ripgrep
        tree-sitter
      ];
    };
  in {
  options.programs.nvchad = with lib; {

    enable = mkEnableOption "Enable NvChad config";

    dependencies = mkOption {
      default = default.dependencies;
      type = types.listOf types.package;
      description = ''
        List of runtime dependencies.
        NvChad extensions assume that the libraries it need
        will be available globally.
        By default, all dependencies for the starting configuration are included.
        Overriding the option will expand the list of dependencies.
      '';
    };
    neovim = mkOption {
      default = default.neovim;
      type = types.package;
      description = ''
        Neovim package name in case you are not using pkgs.neovim from 
        unstable nixpkgs
      '';
    };
    nvchad = mkOption {
      default = builtins.toPath default.nvchad;
      type = types.pathInStore;
      description = ''
        Your own NvChad configuration based on the started repository.
        Overriding the option will override the default configuration
        included in the module. This should be the path to the nix store.
        The easiest way is to use pkgs.fetchFromGitHub
      '';
    };
    backup = mkOption {
      default = true;
      type = types.bool;
      description = ''
        Since the module violates the principle of immutability
        and copies NvChad to ~/.config/nvim rather than creating
        a symbolic link by default, it will create a backup copy of
        ~/.config/nvim_%Y_%m_%d_%H_%M_%S.bak when each generation.
        This ensures that the module does not 
        accidentally delete the configuration.
        You probably do not need backups,
        just disable them config.programs.nvchad.backup = false;
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    home.packages = (
      (lib.lists.unique (cfg.dependencies ++ default.dependencies)) ++ [cfg.neovim]
    );
    home.activation.backupNvim = lib.hm.dag.entryBefore ["checkLinkTargets"] ''
      if [ -d "${config.xdg.configHome}/nvim" ]; then
        ${(
          if cfg.backup then ''
            backup_name="nvim_$(${pkgs.coreutils}/bin/date +'%Y_%m_%d_%H_%M_%S').bak"
            ${pkgs.coreutils}/bin/mv \
              ${config.xdg.configHome}/nvim \
              ${config.xdg.configHome}/$backup_name
          ''
          else ''
            ${pkgs.coreutils}/bin/rm -r ${config.xdg.configHome}/nvim
          ''
        )}
      fi
    '';
    home.activation.copyNvChad = lib.hm.dag.entryAfter ["writeBoundary"] ''
      mkdir ${config.xdg.configHome}/nvim
      ${pkgs.coreutils}/bin/cp -r ${cfg.nvchad}/* ${config.xdg.configHome}/nvim/
      for file_or_dir in $(${pkgs.findutils}/bin/find ${config.xdg.configHome}/nvim); do
        if [ -d "$file_or_dir" ]; then
          ${pkgs.coreutils}/bin/chmod 755 $file_or_dir
        else
          ${pkgs.coreutils}/bin/chmod 664 $file_or_dir
        fi
      done
    '';
  };
}
