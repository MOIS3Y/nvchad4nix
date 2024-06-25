# █░█ █▀▄▀█ ▄▄ █▀▄▀█ █▀█ █▀▄ █░█ █░░ █▀▀ ▀
# █▀█ █░▀░█ ░░ █░▀░█ █▄█ █▄▀ █▄█ █▄▄ ██▄ ▄
# -- -- -- -- -- -- -- -- -- -- -- -- -- -

{ config, pkgs, lib, ... }: 
  let
    cfg = config.programs.nvchad;
    src = pkgs.fetchFromGitHub {
      owner = "NvChad";
      repo = "starter";
      rev = "41c5b467339d34460c921a1764c4da5a07cdddf7";
      sha256 = "sha256-yxZTxFnw5oV/76g+qkKs7UIwgkpD+LkN/6IJxiV9iRY=";
      name = "nvchad-2.5";
    };
    nvchad = pkgs.callPackage ./nvchad.nix { inherit config; inherit cfg; };
  in {
  options.programs.nvchad = with lib; {

    enable = mkEnableOption "Enable NvChad";

    dependencies = mkOption {
      default = [];
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
      default = pkgs.neovim;
      type = types.package;
      description = ''
        Neovim package name in case you are not using pkgs.neovim from 
        unstable nixpkgs
      '';
    };
    src = mkOption {
      default = builtins.toPath src;
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
        and copies NvChad to ~/.config/nvchad rather than creating
        a symbolic link by default, it will create a backup copy of
        ~/.config/nvchad_%Y_%m_%d_%H_%M_%S.bak when each generation.
        This ensures that the module
        will not delete the configuration accidentally.
        You probably do not need backups, just disable them
        config.programs.nvchad.backup = false;
      '';
    };
    hm-activation = mkOption {
      default = true;
      type = types.bool;
      description = ''
        If you do not want home-manager to manage nvchad configuration, 
        set the false option. In this case, HM will not copy the configuration
        saved in /nix/store to ~/.config/nvchad.
        This way you can customize the configuration in the usual way
        by cloning it from the NvChad repository.
        By default, the ~/.config/nvchad is managed by HM.
      '';
    };
  };
  config = with pkgs; with lib; let
    confDir = "${config.xdg.configHome}/nvchad";
  in mkIf cfg.enable {
    home = {
      packages = [ nvchad ];  
      activation = mkIf cfg.hm-activation {
        backupNvChad = hm.dag.entryBefore ["checkLinkTargets"] ''
          if [ -d "${confDir}" ]; then
            ${(
              if cfg.backup then ''
                backup_name="nvchad_$(${coreutils}/bin/date +'%Y_%m_%d_%H_%M_%S').bak"
                ${coreutils}/bin/mv \
                  ${confDir} \
                  ${config.xdg.configHome}/$backup_name
              ''
              else ''
                ${coreutils}/bin/rm -r ${confDir}
              ''
            )}
          fi
        '';
        copyNvChad = hm.dag.entryAfter ["writeBoundary"] ''
          ${coreutils}/bin/mkdir ${confDir}
          ${coreutils}/bin/cp -r ${nvchad}/config/* ${confDir}
          for file_or_dir in $(${findutils}/bin/find ${confDir}); do
            if [ -d "$file_or_dir" ]; then
              ${coreutils}/bin/chmod 755 $file_or_dir
            else
              ${coreutils}/bin/chmod 664 $file_or_dir
            fi
          done
        '';
      };
    };
  };
}
