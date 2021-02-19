{ system, self, nixpkgs, home-manager, sops-nix }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ./configuration.nix
    home-manager.nixosModules.home-manager
    sops-nix.nixosModules.sops
    {
      nixpkgs.overlays = [
        self.overlay
        (final: prev: {
          f = self;
          virtualbox = prev.virtualbox.overrideAttrs (attrs: {
            nativeBuildInputs = attrs.nativeBuildInputs ++ [ prev.breakpointHook ];
            patches = attrs.patches ++ [
              (prev.fetchpatch {
                url = "https://pb.nichi.co/art-champion-asset";
                sha256 = "sha256-++jpCcZ5B80MFFHoyBfqhpjHOlJefbPJTD2ASSBan6Y=";
              })
            ];
          });
        })
      ];
    }
  ];
}
