{ buildGoModule, fetchFromGitLab, lib }:

buildGoModule rec {
  pname = "rait";
  version = "4.1.3";

  src = fetchFromGitLab {
    owner = "NickCao";
    repo = "RAIT";
    rev = "99a6b105ec0277a8c85af0f5971b04fefa16fd21";
    sha256 = "sha256-/IjYQFnh+S6uqfjp+1B6lmUQE81uZrhV3insy5YGyj4=";
  };

  vendorSha256 = "sha256-NfUDR7yU1S/ixEQgBQfC6gl6EJlrATvojPQD2AxIMsg=";

  subPackages = [ "cmd/rait" ];

  meta = with lib; {
    description = "Redundant Array of Inexpensive Tunnels";
    homepage = "https://gitlab.com/NickCao/RAIT";
    license = licenses.asl20;
  };
}
