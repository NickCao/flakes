{ lib
, buildGoModule
, fetchFromGitLab
}:

buildGoModule rec {
  pname = "rait";
  version = "4.4.0";

  src = fetchFromGitLab {
    owner = "NickCao";
    repo = "RAIT";
    rev = "v${version}";
    hash = "sha256-6Y0s5/HUmWrZA6QmV5wYjB1M0Ab/jHM3TSruRpMRwtA=";
  };

  vendorHash = "sha256-T/ufC4mEXRBKgsmIk8jSCQva5Td0rnFHx3UIVV+t08k=";

  subPackages = [ "cmd/rait" ];

  meta = with lib; {
    description = "Redundant Array of Inexpensive Tunnels";
    homepage = "https://gitlab.com/NickCao/RAIT";
    license = licenses.asl20;
  };
}
