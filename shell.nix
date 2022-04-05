with import <nixpkgs> {
  overlays = [ (import ../slab/overlay.nix) ];
} ;
callPackage ./. {}
