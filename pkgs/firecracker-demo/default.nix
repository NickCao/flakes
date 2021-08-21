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
, writeText
}:
let
  init = writeShellScript "init-stage1" ''
    ${util-linux}/bin/mount -t tmpfs -o noatime,mode=0755 tmpfs /mnt
    ${coreutils}/bin/mkdir -p /mnt/{root,work,upper}
    ${util-linux}/bin/mount -o noatime,lowerdir=/,upperdir=/mnt/upper,workdir=/mnt/work -t overlay overlay /mnt/root
    export PATH=${coreutils}/bin
    ${util-linux}/bin/switch_root /mnt/root ${init-stage2}
  '';
  nix-config = writeText "nix.conf" ''
    build-users-group =
    trusted-users =
    substituters =
  '';
  init-stage2 = writeShellScript "init-stage2" ''
    specialMount() {
      local device="$1"
      local mountPoint="$2"
      local options="$3"
      local fsType="$4"
      ${coreutils}/bin/mkdir -m 0755 -p "$mountPoint"
      ${util-linux}/bin/mount -n -t "$fsType" -o "$options" "$device" "$mountPoint"
    }
    specialMount "devtmpfs" "/dev" "nosuid,strictatime,mode=755,size=5%" "devtmpfs"
    specialMount "devpts" "/dev/pts" "nosuid,noexec,mode=620,ptmxmode=0666,gid=3" "devpts"
    specialMount "proc" "/proc" "nosuid,noexec,nodev" "proc"
    specialMount "sysfs" "/sys" "nosuid,noexec,nodev" "sysfs"
    ${coreutils}/bin/mkdir -p /etc/nix
    ${coreutils}/bin/echo "root:x:0:0::/root:" > /etc/passwd
    ${coreutils}/bin/cp ${nix-config} /etc/nix/nix.conf
    ${coreutils}/bin/mkdir /tmp
    ${nixUnstable}/bin/nix --experimental-features nix-command show-config
    ${sirius}/bin/agent -p 1 -n ${nixUnstable}/bin/nix-daemon
  '';
  db = closureInfo { rootPaths = [ init ]; };
  image = runCommand "nixos.img"
    {
      requiredSystemFeatures = [ "recursive-nix" ];
      nativeBuildInputs = [ e2fsprogs util-linux nixUnstable ];
    } ''
    touch $out
    truncate -s $(( $(cat ${db}/total-nar-size) + 500000000 )) $out
    mkdir -p rootfs/mnt
    nix --experimental-features nix-command copy --no-check-sigs --to ./rootfs ${init}
    mkfs.ext4 -d rootfs $out
  '';
  config = (formats.json { }).generate "config.json" {
    boot-source = {
      kernel_image_path = "${firecracker-kernel.dev}/vmlinux";
      boot_args = "init=${init} panic=-1 console=ttyS0 i8042.reset random.trust_cpu=on";
    };
    drives = [
      {
        drive_id = "rootfs";
        path_on_host = "${image}";
        is_root_device = true;
        is_read_only = true;
      }
    ];
    machine-config = {
      vcpu_count = 2;
      mem_size_mib = 10240;
      ht_enabled = true;
    };
    vsock = {
      guest_cid = 3;
      uds_path = "vsock.sock";
      vsock_id = "vsock";
    };
  };
in
writeShellScript "demo" ''
  ${firecracker}/bin/firecracker --no-api --config-file ${config}
''
