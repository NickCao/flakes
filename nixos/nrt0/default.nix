{ system, self, nixpkgs, inputs }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ./configuration.nix
    ./services.nix
    self.nixosModules.bgp
    self.nixosModules.ssh
    self.nixosModules.vultr
    self.nixosModules.gravity
    self.nixosModules.divi
    self.nixosModules.dns
    self.nixosModules.telegraf
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
