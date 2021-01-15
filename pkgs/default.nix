rec {
  mapPackages = f: with builtins;listToAttrs (map (name: { inherit name; value = f name; }) (filter (v: v != null) (attrValues (mapAttrs (k: v: if v == "directory" then k else null) (readDir ./.)))));
  getPackages = pkgs: pkgs.lib.filterAttrs (n: p: p.meta.only or true) (mapPackages (name: pkgs.${name}));
  overlay = final: prev: mapPackages (name: final.callPackage (./. + "/${name}") { });
}
