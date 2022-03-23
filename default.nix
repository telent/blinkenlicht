{ stdenv
, callPackage
, fetchFromGitHub
, fetchurl
, gobject-introspection
, gtk3
, gtk-layer-shell
, lib
, librsvg
, lua53Packages
, lua5_3
, makeWrapper
, writeText
}:
let
  pname = "blinkenlicht";
  fennel = fetchurl {
    name = "fennel.lua";
    url = "https://fennel-lang.org/downloads/fennel-1.0.0";
    hash = "sha256:1nha32yilzagfwrs44hc763jgwxd700kaik1is7x7lsjjvkgapw7";
  };

  lua = lua5_3.withPackages (ps: with ps; [
    lgi
    luafilesystem
    luaposix
    readline
  ]);

in stdenv.mkDerivation {
  inherit pname;
  version = "0.1";
  src =./.;

  inherit fennel;

  buildInputs = [
    gobject-introspection.dev
    gtk-layer-shell
    gtk3
    lua
  ];
  nativeBuildInputs = [ lua makeWrapper ];

  makeFlags = [ "PREFIX=${placeholder "out"}" ];
  # GDK_PIXBUF_MODULE_FILE setting is to support SVG icons without
  # their having been transformed to bitmaps.
  # This makes a big difference to how many icons are displayed on
  # my machine
  postInstall = ''
    mkdir -p $out/share/dbus-1/services

    wrapProgram $out/bin/${pname} --set GDK_PIXBUF_MODULE_FILE ${librsvg.out}/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache --set GI_TYPELIB_PATH "$GI_TYPELIB_PATH"
  '';
}
