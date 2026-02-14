{ ipxe, writeText }:
ipxe.override {
  embedScript = writeText "script.ipxe" ''
    #!ipxe
    dhcp
    set cmdline sshkey="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOLQwaWXeJipSuAB+lV202yJOtAgJSNzuldH7JAf2jji"
    chain --autofree http://nickcao.github.io/netboot/
    EOT
  '';
  additionalTargets = {
    "bin-x86_64-efi/ipxe.iso" = "ipxe-efi.iso";
  };
}
