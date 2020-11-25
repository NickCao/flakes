{
  description = "a nix derivation collection by nickcao";
  outputs = { self, nixpkgs }:
  let
    callPackage = (import nixpkgs { system = "x86_64-linux"; }).callPackage;
  in 
  {
    packages.x86_64-linux.auth-thu = callPackage ./pkgs/auth-thu {};
  };
}
