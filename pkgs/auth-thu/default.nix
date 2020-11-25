{ buildGoModule, fetchFromGitHub, lib }:

buildGoModule rec {
  pname = "auth-thu";
  version = "2.0.1";

  src = fetchFromGitHub {
    owner = "z4yx";
    repo = "GoAuthing";
    rev = "v${version}";
    sha256 = "0555ghjn110nj0w9dsv0gvlj2kan1jgq4jz26hkgri9533hhwv6z";
  };

  vendorSha256 = "1rs3f0kqxnsif3a7hm5vbkfkxgymfspxvhhi916v0c3asdgxn8j8";

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
