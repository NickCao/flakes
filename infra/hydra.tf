resource "hydra_project" "nixpkgs" {
  name         = "nixpkgs"
  display_name = "Nixpkgs"
  description  = "Nix Packages collection"
  homepage     = "https://nixos.org/nixpkgs"
  owner        = "nickcao@nichi.co"
}

resource "hydra_project" "nixos" {
  name         = "nixos"
  display_name = "NixOS"
  description  = "NixOS, the purely functional Linux distribution"
  homepage     = "https://nixos.org/nixos"
  owner        = "nickcao@nichi.co"
  declarative {
    file  = "hydra/nixos.json"
    type  = "git"
    value = "https://github.com/NickCao/flakes.git"
  }

}

resource "hydra_project" "misc" {
  name         = "misc"
  display_name = "Misc"
  description  = "Miscellaneous projects"
  owner        = "nickcao@nichi.co"
  declarative {
    file  = "hydra/misc.json"
    type  = "git"
    value = "https://github.com/NickCao/flakes.git"
  }
}

resource "hydra_jobset" "riscv" {
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
