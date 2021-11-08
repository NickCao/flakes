{ system, self, nixpkgs, inputs }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ./configuration.nix
    ./hardware.nix
    ./services.nix
    inputs.impermanence.nixosModules.impermanence
    inputs.sops-nix.nixosModules.sops
    {
      nixpkgs.overlays = [
        (final: prev: {
          inherit (inputs.nixbot.packages."${system}") nixbot-telegram;
          etcd = final.etcd_3_4;
          hercules-ci-agent = inputs.hercules.packages.${system}.hercules-ci-agent-nixUnstable;
        })
        inputs.rust-overlay.overlay
        inputs.fn.overlay
      ];
    }
  ];
}
