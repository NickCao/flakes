{ lib
, stdenv
, fetchFromGitHub
, makeWrapper
, python3
, git
}:

stdenv.mkDerivation rec {
  pname = "gh-mirror";
  version = "2022-04-14";

  src = fetchFromGitHub {
    owner = "cdown";
    repo = pname;
    rev = "250cab172f1ebbc3af19444d328a74db588639ef";
    hash = "sha256-XVt7JHrLsVv1Fy2ZdWrA0mH/eQNKCJrcuJp1xLVnLIM=";
  };

  buildInputs = [ python3 makeWrapper ];

  installPhase = ''
    runHook preInstall
    install -Dm755 gh-mirror "$out/bin/gh-mirror"
    wrapProgram "$out/bin/gh-mirror" --prefix PATH : ${lib.makeBinPath [ git ]}
    runHook postInstall
  '';

  meta = with lib; {
    description = "Mirror all GitHub repositories for a user, maintaining metadata";
    homepage = "https://github.com/cdown/gh-mirror";
    license = licenses.isc;
    maintainers = with maintainers; [ nickcao ];
  };
}
