# █░█ █▀▄▀█ ▄▄ █▀▄▀█ █▀█ █▀▄ █░█ █░░ █▀▀ ▀
# █▀█ █░▀░█ ░░ █░▀░█ █▄█ █▄▀ █▄█ █▄▄ ██▄ ▄
# -- -- -- -- -- -- -- -- -- -- -- -- -- -

{ config, pkgs, lib, ... }: let
  cfg = config.programs.nvchad;
  extraPackages = [];
  neovim = pkgs.neovim;
  nvchad = pkgs.callPackage ./nvchad.nix {
    inherit neovim;
    extraPackages = cfg.extraPackages;
    extraConfig = cfg.extraConfig;
  };
  in {
  options.programs.nvchad = with lib; {
    enable = mkEnableOption "Enable NvChad";
    extraPackages = mkOption {
      default = extraPackages;
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
      default = neovim;
      type = types.package;
      description = ''
        Neovim package name in case you are not using pkgs.neovim from 
        unstable nixpkgs
      '';
    };
    extraConfig = mkOption {
      default = builtins.toPath (fetchFromGitHub (import ./starter.nix));
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
        saved in /nix/store to ~/.config/nvim.
        This way you can customize the configuration in the usual way
        by cloning it from the NvChad repository.
        By default, the ~/.config/nvim is managed by HM.
      '';
    };
  };
  config = with pkgs; with lib; let
    confDir = "${config.xdg.configHome}/nvim";
  in mkIf cfg.enable {
    home = {
      packages = [ nvchad ];  
      activation = mkIf cfg.hm-activation {
        backupNvChad = hm.dag.entryBefore ["checkLinkTargets"] ''
          if [ -d "${confDir}" ]; then
            ${(
              if cfg.backup then ''
                backup_name="nvim_$(${coreutils}/bin/date +'%Y_%m_%d_%H_%M_%S').bak"
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
