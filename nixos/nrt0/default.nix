{ system, self, nixpkgs, inputs }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ./configuration.nix
    ./services.nix
    ../modules/bgp
    ../modules/ssh.nix
    ../modules/vultr.nix
    ../modules/gravity.nix
    ../modules/divi.nix
    ../modules/dns
    {
      nixpkgs.overlays = [
        self.overlay
        inputs.fn.overlay
        inputs.blog.overlay
        inputs.rust-overlay.overlay
        inputs.naersk.overlay
      ];
    }
    inputs.sops-nix.nixosModules.sops
  ];
}
