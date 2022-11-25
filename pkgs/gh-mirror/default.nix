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
    rev = "46a1231c96c54009a75016e5e6f85b15cb7eacdd";
    hash = "sha256-5zeO0vTzD44lKuWYHz5vbzZgZXzLxGFx1alObbMV1ZY=";
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
