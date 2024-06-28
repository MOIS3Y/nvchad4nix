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
,extraConfig ? false
}: with lib;
stdenvNoCC.mkDerivation rec {
  pname = "nvchad";
  version = "2.5";
  src = if extraConfig then extraConfig else fetchFromGitHub (import ./starter.nix);
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
