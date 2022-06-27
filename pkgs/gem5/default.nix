{ stdenv
, lib
, fetchgit
, scons
, gnum4
, protobuf
, zlib
, gperftools
, libpng
, hdf5-cpp
, isa ? "RISCV"
, variant ? "fast"
}:

let
  target = "build/${isa}/gem5.${variant}";
in
stdenv.mkDerivation rec {
  pname = "gem5";
  version = "22.0.0.1";

  src = fetchgit {
    url = "https://gem5.googlesource.com/public/gem5";
    rev = "v${version}";
    sha256 = "sha256-PpAKFZuJwmHpGY0LQ5e1mCnmxATgWqepmJeYTI6OToI=";
  };

  postPatch = ''
    patchShebangs ./util
  '';

  installPhase = ''
    install -Dm755 "${target}" "$out/bin/gem5"
  '';

  nativeBuildInputs = [
    scons
    gnum4
    protobuf
  ];

  buildInputs = [
    zlib
    gperftools # tcmalloc
    libpng
    hdf5-cpp
  ];

  buildFlags = [
    "${target}"
  ];

  enableParallelBuilding = true;

  meta = with lib; {
    description = "The gem5 simulator system";
    homepage = "https://www.gem5.org/";
    license = licenses.bsd3;
    maintainers = with maintainers; [ nickcao ];
  };
}
