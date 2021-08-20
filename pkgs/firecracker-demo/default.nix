{ closureInfo
, runCommand
, coreutils
, e2fsprogs
, mount
, util-linux
, nixUnstable
, formats
, vmTools
, firecracker-kernel
, firecracker
, firectl
, writeShellScript
, tree
, bash
, bashInteractive
, iproute2
, init ? (writeShellScript "init" ''
    ${util-linux}/bin/mount -t tmpfs -o noatime,mode=0755 tmpfs /mnt
    ${coreutils}/bin/mkdir -p /mnt/{root,work,upper}
    ${util-linux}/bin/mount -o noatime,lowerdir=/,upperdir=/mnt/upper,workdir=/mnt/work -t overlay overlay /mnt/root
    export PATH=${coreutils}/bin
    ${util-linux}/bin/switch_root /mnt/root ${bashInteractive}/bin/bash
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
    mkdir -p /mnt/mnt
    umount /dev/vda
  '');
  config = (formats.json {}).generate "config.json" {
    boot-source = {
      kernel_image_path = "${firecracker-kernel.dev}/vmlinux";
      boot_args = "init=${init} panic=-1 console=ttyS0 i8042.reset random.trust_cpu=on";
    };
    drives = [
      {
        drive_id = "rootfs";
        path_on_host = "${image}/nixos.img";
        is_root_device = true;
        is_read_only = true;
      }
    ];
    machine-config = {
      vcpu_count = 2;
      mem_size_mib = 1024;
      ht_enabled = true;
    };
  };
in
writeShellScript "demo" ''
  ${firecracker}/bin/firecracker --no-api --config-file ${config}
''
