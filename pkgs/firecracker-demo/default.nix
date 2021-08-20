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
, socat
}:
let
  init = writeShellScript "init-stage1" ''
    ${util-linux}/bin/mount -t tmpfs -o noatime,mode=0755 tmpfs /mnt
    ${coreutils}/bin/mkdir -p /mnt/{root,work,upper}
    ${util-linux}/bin/mount -o noatime,lowerdir=/,upperdir=/mnt/upper,workdir=/mnt/work -t overlay overlay /mnt/root
    export PATH=${coreutils}/bin
    ${util-linux}/bin/switch_root /mnt/root ${init-stage2}
  '';
  init-stage2 = writeShellScript "init-stage2" ''
    ${socat}/bin/socat VSOCK-LISTEN:1,fork EXEC:"${bashInteractive}/bin/bash -li",stderr
  '';
  db = closureInfo { rootPaths = [ init ]; };
  image = runCommand "nixos.img"
    {
      requiredSystemFeatures = [ "recursive-nix" ];
      nativeBuildInputs = [ e2fsprogs mount util-linux nixUnstable ];
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
      mem_size_mib = 1024;
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
