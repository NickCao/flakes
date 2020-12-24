{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "auth-thu";
  version = "2020-12-17";

  src = fetchFromGitHub {
    owner = "z4yx";
    repo = "GoAuthing";
    rev = "f8acce6ce173458ff3a34a44ae7b84408599bdc8"; # tags/v*
    sha256 = "1z1anpp16d01ncp2bg1ahnyn0707xnavhbaqhddjhzw78zsh120q";
  };

  vendorSha256 = "sha256-SCLbX9NqMLBNSBHC3a921b8+3Vy7VHjUcFHbjidwQ+c=";

  subPackages = [ "cli" ];

  postInstall = ''
    mv $out/bin/cli $out/bin/auth-thu
  '';

  meta = with lib; {
    description =
      "Authentication utility for srun4000 (auth.tsinghua.edu.cn / net.tsinghua.edu.cn / Tsinghua-IPv4)";
    homepage = "https://github.com/z4yx/GoAuthing";
    license = licenses.gpl3Only;
  };
}
