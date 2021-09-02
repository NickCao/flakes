{ system, self, nixpkgs, inputs }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ./configuration.nix
    ./gravity.nix
    ./hardware.nix
    self.nixosModules.gravity
    self.nixosModules.kernel
    inputs.impermanence.nixosModules.impermanence
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    {
      nixpkgs.overlays = [
        self.overlay
        inputs.rust-overlay.overlay
        (final: prev: {
          alacritty = final.symlinkJoin {
            name = "alacritty";
            paths = [ prev.alacritty ];
            buildInputs = [ final.makeWrapper ];
            postBuild = ''
              wrapProgram $out/bin/alacritty --unset WAYLAND_DISPLAY
            '';
          };
        })
      ];
      nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];
      nix.registry.p.flake = self;
    }
  ];
}
