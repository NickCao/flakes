{ stdenv, fetchFromGitHub, cmake, extra-cmake-modules, qt5, plasma5Packages }:
qt5.mkDerivation {
  pname = "material-decoration";
  version = "2021-03-15";
  src = fetchFromGitHub {
    owner = "Zren";
    repo = "material-decoration";
    rev = "e652d62451dc67a9c6bc16c00ccbc38fed3373dd"; # heads/master
    sha256 = "182hqn4kbh0vmnbhj7nrqx2lypkddd6appp5y4kqinnw8dmpdyqx";
  };
  buildInputs = with plasma5Packages; [ qt5.qtbase qt5.qtx11extras kwayland kdecoration kcoreaddons kguiaddons kconfig kconfigwidgets kwindowsystem kiconthemes ];
  nativeBuildInputs = [ cmake extra-cmake-modules ];
}
