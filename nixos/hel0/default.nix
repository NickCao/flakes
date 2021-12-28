{ system, self, nixpkgs, inputs }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ./configuration.nix
    ./hardware.nix
    ./services.nix
    self.nixosModules.cloud.services
    inputs.impermanence.nixosModules.impermanence
    inputs.sops-nix.nixosModules.sops
    {
      nixpkgs.overlays = [
        (final: prev: {
          inherit (inputs.nixbot.packages."${system}") nixbot-telegram;
          etcd = final.etcd_3_4;
        })
        inputs.rust-overlay.overlay
        inputs.fn.overlay
      ];
    }
  ];
}
