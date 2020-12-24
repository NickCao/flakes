{ buildGoModule, fetchFromGitLab, lib }:

buildGoModule rec {
  pname = "rait";
  version = "2020-11-18";

  src = fetchFromGitLab {
    owner = "NickCao";
    repo = "RAIT";
    rev = "99a6b105ec0277a8c85af0f5971b04fefa16fd21"; # heads/master
    sha256 = "0gna0sbcpv19vravhrkfrl9i0rcng98gpsgqm6p2xyg1b50di27w";
  };

  vendorSha256 = "sha256-NfUDR7yU1S/ixEQgBQfC6gl6EJlrATvojPQD2AxIMsg=";

  subPackages = [ "cmd/rait" ];

  meta = with lib; {
    description = "Redundant Array of Inexpensive Tunnels";
    homepage = "https://gitlab.com/NickCao/RAIT";
    license = licenses.asl20;
  };
}
