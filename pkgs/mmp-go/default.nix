{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "mmp-go";
  version = "c8644b4";

  src = fetchFromGitHub {
    owner = "Qv2ray";
    repo = "mmp-go";
    rev = "${version}";
    sha256 = "sha256-xJEmE1F5WP5tCeB6RZ4V4AxUgpPhxY9LAbWkH2MAqoE=";
  };

  vendorSha256 = "sha256-uVMa8DRMIKGpPrCLuROUBIQGHwxnACGfOyE5MWnKNos=";

  meta = with lib; {
    description =
      "Mega Multiplexer, port mutiplexer for shadowsocks, supports AEAD methods only";
    homepage = "https://github.com/Qv2ray/mmp-go";
    license = licenses.agpl3;
  };
}
