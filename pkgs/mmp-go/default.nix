{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "mmp-go";
  version = "2020-12-22";

  src = fetchFromGitHub {
    owner = "Qv2ray";
    repo = "mmp-go";
    rev = "0157e09b009ccb077555ece10fa664d364629523"; # heads/main
    sha256 = "0rxlzb5bm1l2nz6i936ashzgzlvjvax2fg1g52538g7mxqnbd0vp";
  };

  vendorSha256 = "sha256-uVMa8DRMIKGpPrCLuROUBIQGHwxnACGfOyE5MWnKNos=";

  meta = with lib; {
    description =
      "Mega Multiplexer, port mutiplexer for shadowsocks, supports AEAD methods only";
    homepage = "https://github.com/Qv2ray/mmp-go";
    license = licenses.agpl3;
  };
}
