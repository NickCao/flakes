{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "mmp-go";
  version = "2021-01-07";

  src = fetchFromGitHub {
    owner = "Qv2ray";
    repo = "mmp-go";
    rev = "00d3b64c272922ed7743fdc11381e1f2659760fd"; # heads/main
    sha256 = "1n08bmw0kyjwqi7lw8nqi32i58ligl9ki4a00mck6f1jybk0ycs3";
  };

  vendorSha256 = "sha256-LnKhfxZiaWQspfF/wMVA9ApnoxSBBzo7HFc5pGoG+CY=";

  meta = with lib; {
    description =
      "Mega Multiplexer, port mutiplexer for shadowsocks, supports AEAD methods only";
    homepage = "https://github.com/Qv2ray/mmp-go";
    license = licenses.agpl3;
  };
}
