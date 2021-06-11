rec {
  mapPackages = f: with builtins;listToAttrs (map (name: { inherit name; value = f name; }) (filter (v: v != null) (attrValues (mapAttrs (k: v: if v == "directory" && k != "_build" then k else null) (readDir ./.)))));
  packages = pkgs: mapPackages (name: pkgs.${name});
  overlay = final: prev: mapPackages (name:
    let
      sources = (import ./_build/generated.nix) { inherit (final) fetchurl fetchgit; };
      package = import (./. + "/${name}");
      args = builtins.intersectAttrs (builtins.functionArgs package) { source = sources.${name}; };
    in
    final.callPackage package args
  );
}
