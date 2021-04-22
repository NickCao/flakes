{ source, stdenv, fetchFromGitHub, cmake, extra-cmake-modules, qt5, plasma5Packages }:
qt5.mkDerivation {
  inherit (source) pname version src;
  buildInputs = with plasma5Packages; [ qt5.qtbase qt5.qtx11extras kwayland kdecoration kcoreaddons kguiaddons kconfig kconfigwidgets kwindowsystem kiconthemes ];
  nativeBuildInputs = [ cmake extra-cmake-modules ];
}
