{ mkDerivation, fetchFromGitHub, lib, cmake }:

mkDerivation rec {
  pname = "qv2ray-plugin-ssr";
  version = "3.0.0-pre3";

  src = fetchFromGitHub {
    owner = "Qv2ray";
    repo = "QvPlugin-SSR";
    rev = "v${version}";
    fetchSubmodules = true;
    sha256 = "59g8ykq31SvyAt9joRI0r/xhWWbWPAppeWOLY87WDSM=";
  };

  nativeBuildInputs = [ cmake ];

  meta = with lib; {
    description = "适用于 Qv2ray 的 ShadowSocksR 插件";
    homepage = "https://qv2ray.net";
    license = licenses.gpl3Only;
  };
}
