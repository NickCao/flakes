{ source, stdenv, lib, cmake, ninja }:
stdenv.mkDerivation {
  inherit (source) pname version src;
  nativeBuildInputs = [ cmake ninja ];
}
