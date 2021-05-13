{ pkgs, build }:
with pkgs;
let
  db = closureInfo { rootPaths = [ build.toplevel ]; };
in
runCommandNoCC "" {} ''
  export root=$TMPDIR/root
  export NIX_STATE_DIR=$TMPDIR/state
  ${nix}/bin/nix-store --load-db < ${db}/registration
  ${nix}/bin/nix copy --no-check-sigs --to $root ${build.toplevel}
  ${nix}/bin/nix-env --store $root -p $root/nix/var/nix/profiles/system --set ${build.toplevel}
  mkdir -m 0755 -p $root/etc
  touch $root/etc/NIXOS
  cp -a $root $out
''
