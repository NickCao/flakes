{ stdenv, fetchFromGitHub, cmake, extra-cmake-modules, qt5, plasma5Packages }:
qt5.mkDerivation {
  pname = "material-decoration";
  version = "2021-03-07";
  src = fetchFromGitHub {
    owner = "Zren";
    repo = "material-decoration";
    rev = "8873774202153d793936e75437b7924a9cf43198"; # heads/master
    sha256 = "1ygj5saw7yqhw1y2r4nz53spc14i4b45j65q7xrhsz4pa6ciqa4r";
  };
  buildInputs = with plasma5Packages; [ qt5.qtbase qt5.qtx11extras kdecoration kcoreaddons kguiaddons kconfig kconfigwidgets kwindowsystem kiconthemes ];
  nativeBuildInputs = [ cmake extra-cmake-modules ];
}
