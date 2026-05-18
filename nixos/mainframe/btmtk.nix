{
  stdenv,
  kernel,
  fetchpatch,
}:

stdenv.mkDerivation {
  pname = "btmtk-kernel-module";
  inherit (kernel)
    src
    version
    postPatch
    nativeBuildInputs
    ;

  kernel_dev = kernel.dev;
  kernelVersion = kernel.modDirVersion;
  modulePath = "drivers/bluetooth";

  patches = [
    (fetchpatch {
      url = "https://gitlab.com/cki-project/kernel-ark/-/commit/f52ec337a3f4e4d40707197a07dc0eda386be1f2.patch";
      hash = "sha256-q/sB4SLlqwtrnjmLKzkFa5B7sD8GDmhsZNd+hfcC1sY=";
    })
  ];

  buildPhase = ''
    BUILT_KERNEL=$kernel_dev/lib/modules/$kernelVersion/build

    cp $BUILT_KERNEL/Module.symvers .
    cp $BUILT_KERNEL/.config        .
    cp $kernel_dev/vmlinux          .

    make "-j$NIX_BUILD_CORES" modules_prepare
    make "-j$NIX_BUILD_CORES" M=$modulePath CONFIG_BT_MTK=m modules
  '';

  installPhase = ''
    make INSTALL_MOD_PATH="$out" M="$modulePath" modules_install
  '';
}
