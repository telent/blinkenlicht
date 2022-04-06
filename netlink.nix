{ lua, lib, fetchpatch, fetchFromGitHub, buildLuaPackage, libmnl }:
let pname = "netlink";
in buildLuaPackage {
  inherit pname;
  version = "0.1.1-1";

  buildInputs = [ libmnl ];

  src = fetchFromGitHub {
    repo = "lua-netlink";
    owner = "chris2511";
    rev = "v0.1.1";
    hash = "sha256:1833naskl4p7rz5kk0byfgngvw1mvf6cnz64sr3ny7i202wv7s52";
  };
  patches = [ (fetchpatch {
    url = "https://github.com/chris2511/lua-netlink/compare/master...telent:rtnetlink-types.patch";
    name = "rtnetlink-types.patch";
    hash = "sha256-lBCfP8pMyBIY+XEGWD/nPQ9l2dDOnXeitR1TaRUXCq8=";
  })];

  buildPhase = "$CC -shared -l mnl -o netlink.so src/*.c";

  installPhase = ''
    mkdir -p "$out/lib/lua/${lua.luaversion}"
    cp  netlink.so "$out/lib/lua/${lua.luaversion}/"
  '';

}


# , fetchFromGitHub }:
# let

#   simpleName = "netlink";

# in
# # TODO: add busted and checkPhase?
# buildLuaPackage rec {
#   version = "0.10.2";
#   pname = simpleName; # nixpkgs unstable needs this
#   name = "${pname}-${version}"; # nixpkgs 21.11 needs this

#   src = fetchFromGitHub {
#     owner = "stefano-m";
#     repo = "lua-${simpleName}";
#     rev = "v${version}";
#     sha256 = "0kl8ff1g1kpmslzzf53cbzfl1bmb5cb91w431hbz0z0vdrramh6l";
#   };

#   propagatedBuildInputs = [ lgi ];

#   buildPhase = ":";

#   installPhase = ''
#     mkdir -p "$out/share/lua/${lua.luaversion}"
#     cp -r src/${pname} "$out/share/lua/${lua.luaversion}/"
#   '';

# }
