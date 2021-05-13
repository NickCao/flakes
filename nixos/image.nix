{ pkgs, build }:
with pkgs;
let
  db = closureInfo { rootPaths = [ build.toplevel ]; };
in
runCommandNoCC "nixos.img" {} ''
  export root=$TMPDIR/root
  export NIX_STATE_DIR=$TMPDIR/state
  ${nix}/bin/nix-store --load-db < ${db}/registration
  ${nix}/bin/nix copy --no-check-sigs --to $root ${build.toplevel}
  ${nix}/bin/nix-env --store $root -p $root/nix/var/nix/profiles/system --set ${build.toplevel}
  mkdir -m 0755 -p $root/etc
  touch $root/etc/NIXOS
  ${libguestfs-with-appliance}/bin/guestfish -N $out=fs:ext4:2G -m /dev/sda1 << EOT
  set-label /dev/sda1 nixos
  copy-in $root/nix $root/etc /
  command "/nix/var/nix/profiles/system/activate"
  command "/nix/var/nix/profiles/system/bin/switch-to-configuration boot"
  EOT
''
