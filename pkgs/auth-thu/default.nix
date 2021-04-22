{ source, buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  inherit (source) pname version src;

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
