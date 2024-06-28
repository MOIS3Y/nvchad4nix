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
,lua5_1
,lua-language-server
,ripgrep
,tree-sitter
}: with lib;
stdenvNoCC.mkDerivation rec {
  pname = "nvchad";
  version = "2.5";
  src = cfg.src;
  nvChadBin = ../bin/nvchad;
  nvChadContrib = ../contrib;
  nativeBuildInputs = (
    lists.unique (
      cfg.dependencies ++ [
        git
        gcc
        nodejs_20
        lua-language-server
        (lua5_1.withPackages(ps: with ps; [ luarocks ]))
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
  postInstall = ''
    mkdir -p $out/share/{applications,icons/hicolor/scalable/apps}
    cp $nvChadContrib/NvChad.desktop $out/share/applications
    cp $nvChadContrib/nvchad.svg $out/share/icons/hicolor/scalable/apps
  '';
}
