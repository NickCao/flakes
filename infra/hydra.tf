resource "hydra_project" "nixpkgs" {
  name         = "nixpkgs"
  display_name = "Nixpkgs"
  description  = "Nix Packages collection"
  homepage     = "https://nixos.org/nixpkgs"
  owner        = "terraform"
}

resource "hydra_project" "nixos" {
  name         = "nixos"
  display_name = "NixOS"
  description  = "NixOS, the purely functional Linux distribution"
  homepage     = "https://nixos.org/nixos"
  owner        = "terraform"
}

resource "hydra_project" "misc" {
  name         = "misc"
  display_name = "Misc"
  description  = "Miscellaneous projects"
  owner        = "terraform"
}

resource "hydra_jobset" "nixos_riscv" {
  project           = hydra_project.nixos.name
  state             = "enabled"
  name              = "riscv"
  description       = "cross-compiled riscv nixos"
  type              = "flake"
  flake_uri         = "github:NickCao/nixos-riscv"
  check_interval    = 120
  scheduling_shares = 50
  keep_evaluations  = 3
}

resource "hydra_jobset" "misc_flakes" {
  project           = hydra_project.misc.name
  state             = "enabled"
  name              = "flakes"
  type              = "flake"
  flake_uri         = "github:NickCao/flakes"
  check_interval    = 120
  scheduling_shares = 100
  keep_evaluations  = 3
}

resource "hydra_jobset" "misc_netboot" {
  project           = hydra_project.misc.name
  state             = "enabled"
  name              = "netboot"
  type              = "flake"
  flake_uri         = "github:NickCao/netboot"
  check_interval    = 120
  scheduling_shares = 100
  keep_evaluations  = 3
}

resource "hydra_jobset" "nixpkgs_riscv" {
  project     = hydra_project.nixpkgs.name
  state       = "enabled"
  name        = "riscv"
  description = "cross-compiled riscv packages"
  type        = "legacy"

  nix_expression {
    file  = "pkgs/top-level/release.nix"
    input = "nixpkgs"
  }

  check_interval    = 120
  scheduling_shares = 100
  keep_evaluations  = 2

  input {
    name              = "nixpkgs"
    notify_committers = false
    type              = "git"
    value             = "https://github.com/NickCao/nixpkgs.git riscv"
  }

  input {
    name              = "nixpkgsArgs"
    notify_committers = false
    type              = "nix"
    value             = "{ config = { allowUnfree = false; inHydra = true; }; crossSystem.config = \"riscv64-unknown-linux-gnu\"; }"
  }

  input {
    name              = "limitedSupportedSystems"
    notify_committers = false
    type              = "nix"
    value             = "[]"
  }

  input {
    name              = "supportedSystems"
    notify_committers = false
    type              = "nix"
    value             = "[ \"x86_64-linux\" ]"
  }
}
