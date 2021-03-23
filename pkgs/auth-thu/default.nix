{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "auth-thu";
  version = "2021-01-19";

  src = fetchFromGitHub {
    owner = "z4yx";
    repo = "GoAuthing";
    rev = "0b9cecc866fff41db1ef09248ed58e5ce8a575ff"; # heads/master
    sha256 = "058kqphb83rmkh4c5i5axvarid53zsr2q3kcrf5alsb7ryidsyc9";
  };

  vendorSha256 = "sha256-SCLbX9NqMLBNSBHC3a921b8+3Vy7VHjUcFHbjidwQ+c=";

  subPackages = [ "cli" ];

  prePatch = ''
    substituteInPlace cli/main.go --replace ".auth-thu" ".config/auth-thu"
  '';

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
