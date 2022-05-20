{ stdenv, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "stage0-posix";
  version = "1.5.0";

  src = fetchFromGitHub {
    owner = "oriansj";
    repo = pname;
    rev = "Release_${version}";
    fetchSubmodules = true;
    sha256 = "sha256-jXQxfjtlqUXEiu1YguhA7egL7tDUFCzTu/dkq31Ie08=";
  };

  buildPhase = ''
    ./bootstrap-seeds/POSIX/AMD64/kaem-optional-seed
  '';

  installPhase = ''
    mkdir $out
    cp -r AMD64/bin $out/bin
  '';
}
