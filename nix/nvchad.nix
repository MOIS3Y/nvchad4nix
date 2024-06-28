# █▄░█ █░█ █▀▀ █░█ ▄▀█ █▀▄ ▀
# █░▀█ ▀▄▀ █▄▄ █▀█ █▀█ █▄▀ ▄
# -- -- -- -- -- -- -- -- --

{ stdenvNoCC
,fetchFromGitHub
,makeWrapper
,lib
,git
,gcc
,neovim
,nodejs
,lua5_1
,lua-language-server
,ripgrep
,tree-sitter
,extraPackages ? []
,extraConfig ? ./starter.nix
}: with lib;
stdenvNoCC.mkDerivation rec {
  pname = "nvchad";
  version = "2.5";
  src = (
    if extraConfig == ./starter.nix then fetchFromGitHub (import extraConfig) 
    else extraConfig
  );
  nvChadBin = ../bin/nvchad;
  nvChadContrib = ../contrib;
  nativeBuildInputs = (
    lists.unique (
      extraPackages ++ [
        git
        gcc
        nodejs
        lua-language-server
        (lua5_1.withPackages(ps: with ps; [ luarocks ]))
        ripgrep
        tree-sitter
        makeWrapper
      ]
    )
  ) ++ [ neovim ];
  installPhase = ''
    mkdir -p $out/{bin,config}
    cp -r $src/* $out/config
    install -Dm755 $nvChadBin $out/bin/nvchad
    wrapProgram $out/bin/nvchad --prefix PATH : '${makeBinPath nativeBuildInputs}'
    runHook postInstall
  '';
  postInstall = ''
    mkdir -p $out/share/{applications,icons/hicolor/scalable/apps}
    cp $nvChadContrib/NvChad.desktop $out/share/applications
    cp $nvChadContrib/nvchad.svg $out/share/icons/hicolor/scalable/apps
  '';
}
