# █▄░█ █░█ █▀▀ █░█ ▄▀█ █▀▄ ▀
# █░▀█ ▀▄▀ █▄▄ █▀█ █▀█ █▄▀ ▄
# -- -- -- -- -- -- -- -- --

{ stdenvNoCC
,makeWrapper
,lib
,config
,cfg
,git
,gcc
,nodejs_20
,lua-language-server
,lua
,ripgrep
,tree-sitter
}: with lib;
stdenvNoCC.mkDerivation rec {
  pname = "nvchad";
  version = "2.5";
  src = cfg.src;
  nvChadBin = ../bin/nvchad;
  nativeBuildInputs = (
    lists.unique (
      cfg.dependencies ++ [
        git
        gcc
        nodejs_20
        lua-language-server
        (lua.withPackages(ps: with ps; [ luarocks ]))
        ripgrep
        tree-sitter
        makeWrapper
      ]
    )
  ) ++ [cfg.neovim];
  installPhase = ''
    mkdir -p $out/{bin,config}
    cp -r $src/* $out/config
    install -Dm755 $nvChadBin $out/bin/nvchad
    wrapProgram $out/bin/nvchad --prefix PATH : '${makeBinPath nativeBuildInputs}'
  '';
}
