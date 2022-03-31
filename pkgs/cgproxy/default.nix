{ stdenv
, lib
, fetchFromGitHub
, cmake
, nlohmann_json
, libbpf
, zlib
, libelf
, makeWrapper
, iptables
, procps
, which
, coreutils
, gnused
, util-linux
, iproute2
}:

stdenv.mkDerivation rec {
  pname = "cgproxy";
  version = "0.19";

  src = fetchFromGitHub {
    owner = "springzfx";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-zlD2vC58iaioApSREb4d+hIeyT0t2gedPSj7eJq+mhE=";
  };

  nativeBuildInputs = [ cmake makeWrapper ];
  buildInputs = [ nlohmann_json libbpf zlib libelf ];

  postInstall = ''
    wrapProgram $out/bin/cgproxyd --prefix PATH : ${lib.makeBinPath [
      which procps coreutils
    ]}
    wrapProgram $out/share/cgproxy/scripts/cgroup-tproxy.sh --prefix PATH : ${lib.makeBinPath [
      gnused coreutils util-linux iptables iproute2 procps
    ]}
  '';
}
