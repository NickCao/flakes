{ stdenv
, lib
, fetchFromGitLab
, meson
, ninja
, cmake
, pkg-config
, rustPlatform
, glib
, gtk4
, libadwaita
, gtksourceview5
, gst_all_1
, libsecret
, desktop-file-utils
, openssl
, pipewire
, wrapGAppsHook
}:

stdenv.mkDerivation rec {
  pname = "fractal-next";
  version = "unstable-2022-03-10";

  src = fetchFromGitLab {
    domain = "gitlab.gnome.org";
    owner = "GNOME";
    repo = "fractal";
    rev = "3bd9afe788f1d3701a76671a56420f763d940389";
    sha256 = "sha256-OViMVrxcBku2i0Yoj3ajLZz+n0GFmgyNHVmFnbV0SAQ=";
  };

  cargoDeps = rustPlatform.fetchCargoTarball {
    inherit src;
    sha256 = "sha256-mE4anETcl/60NoVP5dFjANjFYd5SRup35gLULogBg+s=";
  };

  nativeBuildInputs = [
    meson
    ninja
    cmake
    pkg-config
    rustPlatform.rust.rustc
    rustPlatform.rust.cargo
    rustPlatform.cargoSetupHook
    rustPlatform.bindgenHook
    desktop-file-utils
    wrapGAppsHook
  ];

  buildInputs = [
    glib
    gtk4
    libadwaita
    gtksourceview5
    gst_all_1.gstreamer
    gst_all_1.gst-plugins-base
    gst_all_1.gst-plugins-bad
    libsecret
    openssl
    pipewire
  ];

  meta = with lib; {
    description = "a Matrix messaging app for GNOME written in Rust";
    homepage = "https://gitlab.gnome.org/GNOME/fractal";
    license = licenses.gpl3Plus;
    maintainers = with maintainers;[ nickcao ];
  };
}
