{ closureInfo
, runCommand
, coreutils
, e2fsprogs
, mount
, util-linux
, nixUnstable
, vmTools
, firecracker-kernel
, firecracker
, firectl
, writeShellScript
, tree
, bash
, strace
, init ? (writeShellScript "init" ''
    specialMount() {
      local device="$1"
      local mountpoint="$2"
      local options="$3"
      local fstype="$4"
      ${coreutils}/bin/install -m 0755 -d "$mountpoint"
      ${mount}/bin/mount -n -t "$fstype" -o "$options" "$device" "$mountpoint"
    }
    specialMount "devtmpfs" "/dev" "nosuid,strictatime,mode=755,size=5%" "devtmpfs"
    specialMount "devpts" "/dev/pts" "nosuid,noexec,mode=620,ptmxmode=0666,gid=3" "devpts"
    specialMount "tmpfs" "/dev/shm" "nosuid,nodev,strictatime,mode=1777,size=50%" "tmpfs"
    specialMount "proc" "/proc" "nosuid,noexec,nodev" "proc"
    specialMount "tmpfs" "/run" "nosuid,nodev,strictatime,mode=755,size=25%" "tmpfs"
    specialMount "sysfs" "/sys" "nosuid,noexec,nodev" "sysfs"
    ${nixUnstable}/bin/nix-instantiate --eval /etc/default.nix
  '')
}:
let
  db = closureInfo { rootPaths = [ init ]; };
  image = vmTools.runInLinuxVM (runCommand "image"
    {
      preVM = ''
        mkdir $out
        diskImage=$out/nixos.img
        ${vmTools.qemu}/bin/qemu-img create -f raw $diskImage $(( $(cat ${db}/total-nar-size) + 500000000 ))
      '';
      nativeBuildInputs = [ e2fsprogs mount util-linux nixUnstable ];
    } ''
    mkfs.ext4 /dev/vda
    mkdir /mnt && mount /dev/vda /mnt
    export NIX_STATE_DIR=$TMPDIR/state
    nix-store --load-db < ${db}/registration
    nix --experimental-features nix-command copy --no-check-sigs --to /mnt ${init}
    mkdir /mnt/etc
    echo "root:x:0:0:::" > /mnt/etc/passwd
    echo "1 + 1" > /mnt/etc/default.nix
  '');
in
writeShellScript "demo" ''
  IMG=$(${coreutils}/bin/mktemp -u)
  trap '{ ${coreutils}/bin/rm -f "$IMG"; }' EXIT
  ${coreutils}/bin/install -m 0600 ${image}/nixos.img "$IMG"
  ${firectl}/bin/firectl --firecracker-binary=${firecracker}/bin/firecracker \
    --kernel=${firecracker-kernel.dev}/vmlinux --kernel-opts="init=${init} panic=-1 loglevel=0 console=ttyS0 i8042.reset random.trust_cpu=on" \
    --root-drive="$IMG" "$@"
''
