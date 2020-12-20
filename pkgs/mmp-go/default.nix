{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "mmp-go";
  version = "71c3586";

  src = fetchFromGitHub {
    owner = "Qv2ray";
    repo = "mmp-go";
    rev = "${version}";
    sha256 = "sha256-mkxO3MFTUpFlR1+0RTE6RdXBrFxUTcQ8ZP+Qn1Tln+s=";
  };

  vendorSha256 = "sha256-uVMa8DRMIKGpPrCLuROUBIQGHwxnACGfOyE5MWnKNos=";

  meta = with lib; {
    description =
      "Mega Multiplexer, port mutiplexer for shadowsocks, supports AEAD methods only";
    homepage = "https://github.com/Qv2ray/mmp-go";
    license = licenses.agpl3;
  };
}
