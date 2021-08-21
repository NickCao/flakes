{ closureInfo
, runCommand
, coreutils
, e2fsprogs
, util-linux
, nixUnstable
, formats
, firecracker-kernel
, firecracker
, writeShellScript
, bash
, bashInteractive
, sirius
, mount
, writeText
, busybox
}:
let
  init = writeShellScript "init-stage1" ''
    specialMount() {
      local device="$1"
      local mountPoint="$2"
      local options="$3"
      local fsType="$4"
      ${busybox}/bin/mount -t "$fsType" -o "$options" "$device" "$mountPoint"
    }
    specialMount "tmpfs" "/tmp" "noatime" "tmpfs"
    specialMount "tmpfs" "/build" "noatime,mode=0755" "tmpfs"
    specialMount "devtmpfs" "/dev" "nosuid,strictatime,mode=755,size=5%" "devtmpfs"
    ${busybox}/bin/mkdir /dev/pts
    specialMount "devpts" "/dev/pts" "nosuid,noexec,mode=620,ptmxmode=0666,gid=3" "devpts"
    specialMount "proc" "/proc" "nosuid,noexec,nodev" "proc"
    specialMount "sysfs" "/sys" "nosuid,noexec,nodev" "sysfs"
    ${nixUnstable}/bin/nix --experimental-features nix-command show-config
    ${busybox}/bin/chmod a+rw /dev/vsock
    ${busybox}/bin/chown 65533:65533 /build
    ${busybox}/bin/su builder -s ${sirius}/bin/agent -- -p 1024 -n ${nixUnstable}/bin/nix-daemon
  '';
  nix-config = writeText "nix.conf" ''
    build-users-group =
    trusted-users =
    substituters =
    store = /build
  '';
  db = closureInfo { rootPaths = [ init ]; };
  image = runCommand "nixos.img"
    {
      requiredSystemFeatures = [ "recursive-nix" ];
      nativeBuildInputs = [ e2fsprogs util-linux coreutils nixUnstable ];
    } ''
    touch $out
    truncate -s $(( $(cat ${db}/total-nar-size) + 500000000 )) $out
    mkdir -p rootfs/{tmp,dev,proc,sys,etc/nix,build}
    echo "builder:x:65533:65533::/:" > rootfs/etc/passwd
    cp ${nix-config} rootfs/etc/nix/nix.conf
    nix --experimental-features nix-command copy --no-check-sigs --to ./rootfs ${init}
    mkfs.ext4 -d rootfs $out
  '';
in
writeShellScript "demo" ''
  ${sirius}/bin/bridge -f ${firecracker}/bin/firecracker -k ${firecracker-kernel.dev}/vmlinux -r ${image} -a "init=${init} panic=-1 console=ttyS0 i8042.reset random.trust_cpu=on"
''
