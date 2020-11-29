{ stdenv, fetchFromGitHub, cmake, pkgconfig, gdk-pixbuf, glib, ibus, libnotify
, librime, brise }:

stdenv.mkDerivation rec {
  pname = "ibus-rime";
  version = "2020-09-29";

  src = fetchFromGitHub {
    owner = "rime";
    repo = "ibus-rime";
    rev = "933ea96c172715511efa6c4601af73fa2b9ab236";
    sha256 = "1d4kins5pjgvagsphncpcsldgw356c8axyxi66g4kgvfsshsrggy";
  };

  buildInputs = [ gdk-pixbuf glib ibus libnotify librime brise ];
  nativeBuildInputs = [ cmake pkgconfig ];

  makeFlags = [ "PREFIX=$(out)" ];
  dontUseCmakeConfigure = true;

  prePatch = ''
    substituteInPlace Makefile \
       --replace 'cmake' 'cmake -DRIME_DATA_DIR=${brise}/share/rime-data'
     substituteInPlace rime_config.h \
       --replace '/usr' $out
     substituteInPlace rime_config.h \
       --replace 'IBUS_RIME_SHARED_DATA_DIR IBUS_RIME_INSTALL_PREFIX' \
                 'IBUS_RIME_SHARED_DATA_DIR "${brise}"'
     substituteInPlace rime.xml \
       --replace '/usr' $out
  '';

  meta.isIbusEngine = true;
}
