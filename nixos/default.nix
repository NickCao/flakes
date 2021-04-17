{ system, self, nixpkgs, inputs }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ./configuration.nix
    ./hardware.nix
    inputs.impermanence.nixosModules.impermanence
    inputs.home-manager.nixosModules.home-manager
    inputs.sops-nix.nixosModules.sops
    {
      nixpkgs.overlays = [
        (
          final: prev: {
            gnome3 = prev.gnome3 // {
              gnome-shell = prev.gnome3.gnome-shell.overrideAttrs (attrs: {
                pname = "gnome-shell-fixed";
                buildInputs = attrs.buildInputs ++ [ prev.mesa ];
              });
              gnome-session = prev.gnome3.gnome-session.override { gnome3 = final.gnome3; };
              gnome-tweaks = prev.gnome3.gnome-tweaks.override { gnome3 = final.gnome3; };
            };
          }
        )
        self.overlay
        inputs.neovim.overlay
        inputs.fenix.overlay
      ];
      nix.registry.p.flake = nixpkgs;
      home-manager.users.nickcao.imports = [ "${inputs.impermanence}/home-manager.nix" ];
    }
  ];
}
