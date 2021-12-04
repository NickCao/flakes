{ source, stdenv, autoreconfHook, pkg-config, openssl, efivar, keyutils }:
stdenv.mkDerivation {
  inherit (source) pname version src;
  nativeBuildInputs = [ autoreconfHook pkg-config ];
  buildInputs = [ openssl efivar keyutils ];
}
