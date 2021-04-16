{ system, self, nixpkgs, impermanence, fenix, neovim, home-manager, sops-nix }:
nixpkgs.lib.nixosSystem {
  inherit system;
  modules = [
    ./configuration.nix
    ./hardware.nix
    impermanence.nixosModules.impermanence
    home-manager.nixosModules.home-manager
    sops-nix.nixosModules.sops
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
        neovim.overlay
        fenix.overlay
      ];
      nix.registry.p.flake = nixpkgs;
      home-manager.users.nickcao.imports = [ "${impermanence}/home-manager.nix" ];
    }
  ];
}
