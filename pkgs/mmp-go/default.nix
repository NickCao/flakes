{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "mmp-go";
  version = "1ff4cdd";

  src = fetchFromGitHub {
    owner = "Qv2ray";
    repo = "mmp-go";
    rev = "${version}";
    sha256 = "sha256-G17OwaoN/F+Dhc7y7nDoaDyKzF/A4r5DcUHTo/ZKPh8=";
  };

  vendorSha256 = "sha256-uVMa8DRMIKGpPrCLuROUBIQGHwxnACGfOyE5MWnKNos=";

  meta = with lib; {
    description =
      "Mega Multiplexer, port mutiplexer for shadowsocks, supports AEAD methods only";
    homepage = "https://github.com/Qv2ray/mmp-go";
    license = licenses.agpl3;
  };
}
