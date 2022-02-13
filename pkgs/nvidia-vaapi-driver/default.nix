{ source, stdenv, lib, meson, ninja, pkg-config, libGL, gst_all_1, nv-codec-headers-11, libva, addOpenGLRunpath }:
stdenv.mkDerivation {
  inherit (source) pname version src;
  nativeBuildInputs = [ meson ninja pkg-config addOpenGLRunpath ];
  buildInputs = with gst_all_1;[ libGL gstreamer gst-plugins-bad nv-codec-headers-11 libva ];
  postFixup = ''
    addOpenGLRunpath $out/lib/dri/nvidia_drv_video.so
  '';
}
