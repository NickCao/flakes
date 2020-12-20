{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "auth-thu";
  version = "2.0.3";

  src = fetchFromGitHub {
    owner = "z4yx";
    repo = "GoAuthing";
    rev = "v${version}";
    sha256 = "sha256-GIgA9UeHfyhbg1gtuJXtBxxgvYUqvCUuswE0E+61Kvw=";
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
