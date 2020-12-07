{ mkDerivation, fetchFromGitHub, lib, cmake }:

mkDerivation rec {
  pname = "qv2ray-plugin-ssr";
  version = "3.0.0-git";

  src = fetchFromGitHub {
    owner = "Qv2ray";
    repo = "QvPlugin-SSR";
    rev = "663617c";
    fetchSubmodules = true;
    sha256 = "sha256-Oomm+kwIOsHU6uc0JADeAg+bwzZ8OnLpL7K/p3LpWME=";
  };

  nativeBuildInputs = [ cmake ];

  meta = with lib; {
    description = "ShadowsocksR plugin for Qv2ray";
    homepage = "https://qv2ray.net";
    license = licenses.gpl3Only;
  };
}
