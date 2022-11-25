{ lib
, stdenv
, fetchFromGitHub
, makeWrapper
, python3
, git
}:

stdenv.mkDerivation rec {
  pname = "gh-mirror";
  version = "2022-11-25";

  src = fetchFromGitHub {
    owner = "NickCao";
    repo = pname;
    rev = "3f6499e5304841c9a3993b1f1018725e9c3dfc97";
    hash = "sha256-8ruDXE44K3Nfh478o5hCWbvlY9fRFD8lNgcKC8QznAU=";
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
