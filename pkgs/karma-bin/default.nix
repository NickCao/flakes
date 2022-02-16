{ source, stdenv }:
stdenv.mkDerivation {
  inherit (source) pname version src;
  sourceRoot = ".";
  installPhase = ''
    install -Dm755 karma-linux-amd64 $out/bin/karma
  '';
}
