rec {
  mapPackages = f: with builtins;listToAttrs (map (name: { inherit name; value = f name; }) (filter (v: v != null) (attrValues (mapAttrs (k: v: if v == "directory" then k else null) (readDir ./.)))));
  packages = pkgs: mapPackages (name: pkgs.${name});
  overlay = final: prev: mapPackages (name: final.callPackage (./. + "/${name}") { });
}
